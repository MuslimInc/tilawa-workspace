import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';
import 'package:tilawa_lints/src/rules/no_private_ui_kit_imports_rule.dart';
import 'package:tilawa_lints/src/rules/valid_tilawa_ui_exception_rule.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NoPrivateUiKitImportsRuleTest);
    defineReflectiveTests(ValidTilawaUiExceptionRuleTest);
  });
}

@reflectiveTest
class NoPrivateUiKitImportsRuleTest extends AnalysisRuleTest {
  @override
  void setUp() {
    newPackage('tilawa_ui_kit')
      ..addFile('lib/tilawa_ui_kit.dart', 'class TilawaAppBar {}')
      ..addFile('lib/src/atoms/private.dart', 'class PrivateWidget {}');
    rule = NoPrivateUiKitImportsRule();
    super.setUp();
  }

  Future<void> test_privateSrcImportRejected() async {
    const source = r'''
import 'package:tilawa_ui_kit/src/atoms/private.dart';
PrivateWidget? value;
''';
    await assertDiagnostics(source, [lint(source.indexOf("'package"), 46)]);
  }

  Future<void> test_publicApiAllowed() async {
    await assertNoDiagnostics(r'''
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';
TilawaAppBar? value;
''');
  }
}

@reflectiveTest
class ValidTilawaUiExceptionRuleTest extends AnalysisRuleTest {
  @override
  String get testFileName => 'router/app_router_config.dart';

  @override
  String get testPackageRootPath => '/home/apps/tilawa';

  @override
  void setUp() {
    rule = ValidTilawaUiExceptionRule();
    super.setUp();
  }

  Future<void> test_unregisteredSuppressionRejected() async {
    const source = r'''
// tilawa-ui-exception: UNKNOWN-123
// ignore: tilawa_ui_component
final value = 1;
''';
    await assertDiagnostics(source, [
      lint(
        source.indexOf('// tilawa'),
        '// tilawa-ui-exception: UNKNOWN-123'.length,
      ),
    ]);
  }

  Future<void> test_registeredSuppressionAccepted() async {
    await assertNoDiagnostics(r'''
// tilawa-ui-exception: UIKIT-APPBAR-ROUTER
// ignore: tilawa_ui_component
final value = 1;
''');
  }
}
