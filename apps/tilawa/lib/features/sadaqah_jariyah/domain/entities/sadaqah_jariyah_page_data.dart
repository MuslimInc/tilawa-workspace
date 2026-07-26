import 'package:equatable/equatable.dart';

import 'dedication.dart';
import 'sadaqah_jariyah_config.dart';

class SadaqahJariyahPageData extends Equatable {
  const SadaqahJariyahPageData({
    required this.config,
    required this.dedications,
  });

  final SadaqahJariyahConfig config;
  final List<Dedication> dedications;

  @override
  List<Object?> get props => [config, dedications];
}
