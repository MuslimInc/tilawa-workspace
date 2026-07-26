import 'package:equatable/equatable.dart';
import 'package:tilawa_core/errors/failures.dart';

import '../../domain/entities/sadaqah_jariyah_page_data.dart';

sealed class SadaqahJariyahState extends Equatable {
  const SadaqahJariyahState();

  @override
  List<Object?> get props => [];
}

final class SadaqahJariyahInitial extends SadaqahJariyahState {
  const SadaqahJariyahInitial();
}

final class SadaqahJariyahLoading extends SadaqahJariyahState {
  const SadaqahJariyahLoading();
}

final class SadaqahJariyahLoaded extends SadaqahJariyahState {
  const SadaqahJariyahLoaded({
    required this.pageData,
    required this.photoUrls,
  });

  final SadaqahJariyahPageData pageData;

  /// dedicationId → resolved download URL (null if unavailable).
  final Map<String, String?> photoUrls;

  @override
  List<Object?> get props => [pageData, photoUrls];
}

final class SadaqahJariyahError extends SadaqahJariyahState {
  const SadaqahJariyahError(this.failure);

  final Failure failure;

  @override
  List<Object?> get props => [failure];
}
