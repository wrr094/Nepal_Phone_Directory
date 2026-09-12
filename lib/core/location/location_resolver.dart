import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

import '../../features/contacts/data/contact_repository.dart';
import 'location_selection.dart';

class LocationResolutionException implements Exception {
  const LocationResolutionException(this.message);

  final String message;

  @override
  String toString() => message;
}

Future<LocationSelection> resolveCurrentDirectoryLocation(
  ContactRepository repository,
) async {
  final serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    throw const LocationResolutionException('Please enable Location Services.');
  }

  var permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
  }
  if (permission == LocationPermission.denied) {
    throw const LocationResolutionException('Location permission was denied.');
  }
  if (permission == LocationPermission.deniedForever) {
    throw const LocationResolutionException(
      'Location permission is permanently denied. Enable it in Settings.',
    );
  }

  final position = await Geolocator.getCurrentPosition(
    locationSettings: const LocationSettings(
      accuracy: LocationAccuracy.medium,
      timeLimit: Duration(seconds: 12),
    ),
  );
  final placemarks = await placemarkFromCoordinates(
    position.latitude,
    position.longitude,
  );
  if (placemarks.isEmpty) {
    throw const LocationResolutionException(
      'No address found for current location.',
    );
  }

  final candidates = _candidateAddressParts(placemarks.first);
  final province = await _matchPlaceValue(repository, 'province', candidates);
  final district = await _matchPlaceValue(
    repository,
    'district',
    candidates,
    filters: {'province': province ?? ''},
  );
  final palika = await _matchPlaceValue(
    repository,
    'palika',
    candidates,
    filters: {'province': province ?? '', 'district': district ?? ''},
  );

  final location = LocationSelection(
    province: province ?? '',
    district: district ?? '',
    palika: palika ?? '',
  );
  if (location.isEmpty) {
    throw const LocationResolutionException(
      'Could not match your GPS address to local directory locations.',
    );
  }
  return location;
}

List<String> _candidateAddressParts(Placemark placemark) {
  return [
    placemark.administrativeArea,
    placemark.subAdministrativeArea,
    placemark.locality,
    placemark.subLocality,
    placemark.name,
    placemark.street,
    placemark.thoroughfare,
  ].whereType<String>().where((value) => value.trim().isNotEmpty).toList();
}

Future<String?> _matchPlaceValue(
  ContactRepository repository,
  String column,
  List<String> candidates, {
  Map<String, String> filters = const {},
}) async {
  final values = await repository.distinctValues(column, filters: filters);
  final normalizedCandidates =
      candidates
          .map(_normalizePlaceText)
          .where((value) => value.isNotEmpty)
          .toList();

  for (final value in values) {
    final normalizedValue = _normalizePlaceText(value);
    if (normalizedValue.isEmpty) continue;
    for (final candidate in normalizedCandidates) {
      if (normalizedValue == candidate ||
          normalizedValue.contains(candidate) ||
          candidate.contains(normalizedValue)) {
        return value;
      }
    }
  }
  return null;
}

String _normalizePlaceText(String value) {
  return value
      .toLowerCase()
      .replaceAll(
        RegExp(
          r'\b(province|district|metropolitan|submetropolitan|sub metropolitan|municipality|rural|city|ward|gaunpalika|nagarpalika)\b',
        ),
        ' ',
      )
      .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
      .trim();
}
