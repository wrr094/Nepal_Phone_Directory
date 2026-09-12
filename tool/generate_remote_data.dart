import 'dart:convert';
import 'dart:io';

import 'package:csv/csv.dart';

Future<void> main(List<String> args) async {
  final inputPath =
      args.isNotEmpty
          ? args[0]
          : 'assets/data/nepal_public_phone_directory.csv';
  final outputDirectory = args.length > 1 ? args[1] : 'remote_data/data';
  final version = args.length > 2 ? args[2] : _defaultVersion();
  final docsDirectory = args.length > 3 ? args[3] : 'remote_data/docs';

  final input = File(inputPath);
  if (!input.existsSync()) {
    stderr.writeln('Input CSV not found: $inputPath');
    exitCode = 66;
    return;
  }

  final csvText = await input.readAsString();
  final rows = const CsvToListConverter(
    shouldParseNumbers: false,
  ).convert(csvText);
  if (rows.length < 2) {
    stderr.writeln('CSV must contain a header row and at least one contact.');
    exitCode = 65;
    return;
  }

  final headers = rows.first.map((cell) => cell.toString()).toList();
  final records = <Map<String, String>>[];
  for (var i = 1; i < rows.length; i++) {
    final row = rows[i];
    final record = <String, String>{};
    for (var j = 0; j < headers.length; j++) {
      record[headers[j]] = j < row.length ? row[j].toString() : '';
    }
    final hasContent = record.values.any((value) => value.trim().isNotEmpty);
    if (hasContent) records.add(record);
  }

  final directory = Directory(outputDirectory);
  if (!directory.existsSync()) {
    await directory.create(recursive: true);
  }

  final contactsFile = File('${directory.path}/contacts.json');
  // Keep the data payload compact so it stays within Cloudflare Pages' per-file
  // upload limit while retaining the existing single-file sync contract.
  await contactsFile.writeAsString('${jsonEncode(records)}\n');

  final manifest = <String, Object?>{
    'format': 'nepal-helpline-csv-json-v1',
    'data_version': version,
    'published_at': DateTime.now().toUtc().toIso8601String(),
    'contacts_url': 'contacts.json',
    'contacts_count': records.length,
  };
  final manifestFile = File('${directory.path}/manifest.json');
  await manifestFile.writeAsString('${jsonEncode(manifest)}\n');

  stdout.writeln('Generated ${contactsFile.path}');
  stdout.writeln('Generated ${manifestFile.path}');
  stdout.writeln('Data version: $version');
  stdout.writeln('Contacts: ${records.length}');

  final officialSourcesFile = await _writeOfficialSourcesIndex(
    records,
    docsDirectory,
  );
  stdout.writeln('Generated ${officialSourcesFile.path}');
  final sourceRegisterFile = await _writeContactSourceRegister(
    records,
    docsDirectory,
  );
  stdout.writeln('Generated ${sourceRegisterFile.path}');
}

String _defaultVersion() {
  final now = DateTime.now().toUtc();
  String two(int value) => value.toString().padLeft(2, '0');
  return [
    'contacts',
    now.year.toString(),
    two(now.month),
    two(now.day),
    two(now.hour),
    two(now.minute),
    two(now.second),
  ].join('-');
}

Future<File> _writeOfficialSourcesIndex(
  List<Map<String, String>> records,
  String docsDirectory,
) async {
  final sourcesByUrl = <String, _SourceSummary>{};
  for (final record in records) {
    final url = _field(record, 'Data_Source_URL').trim();
    if (url.isEmpty) continue;

    final summary = sourcesByUrl.putIfAbsent(
      url,
      () => _SourceSummary(
        url: url,
        host: _hostForUrl(url),
        sourceName: _field(record, 'Source_Name').trim(),
        sourceType: _field(record, 'Source_Type').trim(),
      ),
    );
    summary.count++;
    final category = _field(record, 'Category').trim();
    if (category.isNotEmpty) summary.categories.add(category);
  }

  final sources =
      sourcesByUrl.values.toList()..sort((a, b) {
        final hostCompare = a.host.compareTo(b.host);
        if (hostCompare != 0) return hostCompare;
        return a.url.compareTo(b.url);
      });

  final officialCount =
      sources.where((source) => _isOfficialSource(source)).length;
  final buffer =
      StringBuffer()
        ..writeln('# Nepal HelpLine Official Sources')
        ..writeln()
        ..writeln('Last generated: ${DateTime.now().toUtc().toIso8601String()}')
        ..writeln()
        ..writeln(
          'Nepal HelpLine is an independent directory app. It does not represent, endorse, or act on behalf of any government entity.',
        )
        ..writeln()
        ..writeln(
          'Every directory record in this release includes its original source URL. Each contact detail page in the app shows the source name, source type, verification status, last checked date, and source URL.',
        )
        ..writeln()
        ..writeln('Total contacts in current dataset: ${records.length}')
        ..writeln('Unique source URLs: ${sources.length}')
        ..writeln('Official or public-service source URLs: $officialCount')
        ..writeln(
          'Complete record-level source register: contact_sources.csv (one row per directory record).',
        )
        ..writeln()
        ..writeln('## Primary Official Sources')
        ..writeln()
        ..writeln('- Nepal Police: https://www.nepalpolice.gov.np/')
        ..writeln(
          '- Kathmandu Valley Traffic Police: https://traffic.nepalpolice.gov.np/',
        )
        ..writeln('- Ministry of Home Affairs: https://www.moha.gov.np/')
        ..writeln(
          '- National Emergency Operation Center: https://moha.gov.np/en/post/national-emergency-operation-center',
        )
        ..writeln(
          '- Health Emergency Operation Center: https://heoc.mohp.gov.np/information-portal/ambulance-nepal',
        )
        ..writeln(
          '- National Disaster Risk Reduction and Management Authority: https://ndrrma.gov.np/en',
        )
        ..writeln(
          '- National Child Rights Council Child Helpline: https://ncrc.gov.np/pages/child-helpline-service--toll-free-phone-number/',
        )
        ..writeln(
          '- National Women Commission Helpline: https://nwchelpline.gov.np/',
        )
        ..writeln('- Hello Sarkar: https://gunaso.opmcm.gov.np/')
        ..writeln('- Nepal Tourism Board: https://ntb.gov.np/contact-us')
        ..writeln('- Nepal Electricity Authority: https://nea.org.np/')
        ..writeln()
        ..writeln('## Source URL Index')
        ..writeln();

  for (final source in sources) {
    final sourceName =
        source.sourceName.isEmpty ? source.host : source.sourceName;
    final sourceType =
        source.sourceType.isEmpty ? 'Unknown' : source.sourceType;
    final categories = source.categories.take(4).join(', ');
    buffer.writeln(
      '- $sourceName | $sourceType | ${source.count} contact(s) | ${source.url}',
    );
    if (categories.isNotEmpty) {
      buffer.writeln('  Categories: $categories');
    }
  }

  final directory = Directory(docsDirectory);
  if (!directory.existsSync()) {
    await directory.create(recursive: true);
  }
  final file = File('${directory.path}/official_sources.md');
  await file.writeAsString(buffer.toString());

  final rootCopy = File('Official_Sources.md');
  await rootCopy.writeAsString(buffer.toString());

  return file;
}

Future<File> _writeContactSourceRegister(
  List<Map<String, String>> records,
  String docsDirectory,
) async {
  final directory = Directory(docsDirectory);
  if (!directory.existsSync()) {
    await directory.create(recursive: true);
  }
  final rows = <List<String>>[
    <String>[
      'entry_id',
      'organisation',
      'category',
      'source_name',
      'source_type',
      'source_url',
      'verification_status',
      'last_checked',
    ],
    for (final record in records)
      <String>[
        _field(record, 'Entry_ID'),
        _field(record, 'Organisation'),
        _field(record, 'Category'),
        _field(record, 'Source_Name'),
        _field(record, 'Source_Type'),
        _field(record, 'Data_Source_URL'),
        _field(record, 'Verification_Status'),
        _field(record, 'Last_Checked'),
      ],
  ];
  final output = const ListToCsvConverter().convert(rows);
  final file = File('${directory.path}/contact_sources.csv');
  await file.writeAsString('$output\n');
  return file;
}

String _field(Map<String, String> record, String field) {
  return record[field] ?? '';
}

String _hostForUrl(String url) {
  final parsed = Uri.tryParse(url.contains('://') ? url : 'https://$url');
  return parsed?.host.toLowerCase() ?? url;
}

bool _isOfficialSource(_SourceSummary source) {
  final type = source.sourceType.toLowerCase();
  return source.host.endsWith('.gov.np') ||
      source.host.contains('nepalpolice.gov.np') ||
      source.host.contains('nea.org.np') ||
      type.contains('official');
}

class _SourceSummary {
  _SourceSummary({
    required this.url,
    required this.host,
    required this.sourceName,
    required this.sourceType,
  });

  final String url;
  final String host;
  final String sourceName;
  final String sourceType;
  final Set<String> categories = <String>{};
  int count = 0;
}
