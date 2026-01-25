import 'package:equatable/equatable.dart';

class AppInfo extends Equatable {
  const AppInfo({
    required this.version,
    required this.buildNumber,
    required this.appName,
    required this.packageName,
  });

  final String version;
  final String buildNumber;
  final String appName;
  final String packageName;

  @override
  List<Object?> get props => [version, buildNumber, appName, packageName];
}
