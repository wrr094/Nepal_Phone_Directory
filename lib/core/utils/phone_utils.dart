import 'package:url_launcher/url_launcher.dart';

class PhoneUtils {
  static List<String> splitMultiplePhoneNumbers(String? value) {
    final raw = value?.trim();
    if (raw == null || raw.isEmpty) return const [];

    return raw
        .split(RegExp(r'[,;/|]|\s+or\s+|\s+and\s+', caseSensitive: false))
        .map((number) => number.trim())
        .where((number) => number.isNotEmpty)
        .toList(growable: false);
  }

  static String normalizePhoneForDisplay(String value) {
    return value.trim().replaceAll(RegExp(r'\s+'), ' ');
  }

  static String normalizePhoneForCall(String value) {
    return value.trim().replaceAll(RegExp(r'[^0-9+]'), '');
  }

  static bool isShortCode(String value) {
    final normalized = normalizePhoneForCall(value);
    return RegExp(r'^[0-9]{3,5}$').hasMatch(normalized);
  }

  static bool isRecognizedNepalPersonalPhone(String value) {
    final normalized = normalizePhoneForCall(value);
    if (RegExp(r'^9[0-9]{9}$').hasMatch(normalized)) return true;
    if (RegExp(r'^0[0-9]{8}$').hasMatch(normalized)) return true;
    if (RegExp(r'^\+9779[0-9]{9}$').hasMatch(normalized)) return true;
    if (RegExp(r'^\+977[0-9]{8}$').hasMatch(normalized)) return true;
    return false;
  }

  static Future<bool> call(String value) async {
    final normalized = normalizePhoneForCall(value);
    if (normalized.isEmpty) return false;
    final uri = Uri(scheme: 'tel', path: normalized);
    return launchUrl(uri);
  }

  static Future<bool> text(String value) async {
    final normalized = normalizePhoneForCall(value);
    if (normalized.isEmpty) return false;
    final uri = Uri(scheme: 'sms', path: normalized);
    return launchUrl(uri);
  }
}

bool isValidEmail(String? value) {
  final email = value?.trim();
  if (email == null || email.isEmpty || email.contains(';')) return false;
  return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);
}

bool isValidWebsite(String? value) {
  final website = value?.trim();
  if (website == null || website.isEmpty) return false;
  final uri = Uri.tryParse(website);
  return uri != null && (uri.scheme == 'http' || uri.scheme == 'https');
}
