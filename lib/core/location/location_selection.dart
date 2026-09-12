class LocationSelection {
  const LocationSelection({
    this.province = '',
    this.district = '',
    this.palika = '',
  });

  factory LocationSelection.fromJson(Map<String, Object?> json) {
    return LocationSelection(
      province: json['province']?.toString() ?? '',
      district: json['district']?.toString() ?? '',
      palika: json['palika']?.toString() ?? '',
    );
  }

  final String province;
  final String district;
  final String palika;

  bool get isEmpty =>
      province.trim().isEmpty &&
      district.trim().isEmpty &&
      palika.trim().isEmpty;

  bool get isNotEmpty => !isEmpty;

  String get label {
    final parts =
        [
          province,
          district,
          palika,
        ].where((value) => value.trim().isNotEmpty).toList();
    return parts.isEmpty ? 'Not set' : parts.join(' / ');
  }

  LocationSelection copyWith({
    String? province,
    String? district,
    String? palika,
  }) {
    return LocationSelection(
      province: province ?? this.province,
      district: district ?? this.district,
      palika: palika ?? this.palika,
    );
  }

  Map<String, String> toJson() {
    return {'province': province, 'district': district, 'palika': palika};
  }
}
