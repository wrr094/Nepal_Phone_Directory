import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/location/location_selection.dart';

const _defaultAddressModeKey = 'user_default_address_mode';
const _manualLocationKey = 'user_manual_location';
const _lastSearchedLocationKey = 'user_last_searched_location';
const _personalEmergencyContactsKey = 'user_personal_emergency_contacts';
const _emergencyContactPromptDismissedKey =
    'user_emergency_contact_prompt_dismissed';
const maxPersonalEmergencyContacts = 4;

enum DefaultAddressMode {
  manual,
  gps,
  lastSearched;

  String get label {
    return switch (this) {
      DefaultAddressMode.manual => 'Manual location',
      DefaultAddressMode.gps => 'GPS location',
      DefaultAddressMode.lastSearched => 'Last searched location',
    };
  }

  static DefaultAddressMode fromStorage(String? value) {
    return switch (value) {
      'gps' => DefaultAddressMode.gps,
      'last_searched' => DefaultAddressMode.lastSearched,
      _ => DefaultAddressMode.manual,
    };
  }

  String get storageValue {
    return switch (this) {
      DefaultAddressMode.manual => 'manual',
      DefaultAddressMode.gps => 'gps',
      DefaultAddressMode.lastSearched => 'last_searched',
    };
  }
}

enum EmergencyContactActionPreference {
  call,
  text;

  String get label {
    return switch (this) {
      EmergencyContactActionPreference.call => 'Call',
      EmergencyContactActionPreference.text => 'Send text',
    };
  }

  String get storageValue {
    return switch (this) {
      EmergencyContactActionPreference.call => 'call',
      EmergencyContactActionPreference.text => 'text',
    };
  }

  static EmergencyContactActionPreference fromStorage(String? value) {
    return switch (value) {
      'text' => EmergencyContactActionPreference.text,
      _ => EmergencyContactActionPreference.call,
    };
  }
}

class PersonalEmergencyContact {
  const PersonalEmergencyContact({
    required this.id,
    required this.name,
    required this.relationship,
    required this.phone,
    this.actionPreference = EmergencyContactActionPreference.call,
    this.photoPath = '',
  });

  final String id;
  final String name;
  final String relationship;
  final String phone;
  final EmergencyContactActionPreference actionPreference;
  final String photoPath;

  String get displayName {
    final trimmedName = name.trim();
    return trimmedName.isEmpty ? 'Emergency contact' : trimmedName;
  }

  String get subtitle {
    final trimmedRelationship = relationship.trim();
    return trimmedRelationship.isEmpty
        ? phone
        : '$trimmedRelationship • $phone';
  }

  PersonalEmergencyContact copyWith({
    String? id,
    String? name,
    String? relationship,
    String? phone,
    EmergencyContactActionPreference? actionPreference,
    String? photoPath,
  }) {
    return PersonalEmergencyContact(
      id: id ?? this.id,
      name: name ?? this.name,
      relationship: relationship ?? this.relationship,
      phone: phone ?? this.phone,
      actionPreference: actionPreference ?? this.actionPreference,
      photoPath: photoPath ?? this.photoPath,
    );
  }

  Map<String, String> toJson() {
    return {
      'id': id,
      'name': name,
      'relationship': relationship,
      'phone': phone,
      'action_preference': actionPreference.storageValue,
      'photo_path': photoPath,
    };
  }

  factory PersonalEmergencyContact.fromJson(Map<String, Object?> json) {
    return PersonalEmergencyContact(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      relationship: json['relationship']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      actionPreference: EmergencyContactActionPreference.fromStorage(
        json['action_preference']?.toString(),
      ),
      photoPath: json['photo_path']?.toString() ?? '',
    );
  }
}

class UserPreferences {
  const UserPreferences({
    required this.defaultAddressMode,
    required this.manualLocation,
    required this.lastSearchedLocation,
    required this.personalEmergencyContacts,
    required this.emergencyContactPromptDismissed,
  });

  final DefaultAddressMode defaultAddressMode;
  final LocationSelection manualLocation;
  final LocationSelection lastSearchedLocation;
  final List<PersonalEmergencyContact> personalEmergencyContacts;
  final bool emergencyContactPromptDismissed;

  LocationSelection get selectedStoredLocation {
    return switch (defaultAddressMode) {
      DefaultAddressMode.manual => manualLocation,
      DefaultAddressMode.lastSearched => lastSearchedLocation,
      DefaultAddressMode.gps => const LocationSelection(),
    };
  }

  UserPreferences copyWith({
    DefaultAddressMode? defaultAddressMode,
    LocationSelection? manualLocation,
    LocationSelection? lastSearchedLocation,
    List<PersonalEmergencyContact>? personalEmergencyContacts,
    bool? emergencyContactPromptDismissed,
  }) {
    return UserPreferences(
      defaultAddressMode: defaultAddressMode ?? this.defaultAddressMode,
      manualLocation: manualLocation ?? this.manualLocation,
      lastSearchedLocation: lastSearchedLocation ?? this.lastSearchedLocation,
      personalEmergencyContacts:
          personalEmergencyContacts ?? this.personalEmergencyContacts,
      emergencyContactPromptDismissed:
          emergencyContactPromptDismissed ??
          this.emergencyContactPromptDismissed,
    );
  }
}

final userPreferencesProvider =
    AsyncNotifierProvider<UserPreferencesController, UserPreferences>(
      UserPreferencesController.new,
    );

class UserPreferencesController extends AsyncNotifier<UserPreferences> {
  @override
  Future<UserPreferences> build() => _load();

  Future<void> setDefaultAddressMode(DefaultAddressMode mode) async {
    final current = await future;
    await _save(current.copyWith(defaultAddressMode: mode));
  }

  Future<void> setManualLocation(LocationSelection location) async {
    final current = await future;
    await _save(current.copyWith(manualLocation: location));
  }

  Future<void> setManualDefaultLocation(LocationSelection location) async {
    final current = await future;
    await _save(
      current.copyWith(
        defaultAddressMode: DefaultAddressMode.manual,
        manualLocation: location,
      ),
    );
  }

  Future<void> setLastSearchedLocation(LocationSelection location) async {
    if (location.isEmpty) return;
    final current = await future;
    await _save(
      current.copyWith(
        lastSearchedLocation: location,
        emergencyContactPromptDismissed:
            current.emergencyContactPromptDismissed,
      ),
    );
  }

  Future<void> saveEmergencyContact(PersonalEmergencyContact contact) async {
    final current = await future;
    final contacts = [...current.personalEmergencyContacts];
    final index = contacts.indexWhere((item) => item.id == contact.id);
    if (index == -1) {
      if (contacts.length >= maxPersonalEmergencyContacts) return;
      contacts.add(contact);
    } else {
      contacts[index] = contact;
    }
    await _save(
      current.copyWith(
        personalEmergencyContacts: contacts,
        emergencyContactPromptDismissed: contacts.isNotEmpty,
      ),
    );
  }

  Future<void> removeEmergencyContact(String id) async {
    final current = await future;
    final contacts = current.personalEmergencyContacts
        .where((contact) => contact.id != id)
        .toList(growable: false);
    await _save(current.copyWith(personalEmergencyContacts: contacts));
  }

  Future<void> setEmergencyContactPromptDismissed(bool dismissed) async {
    final current = await future;
    await _save(current.copyWith(emergencyContactPromptDismissed: dismissed));
  }

  Future<UserPreferences> _load() async {
    final prefs = await SharedPreferences.getInstance();
    return UserPreferences(
      defaultAddressMode: DefaultAddressMode.fromStorage(
        prefs.getString(_defaultAddressModeKey),
      ),
      manualLocation: _decodeLocation(prefs.getString(_manualLocationKey)),
      lastSearchedLocation: _decodeLocation(
        prefs.getString(_lastSearchedLocationKey),
      ),
      personalEmergencyContacts: _decodeContacts(
        prefs.getString(_personalEmergencyContactsKey),
      ),
      emergencyContactPromptDismissed:
          prefs.getBool(_emergencyContactPromptDismissedKey) ?? false,
    );
  }

  Future<void> _save(UserPreferences preferences) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _defaultAddressModeKey,
      preferences.defaultAddressMode.storageValue,
    );
    await prefs.setString(
      _manualLocationKey,
      jsonEncode(preferences.manualLocation.toJson()),
    );
    await prefs.setString(
      _lastSearchedLocationKey,
      jsonEncode(preferences.lastSearchedLocation.toJson()),
    );
    await prefs.setString(
      _personalEmergencyContactsKey,
      jsonEncode(
        preferences.personalEmergencyContacts
            .map((contact) => contact.toJson())
            .toList(),
      ),
    );
    await prefs.setBool(
      _emergencyContactPromptDismissedKey,
      preferences.emergencyContactPromptDismissed,
    );
    state = AsyncData(preferences);
  }
}

LocationSelection _decodeLocation(String? raw) {
  if (raw == null || raw.trim().isEmpty) return const LocationSelection();
  final decoded = jsonDecode(raw);
  if (decoded is! Map<String, Object?>) return const LocationSelection();
  return LocationSelection.fromJson(decoded);
}

List<PersonalEmergencyContact> _decodeContacts(String? raw) {
  if (raw == null || raw.trim().isEmpty) return const [];
  final decoded = jsonDecode(raw);
  if (decoded is! List) return const [];
  return decoded
      .whereType<Map<Object?, Object?>>()
      .map(
        (item) =>
            PersonalEmergencyContact.fromJson(Map<String, Object?>.from(item)),
      )
      .where((contact) => contact.phone.trim().isNotEmpty)
      .take(maxPersonalEmergencyContacts)
      .toList(growable: false);
}
