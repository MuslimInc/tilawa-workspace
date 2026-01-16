import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';
import 'package:tilawa_core/di/injection.dart';

import 'injection.config.dart';

final GetIt getIt = GetIt.instance;

@InjectableInit()
Future<void> configureDependencies() async {
  await configureCoreDependencies();
  await getIt.init();
}
