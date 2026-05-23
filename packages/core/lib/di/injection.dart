import 'package:injectable/injectable.dart';

/// Micro-package entry for [injectable] 3.x code generation.
///
/// Generates [TilawaCorePackageModule]; the host app must include it via
/// [InjectableInit.externalPackageModulesBefore].
@InjectableInit.microPackage()
void initMicroPackage() {}
