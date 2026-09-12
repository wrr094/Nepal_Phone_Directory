// ignore_for_file: prefer_initializing_formals

import '../../../core/network/remote_contact_data_source.dart';
import '../domain/contact.dart';
import 'contact_query.dart';
import 'local_contact_data_source.dart';

abstract class ContactRepository {
  Future<void> initialize();
  Future<List<Contact>> search(ContactQuery query);
  Future<int> count(ContactQuery query);
  Future<List<Contact>> emergencyContacts({int limit});
  Future<List<String>> distinctValues(
    String column, {
    Map<String, String> filters,
  });
  Future<String> metadata(String key);
  Future<int> reloadSeedData();
  Future<bool> sync();
}

class SqliteContactRepository implements ContactRepository {
  // Kept public for compatibility with the standalone app's Dart baseline.
  const SqliteContactRepository({
    required LocalContactDataSource local,
    required RemoteContactDataSource remote,
  }) : _local = local,
       _remote = remote;

  final LocalContactDataSource _local;
  final RemoteContactDataSource _remote;

  @override
  Future<void> initialize() => _local.importSeedIfNeeded();

  @override
  Future<List<Contact>> search(ContactQuery query) => _local.search(query);

  @override
  Future<int> count(ContactQuery query) => _local.count(query);

  @override
  Future<List<Contact>> emergencyContacts({int limit = 30}) {
    return _local.emergencyContacts(limit: limit);
  }

  @override
  Future<List<String>> distinctValues(
    String column, {
    Map<String, String> filters = const {},
  }) {
    return _local.distinctValues(column, filters: filters);
  }

  @override
  Future<String> metadata(String key) => _local.metadata(key);

  @override
  Future<int> reloadSeedData() => _local.importSeedCsv(replace: true);

  @override
  Future<bool> sync() async {
    final currentVersion = await metadata('data_version');
    final update = await _remote.fetchUpdate(
      currentVersion: currentVersion,
      installedBucketHashes: await _local.syncBucketHashes(),
    );
    if (update == null) return true;
    switch (update) {
      case FullRemoteUpdate(:final contacts):
        if (contacts.isEmpty) return false;
        await _local.replaceContacts(contacts, update.dataVersion);
      case ChunkedRemoteUpdate():
        await _local.applyChunkedUpdate(update);
    }
    return true;
  }
}
