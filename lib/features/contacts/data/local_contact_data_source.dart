import 'package:csv/csv.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:sqflite/sqflite.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/network/remote_contact_data_source.dart';
import '../domain/contact.dart';
import 'contact_query.dart';

class LocalContactDataSource {
  const LocalContactDataSource(this._db);

  final Database _db;

  Future<void> importSeedIfNeeded() async {
    final count =
        Sqflite.firstIntValue(
          await _db.rawQuery('SELECT COUNT(*) FROM contacts'),
        ) ??
        0;
    if (count == 0) {
      await importSeedCsv(replace: true);
    }
  }

  Future<int> importSeedCsv({required bool replace}) async {
    final csvText = await _loadSeedCsv();
    final rows = const CsvToListConverter(
      shouldParseNumbers: false,
    ).convert(csvText);
    if (rows.length < 2) return 0;

    final headers = rows.first
        .map(
          (cell) => cell.toString().toLowerCase().replaceAll(
            RegExp(r'[^a-z0-9]'),
            '',
          ),
        )
        .toList(growable: false);

    final contacts = <Contact>[];
    for (var i = 1; i < rows.length; i++) {
      final row = rows[i];
      final mapped = <String, String>{};
      for (var j = 0; j < headers.length; j++) {
        mapped[headers[j]] = j < row.length ? row[j].toString() : '';
      }
      final contact = Contact.fromCsv(mapped, i);
      if (contact.organisationName.isNotEmpty ||
          contact.hotlineCode.isNotEmpty) {
        contacts.add(contact);
      }
    }

    await _db.transaction((txn) async {
      if (replace) {
        await txn.delete('contacts');
      }
      final batch = txn.batch();
      for (final contact in contacts) {
        batch.insert(
          'contacts',
          contact.toDb(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      batch.insert('metadata', {
        'key': 'data_version',
        'value': AppConstants.bundledDataVersion,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
      batch.insert('metadata', {
        'key': 'seed_imported_at',
        'value': DateTime.now().toIso8601String(),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
      await batch.commit(noResult: true);
    });

    return contacts.length;
  }

  Future<String> _loadSeedCsv() async {
    try {
      return await rootBundle.loadString(AppConstants.seedCsvPath);
    } on FlutterError {
      return rootBundle.loadString(AppConstants.packagedSeedCsvPath);
    }
  }

  Future<void> replaceContacts(
    List<Contact> contacts,
    String dataVersion,
  ) async {
    await _db.transaction((txn) async {
      await txn.delete('contacts');
      await txn.delete(
        'metadata',
        where: 'key LIKE ?',
        whereArgs: ['sync_bucket_%'],
      );
      final batch = txn.batch();
      for (final contact in contacts) {
        batch.insert(
          'contacts',
          contact.toDb(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      batch.insert('metadata', {
        'key': 'data_version',
        'value': dataVersion,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
      batch.insert('metadata', {
        'key': 'sync_format',
        'value': 'legacy-v1',
      }, conflictAlgorithm: ConflictAlgorithm.replace);
      batch.insert('metadata', {
        'key': 'last_sync_at',
        'value': DateTime.now().toIso8601String(),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
      await batch.commit(noResult: true);
    });
  }

  Future<Map<int, String>> syncBucketHashes() async {
    final rows = await _db.query(
      'metadata',
      where: 'key LIKE ?',
      whereArgs: ['sync_bucket_%'],
    );
    final hashes = <int, String>{};
    for (final row in rows) {
      final bucket = int.tryParse(
        (row['key'] as String).replaceFirst('sync_bucket_', ''),
      );
      final hash = (row['value'] as String?) ?? '';
      if (bucket != null && hash.isNotEmpty) hashes[bucket] = hash;
    }
    return hashes;
  }

  Future<void> applyChunkedUpdate(ChunkedRemoteUpdate update) async {
    final installedFormat = await metadata('sync_format');
    final firstChunkedSync = installedFormat != 'chunked-v1';
    await _db.transaction((txn) async {
      if (firstChunkedSync) {
        await txn.delete('contacts');
        await txn.delete(
          'metadata',
          where: 'key LIKE ?',
          whereArgs: ['sync_bucket_%'],
        );
      } else {
        for (final chunk in update.chunks) {
          await txn.delete(
            'contacts',
            where: 'sync_bucket = ?',
            whereArgs: [chunk.bucket],
          );
        }
      }
      final batch = txn.batch();
      for (final chunk in update.chunks) {
        for (final contact in chunk.contacts) {
          final values = contact.toDb()..['sync_bucket'] = chunk.bucket;
          batch.insert(
            'contacts',
            values,
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
        batch.insert('metadata', {
          'key': 'sync_bucket_${chunk.bucket}',
          'value': chunk.sha256,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
      batch.insert('metadata', {
        'key': 'data_version',
        'value': update.dataVersion,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
      batch.insert('metadata', {
        'key': 'sync_format',
        'value': 'chunked-v1',
      }, conflictAlgorithm: ConflictAlgorithm.replace);
      batch.insert('metadata', {
        'key': 'last_sync_at',
        'value': DateTime.now().toIso8601String(),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
      await batch.commit(noResult: true);
    });
  }

  Future<List<Contact>> search(ContactQuery query) async {
    final clause = _buildSearchWhere(query);

    final maps = await _db.query(
      'contacts',
      where: clause.where,
      whereArgs: clause.args,
      orderBy: 'is_emergency DESC, organisation_name COLLATE NOCASE ASC',
      limit: query.limit,
      offset: query.offset,
    );
    return maps.map(Contact.fromDb).toList(growable: false);
  }

  Future<int> count(ContactQuery query) async {
    final clause = _buildSearchWhere(query);
    final rows = await _db.rawQuery(
      'SELECT COUNT(*) FROM contacts${clause.sqlSuffix}',
      clause.args,
    );
    return Sqflite.firstIntValue(rows) ?? 0;
  }

  Future<Contact?> byId(String id) async {
    final maps = await _db.query(
      'contacts',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return Contact.fromDb(maps.first);
  }

  Future<List<Contact>> emergencyContacts({int limit = 30}) {
    return search(ContactQuery(emergencyOnly: true, limit: limit));
  }

  Future<List<String>> distinctValues(
    String column, {
    Map<String, String> filters = const {},
  }) async {
    final where = <String>['$column != ""'];
    final args = <Object?>[];
    filters.forEach((key, value) {
      if (value.trim().isNotEmpty) {
        where.add('$key = ?');
        args.add(value);
      }
    });
    final rows = await _db.query(
      'contacts',
      columns: ['DISTINCT $column'],
      where: where.join(' AND '),
      whereArgs: args,
      orderBy: '$column COLLATE NOCASE ASC',
    );
    return rows
        .map((row) => (row[column] as String?) ?? '')
        .where((value) => value.isNotEmpty)
        .toList(growable: false);
  }

  Future<String> metadata(String key) async {
    final rows = await _db.query(
      'metadata',
      where: 'key = ?',
      whereArgs: [key],
      limit: 1,
    );
    if (rows.isEmpty) return '';
    return (rows.first['value'] as String?) ?? '';
  }

  _WhereClause _buildSearchWhere(ContactQuery query) {
    final where = <String>[];
    final args = <Object?>[];
    final term = query.searchTerm.trim();
    if (term.isNotEmpty) {
      final like = '%$term%';
      where.add('''
        (
          organisation_name LIKE ? OR name_nepali LIKE ? OR category LIKE ? OR
          subcategory LIKE ? OR province LIKE ? OR district LIKE ? OR palika LIKE ? OR
          ward LIKE ? OR address LIKE ? OR primary_phone LIKE ? OR secondary_phone LIKE ? OR
          hotline_code LIKE ? OR department LIKE ? OR description LIKE ? OR notes LIKE ?
        )
      ''');
      args.addAll(List<Object?>.filled(15, like));
    }
    void addFilter(String column, String? value) {
      final filter = value?.trim();
      if (filter != null && filter.isNotEmpty) {
        where.add('$column = ?');
        args.add(filter);
      }
    }

    addFilter('province', query.province);
    addFilter('district', query.district);
    addFilter('palika', query.palika);
    addFilter('category', query.category);
    addFilter('verification_status', query.verificationStatus);
    if (query.emergencyOnly) where.add('is_emergency = 1');
    if (query.open247Only) where.add('is_24_7 = 1');
    return _WhereClause(where, args);
  }
}

class _WhereClause {
  const _WhereClause(this.parts, this.args);

  final List<String> parts;
  final List<Object?> args;

  String? get where => parts.isEmpty ? null : parts.join(' AND ');

  String get sqlSuffix => parts.isEmpty ? '' : ' WHERE ${parts.join(' AND ')}';
}
