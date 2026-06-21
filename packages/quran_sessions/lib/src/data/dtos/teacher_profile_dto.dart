class TeacherProfileDto {
  const TeacherProfileDto({
    required this.id,
    required this.userId,
    required this.displayName,
    required this.verificationStatus,
    required this.teachingLanguages,
    required this.specializations,
    required this.averageRating,
    required this.reviewCount,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.avatarUrl,
    this.publicBio,
    this.allowedStudentGender,
    this.canTeachChildren = true,
  });

  final String id;
  final String userId;
  final String displayName;
  final String? avatarUrl;
  final String? publicBio;
  final String verificationStatus;
  final List<String> teachingLanguages;
  final List<String> specializations;
  final double averageRating;
  final int reviewCount;
  final bool isActive;
  final String? allowedStudentGender;
  final bool canTeachChildren;
  final DateTime createdAt;
  final DateTime updatedAt;
}
