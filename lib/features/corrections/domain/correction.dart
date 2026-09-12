class Correction {
  const Correction({
    required this.id,
    required this.contactId,
    required this.correctionType,
    required this.details,
    required this.createdAt,
    this.status = 'Pending Review',
  });

  final String id;
  final String? contactId;
  final String correctionType;
  final String details;
  final DateTime createdAt;
  final String status;

  Map<String, Object?> toDb() {
    return {
      'id': id,
      'contact_id': contactId,
      'correction_type': correctionType,
      'details': details,
      'created_at': createdAt.toIso8601String(),
      'status': status,
    };
  }
}
