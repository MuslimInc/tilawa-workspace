class DeviceInfoSnapshot {
  const DeviceInfoSnapshot({
    this.manufacturer,
    this.model,
    this.os,
    this.osVersion,
    this.appBuildNumber,
    this.appVersion,
  });

  final String? manufacturer;
  final String? model;
  final String? os;
  final String? osVersion;
  final String? appBuildNumber;
  final String? appVersion;

  Map<String, String> toJson() {
    return <String, String>{
      if (_hasValue(manufacturer)) 'manufacturer': manufacturer!,
      if (_hasValue(model)) 'model': model!,
      if (_hasValue(os)) 'os': os!,
      if (_hasValue(osVersion)) 'osVersion': osVersion!,
      if (_hasValue(appBuildNumber)) 'appBuildNumber': appBuildNumber!,
      if (_hasValue(appVersion)) 'appVersion': appVersion!,
    };
  }

  static bool _hasValue(String? value) => value != null && value.isNotEmpty;
}
