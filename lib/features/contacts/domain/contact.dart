import '../../../core/constants/short_codes.dart';
import '../../../core/utils/phone_utils.dart';

class Contact {
  const Contact({
    required this.id,
    required this.category,
    required this.subcategory,
    required this.organisationName,
    required this.nameNepali,
    required this.description,
    required this.province,
    required this.district,
    required this.palika,
    required this.ward,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.primaryPhone,
    required this.secondaryPhone,
    required this.hotlineCode,
    required this.fax,
    required this.email,
    required this.website,
    required this.keyPersons,
    required this.department,
    required this.workingHours,
    required this.is247,
    required this.isEmergency,
    required this.sourceName,
    required this.sourceType,
    required this.sourceUrl,
    required this.verificationStatus,
    required this.confidenceLevel,
    required this.lastChecked,
    required this.notes,
  });

  factory Contact.seed({
    required String id,
    required String category,
    required String subcategory,
    required String organisationName,
    String hotlineCode = '',
    bool isEmergency = false,
    bool is247 = false,
    String verificationStatus = 'Unverified',
    String sourceType = 'Unknown',
  }) {
    return Contact(
      id: id,
      category: category,
      subcategory: subcategory,
      organisationName: organisationName,
      nameNepali: '',
      description: '',
      province: 'National',
      district: 'National',
      palika: 'National',
      ward: '',
      address: '',
      latitude: '',
      longitude: '',
      primaryPhone: '',
      secondaryPhone: '',
      hotlineCode: hotlineCode,
      fax: '',
      email: '',
      website: '',
      keyPersons: '',
      department: '',
      workingHours: '',
      is247: is247,
      isEmergency: isEmergency,
      sourceName: '',
      sourceType: sourceType,
      sourceUrl: '',
      verificationStatus: verificationStatus,
      confidenceLevel: '',
      lastChecked: '',
      notes: '',
    );
  }

  factory Contact.fromCsv(Map<String, String> row, int fallbackIndex) {
    String read(String key) => row[_key(key)]?.trim() ?? '';
    final hotline = read('hotline_code');
    final primary = read('primary_phone');
    final secondary = read('secondary_phone');
    final isEmergency =
        _parseBool(read('is_emergency')) ||
        _containsHighlightedShortCode(hotline) ||
        _containsHighlightedShortCode(primary) ||
        _containsHighlightedShortCode(secondary);

    return Contact(
      id:
          read('id').isNotEmpty
              ? read('id')
              : read('entry_id').isNotEmpty
              ? read('entry_id')
              : 'seed-$fallbackIndex',
      category: _fallback(read('category'), 'Other'),
      subcategory: read('subcategory'),
      organisationName: _fallback(
        read('organisation_name'),
        read('organisation'),
      ),
      nameNepali: read('name_nepali'),
      description: read('description'),
      province: read('province'),
      district: read('district'),
      palika: read('palika'),
      ward: read('ward'),
      address: read('address'),
      latitude: read('latitude'),
      longitude: read('longitude'),
      primaryPhone: primary,
      secondaryPhone: secondary,
      hotlineCode: hotline,
      fax: read('fax'),
      email: read('email'),
      website: read('website'),
      keyPersons: read('key_persons'),
      department: read('department'),
      workingHours: read('working_hours'),
      is247: _parseBool(read('is_24_7')),
      isEmergency: isEmergency,
      sourceName: read('source_name'),
      sourceType: _normalizeSourceType(read('source_type')),
      sourceUrl: _fallback(read('source_url'), read('data_source_url')),
      verificationStatus: _normalizeVerification(read('verification_status')),
      confidenceLevel: read('confidence_level'),
      lastChecked: read('last_checked'),
      notes: read('notes'),
    );
  }

  factory Contact.fromDb(Map<String, Object?> map) {
    String read(String key) => (map[key] as String?) ?? '';
    return Contact(
      id: read('id'),
      category: read('category'),
      subcategory: read('subcategory'),
      organisationName: read('organisation_name'),
      nameNepali: read('name_nepali'),
      description: read('description'),
      province: read('province'),
      district: read('district'),
      palika: read('palika'),
      ward: read('ward'),
      address: read('address'),
      latitude: read('latitude'),
      longitude: read('longitude'),
      primaryPhone: read('primary_phone'),
      secondaryPhone: read('secondary_phone'),
      hotlineCode: read('hotline_code'),
      fax: read('fax'),
      email: read('email'),
      website: read('website'),
      keyPersons: read('key_persons'),
      department: read('department'),
      workingHours: read('working_hours'),
      is247: map['is_24_7'] == 1,
      isEmergency: map['is_emergency'] == 1,
      sourceName: read('source_name'),
      sourceType: read('source_type'),
      sourceUrl: read('source_url'),
      verificationStatus: read('verification_status'),
      confidenceLevel: read('confidence_level'),
      lastChecked: read('last_checked'),
      notes: read('notes'),
    );
  }

  final String id;
  final String category;
  final String subcategory;
  final String organisationName;
  final String nameNepali;
  final String description;
  final String province;
  final String district;
  final String palika;
  final String ward;
  final String address;
  final String latitude;
  final String longitude;
  final String primaryPhone;
  final String secondaryPhone;
  final String hotlineCode;
  final String fax;
  final String email;
  final String website;
  final String keyPersons;
  final String department;
  final String workingHours;
  final bool is247;
  final bool isEmergency;
  final String sourceName;
  final String sourceType;
  final String sourceUrl;
  final String verificationStatus;
  final String confidenceLevel;
  final String lastChecked;
  final String notes;

  List<String> get phoneNumbers => <String>[
    ...PhoneUtils.splitMultiplePhoneNumbers(primaryPhone),
    ...PhoneUtils.splitMultiplePhoneNumbers(secondaryPhone),
    ...PhoneUtils.splitMultiplePhoneNumbers(hotlineCode),
  ];

  Map<String, Object?> toDb() {
    return {
      'id': id,
      'category': category,
      'subcategory': subcategory,
      'organisation_name': organisationName,
      'name_nepali': nameNepali,
      'description': description,
      'province': province,
      'district': district,
      'palika': palika,
      'ward': ward,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'primary_phone': primaryPhone,
      'secondary_phone': secondaryPhone,
      'hotline_code': hotlineCode,
      'fax': fax,
      'email': email,
      'website': website,
      'key_persons': keyPersons,
      'department': department,
      'working_hours': workingHours,
      'is_24_7': is247 ? 1 : 0,
      'is_emergency': isEmergency ? 1 : 0,
      'source_name': sourceName,
      'source_type': sourceType,
      'source_url': sourceUrl,
      'verification_status': verificationStatus,
      'confidence_level': confidenceLevel,
      'last_checked': lastChecked,
      'notes': notes,
    };
  }

  static String _key(String value) {
    return value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
  }

  static bool _parseBool(String value) {
    final normalized = value.trim().toLowerCase();
    return normalized == 'yes' ||
        normalized == 'true' ||
        normalized == '1' ||
        normalized == 'y';
  }

  static String _fallback(String value, String fallback) {
    return value.trim().isEmpty ? fallback.trim() : value.trim();
  }

  static bool _containsHighlightedShortCode(String value) {
    return PhoneUtils.splitMultiplePhoneNumbers(value).any((phone) {
      return highlightedShortCodes.contains(
        PhoneUtils.normalizePhoneForCall(phone),
      );
    });
  }

  static String _normalizeVerification(String value) {
    final normalized = value.trim().toLowerCase();
    if (normalized == 'verified') return 'Verified';
    if (normalized == 'needs review' || normalized == 'review') {
      return 'Needs Review';
    }
    return 'Unverified';
  }

  static String _normalizeSourceType(String value) {
    final normalized = value.trim().toLowerCase();
    if (normalized.contains('government') ||
        normalized.contains('municipality')) {
      return 'Official Government';
    }
    if (normalized.contains('hospital')) return 'Official Hospital';
    if (normalized.contains('police') || normalized.contains('security')) {
      return 'Police / Security Official';
    }
    if (normalized.contains('utility') || normalized.contains('electric')) {
      return 'Utility Official';
    }
    if (normalized.contains('ngo')) return 'NGO Official';
    if (normalized.contains('organisation') ||
        normalized.contains('organization')) {
      return 'Official Organisation';
    }
    if (normalized.contains('directory')) return 'Directory';
    if (normalized.contains('blog')) return 'Blog';
    if (normalized.contains('social')) return 'Social Media';
    if (normalized.contains('user')) return 'User Submitted';
    return value.trim().isEmpty ? 'Unknown' : value.trim();
  }
}
