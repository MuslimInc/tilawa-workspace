import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';
import 'package:tilawa_lints/src/rules/tilawa_shell_child_scaffold_rule.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(TilawaShellChildScaffoldRuleTest);
    defineReflectiveTests(ShellChildScaffoldOutsideShellTest);
    defineReflectiveTests(ShellChildScaffoldUiKitInternalTest);
  });
}

@reflectiveTest
class TilawaShellChildScaffoldRuleTest extends AnalysisRuleTest {
  @override
  String get testFileName =>
      'features/smart_khatma/presentation/screens/smart_khatma_hub_screen.dart';

  @override
  String get testPackageRootPath => '/home/apps/tilawa';

  @override
  void setUp() {
    newPackage('flutter').addFile(
      'lib/src/material/scaffold.dart',
      'class Scaffold { const Scaffold({Object? body, Object? appBar}); }',
    );
    rule = TilawaShellChildScaffoldRule();
    super.setUp();
  }

  Future<void> test_rawScaffoldRejectedUnderShell() async {
    const source = r'''
import 'package:flutter/src/material/scaffold.dart';
final value = Scaffold(body: null);
''';
    await assertDiagnostics(source, [
      lint(source.indexOf('Scaffold('), 'Scaffold'.length),
    ]);
  }

  Future<void> test_prefixedScaffoldRejected() async {
    const source = r'''
import 'package:flutter/src/material/scaffold.dart' as material;
final value = material.Scaffold(body: null);
''';
    await assertDiagnostics(source, [
      lint(source.indexOf('material.Scaffold'), 'material.Scaffold'.length),
    ]);
  }

  Future<void> test_ignoreDirectiveAccepted() async {
    // Unit harness accepts bare lint name; app analysis needs
    // `tilawa_lints/tilawa_shell_child_scaffold` (plugin-prefixed).
    await assertNoDiagnostics(r'''
import 'package:flutter/src/material/scaffold.dart';
// ignore: tilawa_shell_child_scaffold
final value = Scaffold(body: null);
''');
  }
}

@reflectiveTest
class ShellChildScaffoldOutsideShellTest extends AnalysisRuleTest {
  @override
  String get testFileName =>
      'features/auth/presentation/screens/login_screen.dart';

  @override
  String get testPackageRootPath => '/home/apps/tilawa';

  @override
  void setUp() {
    newPackage('flutter').addFile(
      'lib/src/material/scaffold.dart',
      'class Scaffold { const Scaffold({Object? body}); }',
    );
    rule = TilawaShellChildScaffoldRule();
    super.setUp();
  }

  Future<void> test_outsideShellMayUseRawScaffold() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/src/material/scaffold.dart';
final value = Scaffold(body: null);
''');
  }
}

@reflectiveTest
class ShellChildScaffoldUiKitInternalTest extends AnalysisRuleTest {
  @override
  void setUp() {
    newPackage('flutter').addFile(
      'lib/src/material/scaffold.dart',
      'class Scaffold { const Scaffold({Object? body}); }',
    );
    rule = TilawaShellChildScaffoldRule();
    super.setUp();
  }

  @override
  String get testPackageRootPath => '/home/packages/ui_kit';

  Future<void> test_uiKitImplementationIsAllowed() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/src/material/scaffold.dart';
final value = Scaffold(body: null);
''');
  }
}
