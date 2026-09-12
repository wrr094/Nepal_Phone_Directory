import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:nepal_helpline/core/network/remote_contact_data_source.dart';

void main() {
  test('static JSON remote source reads manifest and contacts', () async {
    final client = MockClient((request) async {
      if (request.url.toString() == 'https://example.com/data/manifest.json') {
        return http.Response(
          jsonEncode({
            'data_version': 'contacts-test-1',
            'contacts_url': 'contacts.json',
            'contacts_count': 1,
          }),
          200,
        );
      }
      if (request.url.toString() == 'https://example.com/data/contacts.json') {
        return http.Response(
          jsonEncode([
            {
              'Entry_ID': 'TEST-1',
              'Category': 'Emergency Services',
              'Subcategory': 'Police',
              'Organisation': 'Test Police',
              'Hotline_Code': '100',
              'Is_Emergency': 'Yes',
              'Verification_Status': 'Verified',
            },
          ]),
          200,
        );
      }
      return http.Response('Not found', 404);
    });

    final remote = StaticJsonRemoteContactDataSource(
      manifestUrl: 'https://example.com/data/manifest.json',
      client: client,
    );

    expect(await remote.fetchDataVersion(), 'contacts-test-1');
    final contacts = await remote.fetchContacts();

    expect(contacts, hasLength(1));
    expect(contacts.single.id, 'TEST-1');
    expect(contacts.single.organisationName, 'Test Police');
    expect(contacts.single.hotlineCode, '100');
    expect(contacts.single.isEmergency, isTrue);
  });
}
