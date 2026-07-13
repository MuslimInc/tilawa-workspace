import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../component_policy.dart';
import 'rule_scope.dart';

final class ValidTilawaUiExceptionRule extends AnalysisRule {
  ValidTilawaUiExceptionRule()
    : super(
        name: 'valid_tilawa_ui_exception',
        description: 'Requires every UI exception to be reviewed and tracked.',
      );

  static const code = LintCode(
    'valid_tilawa_ui_exception',
    'This UI Kit lint suppression is not reviewed.',
    correctionMessage:
        'Register this ID with a reason and tracking reference in '
        'component_policy.dart.',
    severity: DiagnosticSeverity.ERROR,
    uniqueName: 'TilawaLintCode.valid_tilawa_ui_exception',
  );

  @override
  DiagnosticCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    registry.addCompilationUnit(this, _Visitor(this, context));
  }
}

final class _Visitor extends SimpleAstVisitor<void> {
  _Visitor(this.rule, this.context);

  final ValidTilawaUiExceptionRule rule;
  final RuleContext context;

  @override
  void visitCompilationUnit(CompilationUnit node) {
    final path = context.currentUnit?.file.path;
    if (path == null || !isProductDartFile(path)) return;

    final ids = <String, List<Token>>{};
    Token? token = node.beginToken;
    while (token != null && token.type != TokenType.EOF) {
      Token? comment = token.precedingComments;
      while (comment != null) {
        final match = RegExp(
          r'tilawa-ui-exception:\s*([A-Z0-9-]+)',
        ).firstMatch(comment.lexeme);
        if (match != null) {
          ids.putIfAbsent(match.group(1)!, () => <Token>[]).add(comment);
        }
        comment = comment.next;
      }
      token = token.next;
    }

    for (final entry in ids.entries) {
      final matches = uiKitExceptions.where((item) => item.id == entry.key);
      final valid =
          matches.length == 1 &&
          path.replaceAll(r'\', '/').endsWith(matches.single.pathSuffix) &&
          matches.single.reason.trim().isNotEmpty &&
          matches.single.trackingReference.trim().isNotEmpty &&
          entry.value.length == 1;
      if (!valid) {
        for (final comment in entry.value) {
          rule.reportAtOffset(comment.offset, comment.length);
        }
      }
    }
  }
}
