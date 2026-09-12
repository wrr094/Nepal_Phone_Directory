import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;

import '../../features/contacts/domain/contact.dart';

abstract class RemoteContactDataSource {
  Future<List<Contact>> fetchContacts();
  Future<String> fetchDataVersion();
  Future<RemoteContactUpdate?> fetchUpdate({
    required String currentVersion,
    required Map<int, String> installedBucketHashes,
  });
}

sealed class RemoteContactUpdate {
  const RemoteContactUpdate(this.dataVersion);
  final String dataVersion;
}

class FullRemoteUpdate extends RemoteContactUpdate {
  const FullRemoteUpdate(super.dataVersion, this.contacts);
  final List<Contact> contacts;
}

class ChunkedRemoteUpdate extends RemoteContactUpdate {
  const ChunkedRemoteUpdate(super.dataVersion, this.chunks);
  final List<RemoteContactChunk> chunks;
}

class RemoteContactChunk {
  const RemoteContactChunk({
    required this.bucket,
    required this.sha256,
    required this.contacts,
  });
  final int bucket;
  final String sha256;
  final List<Contact> contacts;
}

class StaticJsonRemoteContactDataSource implements RemoteContactDataSource {
  StaticJsonRemoteContactDataSource({
    required String manifestUrl,
    http.Client? client,
  }) : _manifestUrl = manifestUrl,
       _client = client ?? http.Client();

  static const environmentManifestUrl = String.fromEnvironment(
    'REMOTE_DATA_MANIFEST_URL',
  );
  final String _manifestUrl;
  final http.Client _client;
  bool get isConfigured => _manifestUrl.trim().isNotEmpty;

  @override
  Future<List<Contact>> fetchContacts() async {
    final update = await fetchUpdate(
      currentVersion: '',
      installedBucketHashes: const {},
    );
    return switch (update) {
      FullRemoteUpdate(:final contacts) => contacts,
      ChunkedRemoteUpdate(:final chunks) => [
        for (final chunk in chunks) ...chunk.contacts,
      ],
      null => const [],
    };
  }

  @override
  Future<String> fetchDataVersion() async =>
      isConfigured ? (await _fetchManifest()).dataVersion : '';

  @override
  Future<RemoteContactUpdate?> fetchUpdate({
    required String currentVersion,
    required Map<int, String> installedBucketHashes,
  }) async {
    if (!isConfigured) return null;
    final manifest = await _fetchManifest();
    if (manifest.dataVersion == currentVersion) return null;
    if (manifest is _LegacyManifest) {
      return FullRemoteUpdate(
        manifest.dataVersion,
        await _fetchContacts(manifest.contactsUri, manifest.contactsCount),
      );
    }
    final chunks = await _fetchChangedChunks(
      manifest as _ChunkedManifest,
      installedBucketHashes,
    );
    return ChunkedRemoteUpdate(manifest.dataVersion, chunks);
  }

  Future<_RemoteManifest> _fetchManifest() async {
    final uri = Uri.tryParse(_manifestUrl.trim());
    if (uri == null || !uri.hasScheme)
      throw const RemoteDataException('Remote manifest URL is invalid.');
    final response = await _client.get(uri);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw RemoteDataException(
        'Could not download manifest (${response.statusCode}).',
      );
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, Object?>)
      throw const RemoteDataException('Manifest JSON must be an object.');
    return decoded['formatVersion'] == 1
        ? _ChunkedManifest.fromJson(decoded, uri)
        : _LegacyManifest.fromJson(decoded, uri);
  }

  Future<List<Contact>> _fetchContacts(Uri uri, int? expectedCount) async {
    final response = await _client.get(uri);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw RemoteDataException(
        'Could not download contacts (${response.statusCode}).',
      );
    }
    final decoded = jsonDecode(response.body);
    final records =
        decoded is List
            ? decoded
            : decoded is Map<String, Object?> && decoded['contacts'] is List
            ? decoded['contacts'] as List
            : throw const RemoteDataException('Contacts JSON must be a list.');
    final contacts = _contactsFromRecords(records);
    if (contacts.isEmpty ||
        (expectedCount != null && contacts.length != expectedCount)) {
      throw const RemoteDataException('Contacts JSON failed validation.');
    }
    return contacts;
  }

  Future<List<RemoteContactChunk>> _fetchChangedChunks(
    _ChunkedManifest manifest,
    Map<int, String> installed,
  ) async {
    final changed =
        manifest.chunks
            .where((chunk) => installed[chunk.bucket] != chunk.sha256)
            .toList();
    final downloaded = await Future.wait(
      changed.map((chunk) async {
        final response = await _client.get(chunk.uri);
        if (response.statusCode < 200 || response.statusCode >= 300)
          throw RemoteDataException(
            'Could not download data chunk ${chunk.bucket}.',
          );
        final bytes = response.bodyBytes;
        if (bytes.length >= _maxChunkBytes ||
            sha256.convert(bytes).toString() != chunk.sha256) {
          throw RemoteDataException(
            'Data chunk ${chunk.bucket} failed integrity validation.',
          );
        }
        final raw = gzip.decode(bytes);
        if (sha256.convert(raw).toString() != chunk.dataSha256)
          throw RemoteDataException(
            'Data chunk ${chunk.bucket} content hash is invalid.',
          );
        final decoded = jsonDecode(utf8.decode(raw));
        if (decoded is! Map<String, dynamic> ||
            decoded['formatVersion'] != 1 ||
            decoded['bucket'] != chunk.bucket ||
            decoded['recordCount'] != chunk.recordCount ||
            decoded['records'] is! List) {
          throw RemoteDataException(
            'Data chunk ${chunk.bucket} has an invalid schema.',
          );
        }
        final records = decoded['records'] as List;
        if (records.length != chunk.recordCount)
          throw RemoteDataException(
            'Data chunk ${chunk.bucket} count is invalid.',
          );
        final contacts = _contactsFromRecords(
          records,
          expectedColumns: manifest.columns,
          bucket: chunk.bucket,
          chunkCount: manifest.chunkCount,
        );
        if (contacts.length != records.length)
          throw RemoteDataException(
            'Data chunk ${chunk.bucket} contains invalid contacts.',
          );
        return RemoteContactChunk(
          bucket: chunk.bucket,
          sha256: chunk.sha256,
          contacts: contacts,
        );
      }),
    );
    if (downloaded.isEmpty)
      throw const RemoteDataException('Chunked update has no changed chunks.');
    return downloaded;
  }

  List<Contact> _contactsFromRecords(
    List records, {
    List<String>? expectedColumns,
    int? bucket,
    int? chunkCount,
  }) {
    final contacts = <Contact>[];
    final ids = <String>{};
    for (var i = 0; i < records.length; i++) {
      final item = records[i];
      if (item is! Map)
        throw const RemoteDataException('Contact record must be an object.');
      final keys = item.keys.map((key) => key.toString()).toSet();
      if (expectedColumns != null &&
          (keys.length != expectedColumns.length ||
              !keys.containsAll(expectedColumns))) {
        throw const RemoteDataException('Contact record columns are invalid.');
      }
      final row = <String, String>{};
      for (final entry in item.entries) {
        row[_normalizedKey(entry.key.toString())] =
            entry.value?.toString().trim() ?? '';
      }
      final id = row['entryid'] ?? row['id'] ?? '';
      if (id.isEmpty ||
          !ids.add(id) ||
          (bucket != null && _bucketFor(id, chunkCount!) != bucket)) {
        throw const RemoteDataException('Contact record identity is invalid.');
      }
      final contact = Contact.fromCsv(row, i + 1);
      if (contact.organisationName.isEmpty && contact.hotlineCode.isEmpty)
        throw const RemoteDataException('Contact record is empty.');
      contacts.add(contact);
    }
    return contacts;
  }
}

class DisabledRemoteContactDataSource implements RemoteContactDataSource {
  const DisabledRemoteContactDataSource();
  @override
  Future<List<Contact>> fetchContacts() async => const [];
  @override
  Future<String> fetchDataVersion() async => '';
  @override
  Future<RemoteContactUpdate?> fetchUpdate({
    required String currentVersion,
    required Map<int, String> installedBucketHashes,
  }) async => null;
}

class RemoteDataException implements Exception {
  const RemoteDataException(this.message);
  final String message;
  @override
  String toString() => message;
}

sealed class _RemoteManifest {
  const _RemoteManifest(this.dataVersion);
  final String dataVersion;
}

class _LegacyManifest extends _RemoteManifest {
  const _LegacyManifest(
    super.dataVersion,
    this.contactsUri,
    this.contactsCount,
  );
  factory _LegacyManifest.fromJson(Map<String, Object?> json, Uri uri) {
    final version = json['data_version']?.toString().trim() ?? '';
    final path = json['contacts_url']?.toString().trim() ?? '';
    if (version.isEmpty || path.isEmpty)
      throw const RemoteDataException('Legacy manifest is incomplete.');
    return _LegacyManifest(
      version,
      uri.resolve(path),
      int.tryParse(json['contacts_count']?.toString() ?? ''),
    );
  }
  final Uri contactsUri;
  final int? contactsCount;
}

class _ChunkedManifest extends _RemoteManifest {
  const _ChunkedManifest(
    super.dataVersion,
    this.chunkCount,
    this.columns,
    this.chunks,
  );
  factory _ChunkedManifest.fromJson(Map<String, Object?> json, Uri uri) {
    final version = json['datasetVersion']?.toString() ?? '';
    final count = json['chunkCount'] as int?;
    final columns =
        (json['columns'] as List?)?.map((value) => value.toString()).toList();
    final rawChunks = json['chunks'] as List?;
    if (version.isEmpty ||
        count == null ||
        count < 1 ||
        columns == null ||
        !columns.contains('Entry_ID') ||
        rawChunks == null ||
        rawChunks.length != count)
      throw const RemoteDataException('Chunked manifest is invalid.');
    final chunks =
        rawChunks
            .map((raw) => _ChunkDescriptor.fromJson(raw as Map, uri))
            .toList()
          ..sort((a, b) => a.bucket.compareTo(b.bucket));
    if (chunks.asMap().entries.any((entry) => entry.key != entry.value.bucket))
      throw const RemoteDataException('Chunked manifest buckets are invalid.');
    return _ChunkedManifest(version, count, columns, chunks);
  }
  final int chunkCount;
  final List<String> columns;
  final List<_ChunkDescriptor> chunks;
}

class _ChunkDescriptor {
  const _ChunkDescriptor(
    this.bucket,
    this.uri,
    this.recordCount,
    this.sha256,
    this.dataSha256,
  );
  factory _ChunkDescriptor.fromJson(Map raw, Uri manifestUri) {
    final bucket = raw['bucket'] as int?;
    final path = raw['url']?.toString() ?? '';
    final count = raw['recordCount'] as int?;
    final hash = raw['sha256']?.toString() ?? '';
    final dataHash = raw['dataSha256']?.toString() ?? '';
    if (bucket == null ||
        path.isEmpty ||
        count == null ||
        count < 0 ||
        !_hash.hasMatch(hash) ||
        !_hash.hasMatch(dataHash))
      throw const RemoteDataException('Chunk descriptor is invalid.');
    return _ChunkDescriptor(
      bucket,
      manifestUri.resolve(path),
      count,
      hash,
      dataHash,
    );
  }
  final int bucket;
  final Uri uri;
  final int recordCount;
  final String sha256;
  final String dataSha256;
}

const _maxChunkBytes = 25 * 1024 * 1024;
final _hash = RegExp(r'^[a-f0-9]{64}$');
String _normalizedKey(String value) =>
    value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
int _bucketFor(String entryId, int chunkCount) {
  final bytes = sha256.convert(utf8.encode(entryId)).bytes;
  var value = 0;
  for (var i = 0; i < 8; i++) {
    value = (value << 8) | bytes[i];
  }
  return value % chunkCount;
}
