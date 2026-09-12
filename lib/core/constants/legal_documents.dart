import 'app_constants.dart';

class LegalDocument {
  const LegalDocument({
    required this.title,
    required this.iconName,
    required this.sourceUrl,
    required this.fallbackBody,
  });

  final String title;
  final String iconName;
  final String? sourceUrl;
  final String fallbackBody;
}

const legalDocuments = <LegalDocument>[
  LegalDocument(
    title: 'Privacy Policy',
    iconName: 'privacy',
    sourceUrl: 'https://nepal-helpline-data.pages.dev/docs/privacy_policy.md',
    fallbackBody: '''
Privacy Policy

Nepal HelpLine does not require login for normal users and does not collect unnecessary personal information.

The app stores public directory data and locally submitted correction suggestions on your device. Correction suggestions remain pending review and do not automatically update public contact data.

If future online sync is enabled, the app may connect to a configured backend to refresh public directory data. Personal analytics, ads, and tracking are not part of this first version.

If you opt in to National emergency alerts, Firebase Cloud Messaging may process device delivery information to send alerts. Alerts are optional, may be delayed or unavailable, and do not replace official warning systems or emergency services.
''',
  ),
  LegalDocument(
    title: 'Terms of Use',
    iconName: 'terms',
    sourceUrl: 'https://nepal-helpline-data.pages.dev/docs/terms_of_use.md',
    fallbackBody: '''
Terms of Use

Nepal HelpLine is provided as a public phone directory and emergency contact reference. Contact details are collected from public sources and may change.

For urgent emergencies, call national emergency numbers first. Please verify critical services where possible.

User correction suggestions are saved as pending review and must not be treated as verified public data until reviewed.

National emergency alerts are optional notices from an independent app. They do not replace official government warnings, emergency dispatch, or instructions from authorised authorities. Delivery is not guaranteed.
''',
  ),
  LegalDocument(
    title: 'About',
    iconName: 'about',
    sourceUrl: null,
    fallbackBody: '''
About Nepal HelpLine

Nepal HelpLine is a lightweight offline-first public phone directory for Nepal. It is designed for quick access to emergency numbers, public offices, hospitals, utilities, tourism contacts, ward offices, and other public service contacts.

The app is built with Flutter and uses bundled seed data plus local SQLite storage so it can open without internet.
''',
  ),
  LegalDocument(
    title: 'Official Sources',
    iconName: 'sources',
    sourceUrl: AppConstants.officialSourcesUrl,
    fallbackBody: '''
Official Sources

Nepal HelpLine is an independent directory app and does not represent any government entity.

Every published directory record includes an original source URL. Each contact detail page shows its source name, source type, verification status, last checked date, and source URL. The complete source register is published at ${AppConstants.contactSourcesUrl}.

For urgent emergencies, call national emergency numbers first and verify critical services where possible.
''',
  ),
  LegalDocument(
    title: 'Disclaimer',
    iconName: 'disclaimer',
    sourceUrl: null,
    fallbackBody: AppConstants.disclaimer,
  ),
];
