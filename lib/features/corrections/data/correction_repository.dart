import 'package:sqflite/sqflite.dart';

import '../domain/correction.dart';

class CorrectionRepository {
  const CorrectionRepository(this._db);

  final Database _db;

  Future<void> save(Correction correction) async {
    await _db.insert(
      'corrections',
      correction.toDb(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> pendingCount() async {
    return Sqflite.firstIntValue(
          await _db.rawQuery(
            'SELECT COUNT(*) FROM corrections WHERE status = ?',
            ['Pending Review'],
          ),
        ) ??
        0;
  }
}
