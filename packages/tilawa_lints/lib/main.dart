import 'package:analysis_server_plugin/plugin.dart';
import 'package:analysis_server_plugin/registry.dart';

import 'src/rules/no_private_ui_kit_imports_rule.dart';
import 'src/rules/tilawa_ui_component_rule.dart';
import 'src/rules/valid_tilawa_ui_exception_rule.dart';

final plugin = _TilawaLintPlugin();

final class _TilawaLintPlugin extends Plugin {
  @override
  String get name => 'Tilawa repository policy';

  @override
  void register(PluginRegistry registry) {
    registry
      ..registerWarningRule(TilawaUiComponentRule())
      ..registerWarningRule(NoPrivateUiKitImportsRule())
      ..registerWarningRule(ValidTilawaUiExceptionRule());
  }
}
