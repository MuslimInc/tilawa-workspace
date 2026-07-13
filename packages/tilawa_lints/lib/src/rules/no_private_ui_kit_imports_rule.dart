import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import 'rule_scope.dart';

final class NoPrivateUiKitImportsRule extends AnalysisRule {
  NoPrivateUiKitImportsRule()
    : super(
        name: 'no_private_ui_kit_imports',
        description: 'Requires product code to use the public UI Kit API.',
      );

  static const code = LintCode(
    'no_private_ui_kit_imports',
    'Product code must not import private UI Kit src files.',
    correctionMessage:
        'Import package:tilawa_ui_kit/tilawa_ui_kit.dart instead.',
    severity: DiagnosticSeverity.ERROR,
    uniqueName: 'TilawaLintCode.no_private_ui_kit_imports',
  );

  @override
  DiagnosticCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final visitor = _Visitor(this, context);
    registry
      ..addImportDirective(this, visitor)
      ..addExportDirective(this, visitor);
  }
}

final class _Visitor extends SimpleAstVisitor<void> {
  _Visitor(this.rule, this.context);

  final NoPrivateUiKitImportsRule rule;
  final RuleContext context;

  bool get _isProduct {
    final path = context.currentUnit?.file.path;
    return path != null && isProductDartFile(path);
  }

  @override
  void visitImportDirective(ImportDirective node) => _check(node.uri);

  @override
  void visitExportDirective(ExportDirective node) => _check(node.uri);

  void _check(StringLiteral uri) {
    if (_isProduct &&
        (uri.stringValue?.startsWith('package:tilawa_ui_kit/src/') ?? false)) {
      rule.reportAtNode(uri);
    }
  }
}
