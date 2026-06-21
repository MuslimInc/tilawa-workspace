class TeacherApplicationDto {
  const TeacherApplicationDto({
    required this.id,
    required this.userId,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.phoneNumber,
    this.phoneCountryCode,
    this.preferredContactMethod,
    this.teachingLanguages = const [],
    this.specializations = const [],
    this.bio,
    this.submittedAt,
    this.reviewedAt,
    this.reviewedBy,
    this.rejectionReason,
  });

  final String id;
  final String userId;
  final String status;
  final String? phoneNumber;
  final String? phoneCountryCode;
  final String? preferredContactMethod;
  final List<String> teachingLanguages;
  final List<String> specializations;
  final String? bio;
  final DateTime? submittedAt;
  final DateTime? reviewedAt;
  final String? reviewedBy;
  final String? rejectionReason;
  final DateTime createdAt;
  final DateTime updatedAt;
}
