import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import 'rule_scope.dart';

/// Requires [TilawaShellChildScaffold] instead of Material [Scaffold] under
/// [TilawaAdaptiveShell] (ADR-009).
final class TilawaShellChildScaffoldRule extends AnalysisRule {
  TilawaShellChildScaffoldRule()
    : super(
        name: 'tilawa_shell_child_scaffold',
        description:
            'Requires TilawaShellChildScaffold for screens under '
            'TilawaAdaptiveShell.',
      );

  static const code = LintCode(
    'tilawa_shell_child_scaffold',
    "Do not use Flutter's Scaffold under TilawaAdaptiveShell; use "
        'TilawaShellChildScaffold.',
    correctionMessage:
        'Replace this Scaffold with TilawaShellChildScaffold from '
        'package:tilawa_ui_kit/tilawa_ui_kit.dart so the shell remains the '
        'sole IME owner (ADR-009). Outside-shell routes may keep Scaffold. '
        'If a shell-hosted exception is required, register it in '
        'component_policy.dart and suppress with '
        '// tilawa-ui-exception: <ID> and '
        '// ignore: tilawa_lints/tilawa_shell_child_scaffold.',
    severity: DiagnosticSeverity.ERROR,
    uniqueName: 'TilawaLintCode.tilawa_shell_child_scaffold',
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

  final TilawaShellChildScaffoldRule rule;
  final RuleContext context;

  static const _scaffoldLibraryUri =
      'package:flutter/src/material/scaffold.dart';

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    final path = context.currentUnit?.file.path;
    if (path == null || !isShellHostedScaffoldScope(path)) {
      return;
    }

    final enclosingClass = node.constructorName.element?.enclosingElement;
    if (enclosingClass?.name != 'Scaffold') {
      return;
    }
    if (enclosingClass?.library.uri.toString() != _scaffoldLibraryUri) {
      return;
    }

    rule.reportAtNode(node.constructorName);
  }
}
