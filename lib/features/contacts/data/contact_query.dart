class ContactQuery {
  const ContactQuery({
    this.searchTerm = '',
    this.province,
    this.district,
    this.palika,
    this.category,
    this.verificationStatus,
    this.emergencyOnly = false,
    this.open247Only = false,
    this.limit = 50,
    this.offset = 0,
  });
  static const Object _unset = Object();

  final String searchTerm;
  final String? province;
  final String? district;
  final String? palika;
  final String? category;
  final String? verificationStatus;
  final bool emergencyOnly;
  final bool open247Only;
  final int limit;
  final int offset;

  ContactQuery copyWith({
    String? searchTerm,
    Object? province = _unset,
    Object? district = _unset,
    Object? palika = _unset,
    Object? category = _unset,
    Object? verificationStatus = _unset,
    bool? emergencyOnly,
    bool? open247Only,
    int? limit,
    int? offset,
  }) {
    return ContactQuery(
      searchTerm: searchTerm ?? this.searchTerm,
      province: province == _unset ? this.province : province as String?,
      district: district == _unset ? this.district : district as String?,
      palika: palika == _unset ? this.palika : palika as String?,
      category: category == _unset ? this.category : category as String?,
      verificationStatus:
          verificationStatus == _unset
              ? this.verificationStatus
              : verificationStatus as String?,
      emergencyOnly: emergencyOnly ?? this.emergencyOnly,
      open247Only: open247Only ?? this.open247Only,
      limit: limit ?? this.limit,
      offset: offset ?? this.offset,
    );
  }
}
