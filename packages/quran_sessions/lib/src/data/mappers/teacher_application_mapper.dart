import '../../domain/entities/teacher_application.dart';
import '../dtos/teacher_application_dto.dart';

extension TeacherApplicationDtoMapper on TeacherApplicationDto {
  TeacherApplication toDomain() => TeacherApplication(
    id: id,
    userId: userId,
    status: _mapStatus(status),
    phoneNumber: phoneNumber,
    phoneCountryCode: phoneCountryCode,
    preferredContactMethod: preferredContactMethod == null
        ? null
        : _mapContactMethod(preferredContactMethod!),
    publicDisplayName: publicDisplayName,
    teachingLanguages: teachingLanguages,
    specializations: specializations,
    bio: bio,
    submittedAt: submittedAt,
    reviewedAt: reviewedAt,
    reviewedBy: reviewedBy,
    rejectionReason: rejectionReason,
    createdAt: createdAt,
    updatedAt: updatedAt,
  );
}

extension TeacherApplicationDomainMapper on TeacherApplication {
  TeacherApplicationDto toDto() => TeacherApplicationDto(
    id: id,
    userId: userId,
    status: status.name,
    phoneNumber: phoneNumber,
    phoneCountryCode: phoneCountryCode,
    preferredContactMethod: preferredContactMethod?.name,
    publicDisplayName: publicDisplayName,
    teachingLanguages: teachingLanguages,
    specializations: specializations,
    bio: bio,
    submittedAt: submittedAt,
    reviewedAt: reviewedAt,
    reviewedBy: reviewedBy,
    rejectionReason: rejectionReason,
    createdAt: createdAt,
    updatedAt: updatedAt,
  );
}

TeacherApplicationStatus _mapStatus(String raw) => switch (raw) {
  'draft' => TeacherApplicationStatus.draft,
  'pending' => TeacherApplicationStatus.pending,
  'approved' => TeacherApplicationStatus.approved,
  'rejected' => TeacherApplicationStatus.rejected,
  'suspended' => TeacherApplicationStatus.suspended,
  'revoked' => TeacherApplicationStatus.revoked,
  _ => TeacherApplicationStatus.none,
};

PreferredContactMethod _mapContactMethod(String raw) => switch (raw) {
  'phone' => PreferredContactMethod.phone,
  'email' => PreferredContactMethod.email,
  _ => PreferredContactMethod.whatsapp,
};
