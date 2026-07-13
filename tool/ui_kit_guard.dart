import 'dart:io';

const _forbiddenWidgets = <String, String>{
  'AppBar': 'TilawaAppBar or TilawaCatalogAppBar',
  'SliverAppBar': 'TilawaSliverAppBar',
};

// Existing debt is baselined per file. Counts may decrease, but never increase.
// Delete an entry when its count reaches zero.
const _baseline = <String, int>{
  'apps/tilawa/lib/core/telemetry/tilawa_sentry_feedback_form.dart': 2,
  'apps/tilawa/lib/features/auth/presentation/screens/email_auth_screens.dart':
      3,
  'apps/tilawa/lib/features/auth/presentation/screens/manage_devices_screen.dart':
      2,
  'apps/tilawa/lib/features/genui_assistant/presentation/screens/'
          'genui_assistant_screen.dart':
      1,
  'apps/tilawa/lib/router/app_router_config.dart': 1,
};

void main(List<String> arguments) {
  if (arguments.contains('--self-test')) {
    _runSelfTest();
    return;
  }

  final root = _workspaceRoot();
  final violations = <_Violation>[];
  final currentCounts = <String, int>{};

  for (final file in _productionDartFiles(root)) {
    final relativePath = _relativePath(root, file);
    final source = file.readAsStringSync();
    final matches = _findForbiddenConstructors(source);
    currentCounts[relativePath] = matches.length;

    final allowance = _baseline[relativePath] ?? 0;
    if (matches.length <= allowance) continue;

    for (final match in matches.skip(allowance)) {
      violations.add(
        _Violation(
          path: relativePath,
          line: _lineNumber(source, match.offset),
          widget: match.widget,
        ),
      );
    }
  }

  final staleBaseline = _baseline.entries.where(
    (entry) => (currentCounts[entry.key] ?? 0) < entry.value,
  );

  if (violations.isNotEmpty) {
    stderr.writeln('UI Kit guard failed: raw Flutter components found.');
    for (final violation in violations) {
      final replacement = _forbiddenWidgets[violation.widget];
      stderr.writeln(
        '${violation.path}:${violation.line}: ${violation.widget} is forbidden '
        'in product code; use $replacement.',
      );
    }
    stderr.writeln(
      'If no UI Kit component fits, add one at the correct Atomic Design '
      'level instead of bypassing the kit.',
    );
    exitCode = 1;
    return;
  }

  if (staleBaseline.isNotEmpty) {
    stderr.writeln('UI Kit guard failed: reduce the obsolete baseline:');
    for (final entry in staleBaseline) {
      stderr.writeln(
        '${entry.key}: ${entry.value} -> ${currentCounts[entry.key] ?? 0}',
      );
    }
    exitCode = 1;
    return;
  }

  stdout.writeln('UI Kit guard passed.');
}

Directory _workspaceRoot() {
  var directory = Directory.current.absolute;
  while (!File('${directory.path}/melos.yaml').existsSync() &&
      !File('${directory.path}/pubspec.yaml').existsSync()) {
    final parent = directory.parent;
    if (parent.path == directory.path) {
      throw StateError('Run this command from the Tilawa workspace.');
    }
    directory = parent;
  }
  return directory;
}

Iterable<File> _productionDartFiles(Directory root) sync* {
  final roots = <Directory>[
    Directory('${root.path}/apps/tilawa/lib'),
    Directory('${root.path}/packages'),
  ];

  for (final sourceRoot in roots.where((directory) => directory.existsSync())) {
    for (final entity in sourceRoot.listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final relativePath = _relativePath(root, entity);
      if (relativePath.startsWith('packages/ui_kit/') ||
          relativePath.startsWith('packages/flex_color_scheme/') ||
          !relativePath.contains('/lib/')) {
        continue;
      }
      yield entity;
    }
  }
}

List<_ConstructorMatch> _findForbiddenConstructors(String source) {
  final sanitized = _stripCommentsAndStrings(source);
  final pattern = RegExp(
    r'(?<![A-Za-z0-9_])(?:[A-Za-z_][A-Za-z0-9_]*\.)?'
    r'(AppBar|SliverAppBar)\s*\(',
  );
  return pattern
      .allMatches(sanitized)
      .map((match) => _ConstructorMatch(match.start, match.group(1)!))
      .toList();
}

String _stripCommentsAndStrings(String source) {
  final result = StringBuffer();
  var index = 0;
  while (index < source.length) {
    final remaining = source.substring(index);
    final delimiter = RegExp(
      "^(//|/\\*|'''|\"\"\"|'|\")",
    ).firstMatch(remaining)?.group(1);
    if (delimiter == null) {
      result.write(source[index]);
      index++;
      continue;
    }

    final endDelimiter = switch (delimiter) {
      '//' => '\n',
      '/*' => '*/',
      _ => delimiter,
    };
    final end = source.indexOf(endDelimiter, index + delimiter.length);
    final exclusiveEnd = end < 0 ? source.length : end + endDelimiter.length;
    final removed = source.substring(index, exclusiveEnd);
    result.write(removed.replaceAll(RegExp(r'[^\n]'), ' '));
    index = exclusiveEnd;
  }
  return result.toString();
}

int _lineNumber(String source, int offset) =>
    '\n'.allMatches(source.substring(0, offset)).length + 1;

String _relativePath(Directory root, File file) =>
    file.absolute.path.substring(root.path.length + 1);

void _runSelfTest() {
  const source = '''
// AppBar(title: ignored)
const label = 'SliverAppBar()';
final first = AppBar(title: title);
final second = material.SliverAppBar();
final allowed = TilawaAppBar(title: title);
''';
  final matches = _findForbiddenConstructors(source);
  if (matches.length != 2 ||
      matches[0].widget != 'AppBar' ||
      matches[1].widget != 'SliverAppBar') {
    stderr.writeln('UI Kit guard self-test failed.');
    exitCode = 1;
    return;
  }
  stdout.writeln('UI Kit guard self-test passed.');
}

final class _ConstructorMatch {
  const _ConstructorMatch(this.offset, this.widget);

  final int offset;
  final String widget;
}

final class _Violation {
  const _Violation({
    required this.path,
    required this.line,
    required this.widget,
  });

  final String path;
  final int line;
  final String widget;
}
