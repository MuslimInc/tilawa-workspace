import '../dtos/teacher_availability_dto.dart';

abstract interface class AvailabilityRemoteDataSource {
  Future<List<TeacherAvailabilityDto>> getSlots(
    String teacherId, {
    required DateTime from,
    required DateTime to,
  });

  Future<void> publishSlot(TeacherAvailabilityDto slot);

  /// Deletes a legacy published slot at a deterministic teacher-scoped path.
  Future<void> withdrawSlot(String teacherId, String slotId);
}
