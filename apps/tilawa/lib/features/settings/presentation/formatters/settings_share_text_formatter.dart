import 'package:flutter/foundation.dart';
import 'package:tilawa/l10n/generated/app_localizations.dart';
import 'package:tilawa_core/constants/app_strings.dart';
import 'package:tilawa_core/entities/app_info.dart';

const String _fallbackSharePackageName = 'com.tilawa.app';
const String _defaultAppStoreId = String.fromEnvironment('TILAWA_APP_STORE_ID');

String buildSettingsShareAppText(
  AppLocalizations l10n, {
  AppInfo? appInfo,
  TargetPlatform? platform,
  String? appStoreId,
}) {
  final trimmedAppName = appInfo?.appName.trim();
  final resolvedAppName = trimmedAppName == null || trimmedAppName.isEmpty
      ? AppStrings.appName
      : trimmedAppName;
  final resolvedPlatform = platform ?? defaultTargetPlatform;
  final storeUrl = _resolveShareStoreUrl(
    platform: resolvedPlatform,
    packageName: appInfo?.packageName ?? '',
    appStoreId: appStoreId ?? _defaultAppStoreId,
  );

  return l10n.shareTilawaMessage(resolvedAppName, storeUrl);
}

String _resolveShareStoreUrl({
  required TargetPlatform platform,
  required String packageName,
  String? appStoreId,
}) {
  final resolvedPackageName = packageName.trim().isNotEmpty
      ? packageName.trim()
      : _fallbackSharePackageName;
  final trimmedAppStoreId = appStoreId?.trim();

  if (platform == TargetPlatform.iOS &&
      trimmedAppStoreId != null &&
      trimmedAppStoreId.isNotEmpty) {
    return 'https://apps.apple.com/app/id$trimmedAppStoreId';
  }

  return 'https://play.google.com/store/apps/details?id=$resolvedPackageName';
}
