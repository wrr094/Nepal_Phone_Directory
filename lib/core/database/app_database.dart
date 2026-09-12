import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../constants/app_constants.dart';

class AppDatabase {
  AppDatabase._();

  static final AppDatabase instance = AppDatabase._();
  Database? _database;

  Future<Database> get database async {
    final existing = _database;
    if (existing != null) return existing;

    final dbPath = await getDatabasesPath();
    final database = await openDatabase(
      p.join(dbPath, AppConstants.databaseName),
      version: 2,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE contacts (
            id TEXT PRIMARY KEY,
            category TEXT NOT NULL DEFAULT '',
            subcategory TEXT NOT NULL DEFAULT '',
            organisation_name TEXT NOT NULL DEFAULT '',
            name_nepali TEXT NOT NULL DEFAULT '',
            description TEXT NOT NULL DEFAULT '',
            province TEXT NOT NULL DEFAULT '',
            district TEXT NOT NULL DEFAULT '',
            palika TEXT NOT NULL DEFAULT '',
            ward TEXT NOT NULL DEFAULT '',
            address TEXT NOT NULL DEFAULT '',
            latitude TEXT NOT NULL DEFAULT '',
            longitude TEXT NOT NULL DEFAULT '',
            primary_phone TEXT NOT NULL DEFAULT '',
            secondary_phone TEXT NOT NULL DEFAULT '',
            hotline_code TEXT NOT NULL DEFAULT '',
            fax TEXT NOT NULL DEFAULT '',
            email TEXT NOT NULL DEFAULT '',
            website TEXT NOT NULL DEFAULT '',
            key_persons TEXT NOT NULL DEFAULT '',
            department TEXT NOT NULL DEFAULT '',
            working_hours TEXT NOT NULL DEFAULT '',
            is_24_7 INTEGER NOT NULL DEFAULT 0,
            is_emergency INTEGER NOT NULL DEFAULT 0,
            source_name TEXT NOT NULL DEFAULT '',
            source_type TEXT NOT NULL DEFAULT 'Unknown',
            source_url TEXT NOT NULL DEFAULT '',
            verification_status TEXT NOT NULL DEFAULT 'Unverified',
            confidence_level TEXT NOT NULL DEFAULT '',
            last_checked TEXT NOT NULL DEFAULT '',
            notes TEXT NOT NULL DEFAULT ''
            ,sync_bucket INTEGER NOT NULL DEFAULT -1
          )
        ''');
        await db.execute('''
          CREATE TABLE metadata (
            key TEXT PRIMARY KEY,
            value TEXT NOT NULL DEFAULT ''
          )
        ''');
        await db.execute('''
          CREATE TABLE corrections (
            id TEXT PRIMARY KEY,
            contact_id TEXT,
            correction_type TEXT NOT NULL,
            details TEXT NOT NULL DEFAULT '',
            created_at TEXT NOT NULL,
            status TEXT NOT NULL DEFAULT 'Pending Review'
          )
        ''');
        for (final column in [
          'organisation_name',
          'category',
          'province',
          'district',
          'palika',
          'ward',
          'primary_phone',
          'hotline_code',
          'verification_status',
          'is_emergency',
          'is_24_7',
          'sync_bucket',
        ]) {
          await db.execute(
            'CREATE INDEX idx_contacts_$column ON contacts($column)',
          );
        }
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute(
            'ALTER TABLE contacts ADD COLUMN sync_bucket INTEGER NOT NULL DEFAULT -1',
          );
          await db.execute(
            'CREATE INDEX idx_contacts_sync_bucket ON contacts(sync_bucket)',
          );
        }
      },
    );
    _database = database;
    return database;
  }
}
