import 'dart:io';

/// Spec-Kit validator for specs/043-core-trust-and-reliability.
///
/// Evidence-first reconciliation validator (2026-07-12). Validates the exact
/// review ledger (K01–K59) and the exclusive theme disposition ledger, in
/// addition to artifact/traceability/wording checks.
void main() {
  final dir = Directory('specs/043-core-trust-and-reliability');
  if (!dir.existsSync()) {
    stderr.writeln('Specs directory not found!');
    exit(1);
  }
  final failures = <String>[];
  String read(String rel) => File('${dir.path}/$rel').readAsStringSync();

  // ---- 1. Required artifacts -------------------------------------------------
  const expectedFiles = [
    'spec.md',
    'plan.md',
    'tasks.md',
    'research.md',
    'research-coverage.md',
    'roadmap.md',
    'adr-offline-city-db.md',
    'review-ledger.csv',
    'theme-ledger.csv',
    'contracts/quran-integrity-manifest.md',
    'contracts/quran-validation-result.md',
    'contracts/prayer-diagnostics.md',
    'contracts/location-preference.md',
    'contracts/analytics-events.md',
    'contracts/feature-flags.md',
  ];
  for (final f in expectedFiles) {
    if (!File('${dir.path}/$f').existsSync())
      failures.add('Missing artifact: $f');
  }
  if (failures.isNotEmpty) _report(failures);

  final spec = read('spec.md');
  final tasks = read('tasks.md');
  final research = read('research.md');
  final coverage = read('research-coverage.md');

  // ---- 2. FR ↔ tasks traceability & task-id uniqueness -----------------------
  final frIds = RegExp(
    r'(FR-\d+[a-z]?)',
  ).allMatches(spec).map((m) => m.group(1)!).toSet();
  for (final fr in frIds) {
    if (!tasks.contains(fr))
      failures.add('Requirement $fr not referenced in tasks.md');
  }
  final taskIds = RegExp(
    r'\*\*(T-[ALQ]\d+[a-z]?)\*\*',
  ).allMatches(tasks).map((m) => m.group(1)!).toList();
  if (taskIds.length != taskIds.toSet().length)
    failures.add('Task IDs not unique in tasks.md');

  // ---- 3. Exact review ledger K01–K59 ---------------------------------------
  const validStatuses = {
    'mapped_043',
    'mapped_023',
    'mapped_041',
    'future_spec',
    'deferred',
    'rejected',
    'competitor_specific',
    'non_actionable',
    'extraction_uncertain',
  };
  final ledger = read('review-ledger.csv').trim().split('\n');
  final header = ledger.first.split(',');
  if (header[0] != 'review_id' || header[1] != 'coverage_status') {
    failures.add(
      'review-ledger.csv header must start review_id,coverage_status',
    );
  }
  final seen = <String>{};
  for (final line in ledger.skip(1)) {
    if (line.trim().isEmpty) continue;
    final cols = line.split(',');
    final id = cols[0].trim();
    final status = cols[1].trim();
    final m = RegExp(r'^K(\d{2})$').firstMatch(id);
    if (m == null) {
      failures.add('Ledger id not in K## form: "$id"');
      continue;
    }
    final n = int.parse(m.group(1)!);
    if (n < 1 || n > 59) failures.add('Ledger id out of range K01–K59: $id');
    if (!seen.add(id)) failures.add('Duplicate review id in ledger: $id');
    if (!validStatuses.contains(status))
      failures.add('Invalid coverage status for $id: "$status"');
  }
  for (var i = 1; i <= 59; i++) {
    final id = 'K${i.toString().padLeft(2, '0')}';
    if (!seen.contains(id)) failures.add('Missing review id in ledger: $id');
  }

  // ---- 4. Exclusive theme ledger (reconciles) -------------------------------
  const validDisp = {
    'spec_043',
    'spec_023',
    'spec_041',
    'future_spec',
    'deferred',
    'rejected',
    'competitor_specific',
    'non_actionable',
  };
  final themeLines = read('theme-ledger.csv').trim().split('\n').skip(1);
  final dispCounts = <String, int>{};
  var themeCount = 0;
  final themeSeen = <String>{};
  for (final line in themeLines) {
    if (line.trim().isEmpty) continue;
    final cols = line.split(',');
    final theme = cols[0].trim();
    final disp = cols[1].trim();
    if (!themeSeen.add(theme))
      failures.add('Duplicate theme in theme-ledger: $theme');
    if (!validDisp.contains(disp))
      failures.add('Invalid disposition for theme "$theme": "$disp"');
    dispCounts[disp] = (dispCounts[disp] ?? 0) + 1;
    themeCount++;
  }
  final reconciled = dispCounts.values.fold<int>(0, (a, b) => a + b);
  if (reconciled != themeCount) {
    failures.add(
      'Theme dispositions ($reconciled) do not reconcile to theme count ($themeCount)',
    );
  }

  // ---- 5. Research-backed requirements carry research ids --------------------
  for (final line
      in tasks
          .split('\n')
          .where(
            (l) =>
                l.trimLeft().startsWith('| FR-') ||
                l.trimLeft().startsWith('| GOV-'),
          )) {
    final hasResearch = RegExp(r'K\d{2}').hasMatch(line);
    final hasDash = line.contains('—');
    if (!hasResearch && !hasDash)
      failures.add('Traceability row lacks research id or "—": ${line.trim()}');
  }

  // ---- 6. Preventive labels + no confirmed defect without repo evidence ------
  if (!tasks.contains('PREV'))
    failures.add('No PREV labels in tasks.md matrix');
  // A DEF (confirmed MeMuslim defect) row must cite repository evidence.
  for (final line in tasks.split('\n').where((l) => l.contains('| DEF'))) {
    if (!RegExp(
      r'\.(dart|kt)|repo|Receiver|Scheduler|assets/',
    ).hasMatch(line)) {
      failures.add(
        'Confirmed-defect row without repository evidence: ${line.trim()}',
      );
    }
  }

  // ---- 7. Banned unsupported absolute/demand wording ------------------------
  const banned = [
    'overwhelmingly',
    'proves memuslim',
    'most common complaint',
    'users demand',
    'users strongly demand',
    'the biggest gap',
    'the most important missing feature',
    'vast majority of users',
  ];
  for (final e in {
    'spec.md': spec,
    'research.md': research,
    'roadmap.md': read('roadmap.md'),
    'research-coverage.md': coverage,
  }.entries) {
    for (final p in banned) {
      if (e.value.toLowerCase().contains(p))
        failures.add('Unsupported absolute wording "$p" in ${e.key}');
    }
  }
  // The extremes-only caveat must be present where demand could be over-claimed.
  if (!coverage.toLowerCase().contains('extremes-only')) {
    failures.add(
      'research-coverage.md must state the extremes-only sampling caveat',
    );
  }

  // ---- 8. Sibling specs & scoring model presence ----------------------------
  for (final sib in [
    'specs/023-smart-khatma-reading-plan',
    'specs/041-islamic-widget-suite',
  ]) {
    if (!Directory(sib).existsSync())
      failures.add('Referenced sibling spec missing: $sib');
  }
  if (!research.contains('Research Prioritization Model')) {
    failures.add('research.md missing "Research Prioritization Model" section');
  }

  // ---- 9. Regression guard for corrected repo facts -------------------------
  for (final e in {
    'spec.md': spec,
    'contracts/quran-integrity-manifest.md': read(
      'contracts/quran-integrity-manifest.md',
    ),
    'contracts/feature-flags.md': read('contracts/feature-flags.md'),
  }.entries) {
    for (final line in e.value.split('\n')) {
      final l = line.toLowerCase();
      final falsePremise =
          l.contains('quran.db') ||
          l.contains('assets/quran/') ||
          l.contains('sqlite database');
      final isCorrection =
          l.contains('no ') ||
          l.contains('not ') ||
          l.contains('nonexistent') ||
          l.contains('corrected');
      if (falsePremise && !isCorrection)
        failures.add('Live false-premise in ${e.key}: ${line.trim()}');
    }
  }

  if (!(coverage.contains('Fully covered') ||
      coverage.contains('Covered with documented exclusions') ||
      coverage.contains('Incomplete'))) {
    failures.add('research-coverage.md lacks an explicit coverage statement');
  }

  // ---- 10. Cross-spec contract split (semantic vs presentation) -------------
  String fencedJson(String path) {
    final f = File(path);
    if (!f.existsSync()) {
      failures.add('Missing contract file: $path');
      return '';
    }
    final m = RegExp(
      r'```json\s*([\s\S]*?)```',
    ).firstMatch(f.readAsStringSync());
    return m?.group(1) ?? '';
  }

  const semanticPath =
      'specs/023-smart-khatma-reading-plan/contracts/wird-progress-summary.md';
  const payloadPath =
      'specs/041-islamic-widget-suite/contracts/wird-progress-widget-payload.md';
  final semanticJson = fencedJson(semanticPath);
  final payloadJson = fencedJson(payloadPath);

  // 10a. Semantic summary MUST NOT carry presentation/localization fields (in its schema block).
  const bannedSemanticKeys = [
    'displayLabelAr',
    'displayLabelEn',
    'localizedTitle',
    'localizedSubtitle',
    'textDirection',
    'formattedAssignedAmount',
    'accessibilityLabel',
    'deepLink',
    'color',
  ];
  for (final k in bannedSemanticKeys) {
    if (semanticJson.contains('"$k"')) {
      failures.add(
        'Semantic summary (023) must not contain presentation field "$k"',
      );
    }
  }
  // 10b. Widget payload (041) MUST contain the display-specific fields.
  const requiredPayloadKeys = [
    'locale',
    'textDirection',
    'localizedTitle',
    'accessibilityLabel',
    'action',
    'expiresAt',
  ];
  for (final k in requiredPayloadKeys) {
    if (!payloadJson.contains('"$k"')) {
      failures.add('Widget payload (041) must contain display field "$k"');
    }
  }

  // ---- 11. No duplicate "Continue Listening" requirement (repo marks it shipped) ----
  const amend023 =
      'specs/023-smart-khatma-reading-plan/amendment-review-insights.md';
  final a023 = File(amend023).existsSync()
      ? File(amend023).readAsStringSync()
      : '';
  if (!a023.contains(
    'Integrate listening progress with the active daily Quran plan',
  )) {
    failures.add(
      '023-A1 must be reframed as "Integrate listening progress…", not a new Continue-Listening build',
    );
  }
  if (!(a023.contains('PARTIALLY IMPLEMENTED') ||
      a023.contains('ALREADY IMPLEMENTED'))) {
    failures.add(
      '023-A1 must state its implementation disposition (resume already exists)',
    );
  }
  // The recommended first slice must NOT re-recommend the already-shipped continue-listening.
  final roadmap = read('roadmap.md');
  final sliceIdx = roadmap.indexOf('Recommended First Implementation Slice');
  final sliceText = sliceIdx >= 0
      ? roadmap.substring(sliceIdx).toLowerCase()
      : '';
  if (sliceText.contains('continue listening on home')) {
    failures.add(
      'First slice must not recommend already-implemented "continue listening on home"',
    );
  }

  // ---- 12. Android-only widget scope not described as cross-platform --------
  const amend041 =
      'specs/041-islamic-widget-suite/amendment-wird-progress-widget.md';
  final a041 = File(amend041).existsSync()
      ? File(amend041).readAsStringSync()
      : '';
  if (!a041.contains('Phase 1') || !a041.toLowerCase().contains('android')) {
    failures.add('041 amendment must scope Phase 1 as Android');
  }
  for (final line in a041.split('\n')) {
    if (line.contains('iOS')) {
      final l = line.toLowerCase();
      final phased =
          l.contains('future') ||
          l.contains('phase 2') ||
          l.contains('child spec') ||
          l.contains('out of scope') ||
          l.contains('deferred') ||
          l.contains('not ') ||
          l.contains('no ios') ||
          l.contains('android-only') ||
          l.contains('android only') ||
          l.contains('foundation');
      if (!phased) {
        failures.add(
          '041 amendment mentions iOS without future/Phase-2/child-spec qualifier: ${line.trim()}',
        );
      }
    }
  }

  // ---- 13. Every scoring dimension classified -------------------------------
  for (final tag in ['NUMERICAL', 'METADATA', 'UNAVAILABLE', 'POLICY FLOOR']) {
    if (!research.contains(tag)) {
      failures.add('research.md scoring model missing dimension class "$tag"');
    }
  }

  _report(
    failures,
    dispCounts: dispCounts,
    themeCount: themeCount,
    reviewCount: seen.length,
  );
}

void _report(
  List<String> failures, {
  Map<String, int>? dispCounts,
  int? themeCount,
  int? reviewCount,
}) {
  if (failures.isEmpty) {
    print('SUCCESS: Spec 043 validation passed.');
    if (reviewCount != null)
      print(
        '  Review ledger: $reviewCount/59 reviews, each with exactly one coverage status.',
      );
    if (dispCounts != null && themeCount != null) {
      print('  Theme ledger: $themeCount themes; dispositions reconcile ->');
      final sorted = dispCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      for (final e in sorted) {
        print('    ${e.key.padRight(20)} ${e.value}');
      }
    }
    exit(0);
  }
  stderr.writeln(
    'FAILED: Spec 043 validation found ${failures.length} issue(s):',
  );
  for (final f in failures) {
    stderr.writeln('  - $f');
  }
  exit(1);
}
