import '../../domain/entities/teacher_availability.dart';
import '../dtos/teacher_availability_dto.dart';

extension TeacherAvailabilityDtoMapper on TeacherAvailabilityDto {
  TeacherAvailability toDomain() => TeacherAvailability(
    slotId: slotId,
    teacherId: teacherId,
    startsAt: DateTime.parse(startsAt),
    endsAt: DateTime.parse(endsAt),
    isBooked: isBooked,
  );
}

extension TeacherAvailabilityDomainMapper on TeacherAvailability {
  TeacherAvailabilityDto toDto() => TeacherAvailabilityDto(
    slotId: slotId,
    teacherId: teacherId,
    startsAt: startsAt.toUtc().toIso8601String(),
    endsAt: endsAt.toUtc().toIso8601String(),
    isBooked: isBooked,
  );
}
