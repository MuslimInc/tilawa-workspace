import 'package:equatable/equatable.dart';

/// Teacher-supplied qualification (ijazah, certification, etc.).
class TeacherCredential extends Equatable {
  const TeacherCredential({
    required this.title,
    this.issuer,
    this.isVerified = false,
  });

  final String title;
  final String? issuer;

  /// True when an admin has verified this credential on the backend.
  final bool isVerified;

  @override
  List<Object?> get props => [title, issuer, isVerified];
}
