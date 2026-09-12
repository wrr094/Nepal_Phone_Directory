import 'dart:convert';
import 'dart:io';

import 'package:csv/csv.dart';

Future<void> main(List<String> args) async {
  if (args.length < 2) {
    stderr.writeln(
      'Usage: dart run tool/csv_to_seed_json.dart input.csv output.json',
    );
    exitCode = 64;
    return;
  }

  final input = File(args[0]);
  if (!input.existsSync()) {
    stderr.writeln('Input file not found: ${args[0]}');
    exitCode = 66;
    return;
  }

  final csvText = await input.readAsString();
  final rows = const CsvToListConverter(
    shouldParseNumbers: false,
  ).convert(csvText);
  if (rows.isEmpty) {
    await File(args[1]).writeAsString('[]\n');
    return;
  }

  final headers = rows.first
      .map((cell) => cell.toString())
      .toList(growable: false);
  final records = <Map<String, String>>[];
  for (var i = 1; i < rows.length; i++) {
    final row = rows[i];
    final record = <String, String>{};
    for (var j = 0; j < headers.length; j++) {
      record[headers[j]] = j < row.length ? row[j].toString() : '';
    }
    records.add(record);
  }

  const encoder = JsonEncoder.withIndent('  ');
  await File(args[1]).writeAsString('${encoder.convert(records)}\n');
}
