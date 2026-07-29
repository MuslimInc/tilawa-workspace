import 'package:dartz_plus/dartz_plus.dart';
import 'package:tilawa_core/utils/typedefs.dart';

import '../../domain/entities/sadaqah_jariyah_config.dart';
import '../../domain/repositories/sadaqah_jariyah_config_repository.dart';
import '../datasources/sadaqah_jariyah_config_remote_data_source.dart';

class SadaqahJariyahConfigRepositoryImpl
    implements SadaqahJariyahConfigRepository {
  SadaqahJariyahConfigRepositoryImpl(this._remote);

  final SadaqahJariyahConfigRemoteDataSource _remote;

  @override
  ResultFuture<SadaqahJariyahConfig> getConfig() async {
    final SadaqahJariyahConfig config = await _remote.getConfig();
    return Right(config);
  }
}
