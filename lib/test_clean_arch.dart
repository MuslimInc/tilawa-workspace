import 'package:flutter/material.dart';
import 'package:muzakri/core/di/injection_container.dart' as di;
import 'package:muzakri/features/localization/domain/repositories/localization_repository.dart';
import 'package:muzakri/features/reciters/domain/repositories/reciters_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await di.initDI();

  print('Clean Architecture setup completed successfully!');
  print('Available services:');
  print('- RecitersRepository: ${di.sl.isRegistered<RecitersRepository>()}');
  print(
    '- LocalizationRepository: ${di.sl.isRegistered<LocalizationRepository>()}',
  );
}
