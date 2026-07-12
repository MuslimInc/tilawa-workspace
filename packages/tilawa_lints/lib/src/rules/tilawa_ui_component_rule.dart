import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../component_policy.dart';
import 'rule_scope.dart';

final class TilawaUiComponentRule extends AnalysisRule {
  TilawaUiComponentRule()
    : super(
        name: 'tilawa_ui_component',
        description: 'Requires confirmed UI Kit equivalents in product code.',
      );

  static const code = LintCode(
    'tilawa_ui_component',
    "Do not use Flutter's {0} directly in product code; use the UI Kit "
        'equivalent: {1}.',
    correctionMessage:
        'Import package:tilawa_ui_kit/tilawa_ui_kit.dart and replace this '
        'constructor with {1}. If no UI Kit equivalent fits the use case, '
        'register a reviewed exception in component_policy.dart.',
    severity: DiagnosticSeverity.ERROR,
    uniqueName: 'TilawaLintCode.tilawa_ui_component',
  );

  @override
  DiagnosticCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    registry.addInstanceCreationExpression(this, _Visitor(this, context));
  }
}

final class _Visitor extends SimpleAstVisitor<void> {
  _Visitor(this.rule, this.context);

  final TilawaUiComponentRule rule;
  final RuleContext context;

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    final path = context.currentUnit?.file.path;
    if (path == null || !isProductDartFile(path)) return;

    final enclosingClass = node.constructorName.element?.enclosingElement;
    final libraryUri = enclosingClass?.library.uri.toString();
    for (final policy in componentPolicies) {
      if (policy.className == enclosingClass?.name &&
          policy.libraryUri == libraryUri) {
        rule.reportAtNode(
          node.constructorName,
          arguments: <Object>[
            policy.className,
            policy.replacements.join(' or '),
          ],
        );
        return;
      }
    }
  }
}
