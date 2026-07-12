import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';
import 'package:tilawa_lints/src/rules/tilawa_ui_component_rule.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(TilawaUiComponentRuleTest);
    defineReflectiveTests(GeneratedFileTest);
    defineReflectiveTests(UiKitInternalTest);
  });
}

@reflectiveTest
class TilawaUiComponentRuleTest extends AnalysisRuleTest {
  @override
  void setUp() {
    newPackage('flutter').addFile('lib/src/material/app_bar.dart', r'''
class AppBar { const AppBar({Object? title}); const AppBar.named(); }
class SliverAppBar { const SliverAppBar({Object? title}); }
class Row { const Row(); }
class Column { const Column(); }
class Padding { const Padding(); }
class Stack { const Stack(); }
class SizedBox { const SizedBox(); }
class Expanded { const Expanded(); }
class ListView { const ListView(); }
class CustomAppBar { const CustomAppBar(); }
''');
    rule = TilawaUiComponentRule();
    super.setUp();
  }

  Future<void> test_prefixedImport() async {
    const source = r'''
import 'package:flutter/src/material/app_bar.dart' as material;
final value = material.AppBar(title: 'Title');
''';
    await assertDiagnostics(source, [
      lint(source.indexOf('material.AppBar'), 'material.AppBar'.length),
    ]);
  }

  Future<void> test_aliasedImportShow() async {
    const source = r'''
import 'package:flutter/src/material/app_bar.dart' show AppBar;
final value = AppBar();
''';
    await assertDiagnostics(source, [
      lint(source.indexOf('AppBar();'), 'AppBar'.length),
    ]);
  }

  Future<void> test_commentsStringsAndSimilarNames() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/src/material/app_bar.dart' show CustomAppBar;
// AppBar(title: 'comment')
const text = 'SliverAppBar()';
final value = CustomAppBar();
''');
  }

  Future<void> test_multilineNamedAndSliverConstructors() async {
    const source = r'''
import 'package:flutter/src/material/app_bar.dart';
final first = AppBar.named();
final second = SliverAppBar(
  title: 'Title',
);
''';
    await assertDiagnostics(source, [
      lint(source.indexOf('AppBar.named'), 'AppBar.named'.length),
      lint(source.indexOf('SliverAppBar'), 'SliverAppBar'.length),
    ]);
  }

  Future<void> test_subclassingAndLayoutPrimitives() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/src/material/app_bar.dart';
class ProductBar extends AppBar { const ProductBar(); }
final values = [Row(), Column(), Padding(), Stack(), SizedBox(), Expanded(), ListView()];
''');
  }

  Future<void> test_explicitReviewedSuppression() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/src/material/app_bar.dart';
// tilawa-ui-exception: UIKIT-APPBAR-ROUTER
// ignore: tilawa_ui_component
final value = AppBar();
''');
  }
}

@reflectiveTest
class GeneratedFileTest extends AnalysisRuleTest {
  @override
  void setUp() {
    newPackage('flutter').addFile(
      'lib/src/material/app_bar.dart',
      'class AppBar { const AppBar(); }',
    );
    rule = TilawaUiComponentRule();
    super.setUp();
  }

  @override
  String get testFileName => 'fixture.g.dart';

  Future<void> test_generatedFileIsAllowed() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/src/material/app_bar.dart';
final value = AppBar();
''');
  }
}

@reflectiveTest
class UiKitInternalTest extends AnalysisRuleTest {
  @override
  void setUp() {
    newPackage('flutter').addFile(
      'lib/src/material/app_bar.dart',
      'class AppBar { const AppBar(); }',
    );
    rule = TilawaUiComponentRule();
    super.setUp();
  }

  @override
  String get testPackageRootPath => '/home/packages/ui_kit';

  Future<void> test_uiKitImplementationIsAllowed() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/src/material/app_bar.dart';
final value = AppBar();
''');
  }
}
