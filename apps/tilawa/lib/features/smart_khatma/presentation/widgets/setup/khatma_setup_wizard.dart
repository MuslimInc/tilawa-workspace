import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quran_qcf/quran_qcf.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../../domain/entities/khatma_plan.dart';
import '../../../domain/khatma_plan_boundaries.dart';
import '../../../smart_khatma_dependencies.dart';
import '../../bloc/khatma_plan_bloc.dart';
import '../../bloc/khatma_plan_event.dart';
import '../../bloc/khatma_plan_state.dart';

enum _KhatmaWizardStartOption {
  beginning,
  lastRead,
  juz,
}

enum _KhatmaBoundaryMode { surah, page }

class KhatmaSetupWizard extends StatefulWidget {
  const KhatmaSetupWizard({super.key});

  @override
  State<KhatmaSetupWizard> createState() => _KhatmaSetupWizardState();
}

class _KhatmaSetupWizardState extends State<KhatmaSetupWizard> {
  int _step = 0;
  bool _showAdvanced = false;
  _KhatmaWizardStartOption _startOption = _KhatmaWizardStartOption.beginning;
  int _selectedJuz = 1;
  int? _lastReadPage;
  _KhatmaBoundaryMode _boundaryMode = _KhatmaBoundaryMode.surah;
  int _startSurah = 1;
  int _startAyah = 1;
  int _endSurah = 114;
  int _endAyah = getVerseCount(114);
  int _durationDays = 30;
  final TextEditingController _startPageController = TextEditingController(
    text: '${KhatmaPlan.firstQuranPage}',
  );
  final TextEditingController _endPageController = TextEditingController(
    text: '${KhatmaPlan.lastQuranPage}',
  );

  @override
  void initState() {
    super.initState();
    unawaited(_loadLastReadPage());
  }

  @override
  void dispose() {
    _startPageController.dispose();
    _endPageController.dispose();
    super.dispose();
  }

  Future<void> _loadLastReadPage() async {
    try {
      final int page = await SmartKhatmaDependencies.currentQuranPage();
      if (!mounted) return;
      setState(() => _lastReadPage = page);
    } on Object {
      // Tests and early boot may lack QuranReaderRepository in getIt.
    }
  }

  int? get _startPage {
    if (_showAdvanced) {
      return switch (_boundaryMode) {
        _KhatmaBoundaryMode.surah => KhatmaPlanBoundaries.pageForSurahAyah(
          _startSurah,
          _startAyah,
        ),
        _KhatmaBoundaryMode.page => int.tryParse(_startPageController.text),
      };
    }
    return switch (_startOption) {
      _KhatmaWizardStartOption.beginning => KhatmaPlan.firstQuranPage,
      _KhatmaWizardStartOption.lastRead =>
        _lastReadPage ?? KhatmaPlan.firstQuranPage,
      _KhatmaWizardStartOption.juz => KhatmaPlanBoundaries.pageForJuz(
        _selectedJuz,
      ),
    };
  }

  int? get _targetPage {
    if (_showAdvanced) {
      return switch (_boundaryMode) {
        _KhatmaBoundaryMode.surah => KhatmaPlanBoundaries.pageForSurahAyah(
          _endSurah,
          _endAyah,
        ),
        _KhatmaBoundaryMode.page => int.tryParse(_endPageController.text),
      };
    }
    return KhatmaPlan.lastQuranPage;
  }

  bool get _hasValidBoundaries {
    final int? start = _startPage;
    final int? end = _targetPage;
    if (start == null || end == null) return false;
    if (_showAdvanced && _boundaryMode == _KhatmaBoundaryMode.surah) {
      return KhatmaPlanBoundaries.isOrderedSurahRange(
        startSurah: _startSurah,
        startAyah: _startAyah,
        endSurah: _endSurah,
        endAyah: _endAyah,
      );
    }
    return KhatmaPlanBoundaries.isValidPageRange(start, end);
  }

  int? get _totalPages {
    final int? start = _startPage;
    final int? end = _targetPage;
    if (start == null || end == null) return null;
    return end - start + 1;
  }

  int? get _dailyPages {
    final int? total = _totalPages;
    if (total == null || total <= 0) return null;
    return (total / _durationDays).ceil();
  }

  String _startOptionKey(_KhatmaWizardStartOption option, {int? juz}) {
    return switch (option) {
      _KhatmaWizardStartOption.beginning => 'beginning',
      _KhatmaWizardStartOption.lastRead => 'last_read',
      _KhatmaWizardStartOption.juz => 'juz:$juz',
    };
  }

  _KhatmaWizardStartOption _parseStartOption(String key) {
    if (key == 'beginning') return _KhatmaWizardStartOption.beginning;
    if (key == 'last_read') return _KhatmaWizardStartOption.lastRead;
    if (key.startsWith('juz:')) {
      _selectedJuz = int.tryParse(key.substring(4)) ?? 1;
      return _KhatmaWizardStartOption.juz;
    }
    return _KhatmaWizardStartOption.beginning;
  }

  void _requestPreview() {
    final int? start = _startPage;
    final int? end = _targetPage;
    if (start == null || end == null || !_hasValidBoundaries) return;
    context.read<KhatmaPlanBloc>().add(
      KhatmaPlanPreviewRequested(
        durationDays: _durationDays,
        startPage: start,
        targetPage: end,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;
    final bool isLoading = context.select<KhatmaPlanBloc, bool>(
      (bloc) => bloc.state is KhatmaPlanLoading,
    );

    return ListView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: EdgeInsetsDirectional.fromSTEB(
        theme.componentTokens.settingsGroup.groupHorizontalPadding,
        tokens.spaceSection,
        theme.componentTokens.settingsGroup.groupHorizontalPadding,
        tokens.spaceHuge,
      ),
      children: [
        if (_step == 0) ...[
          Text(
            context.l10n.khatmaWizardStartTitle,
            style: theme.textTheme.headlineSmall,
          ),
          SizedBox(height: tokens.spaceSmall),
          Text(
            context.l10n.khatmaWizardStartSubtitle,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: tokens.spaceLarge),
          TilawaDropdownField<String>(
            value: _startOptionKey(
              _startOption,
              juz: _selectedJuz,
            ),
            semanticLabel: context.l10n.khatmaWizardStartFromLabel,
            items: [
              TilawaDropdownItem(
                value: _startOptionKey(_KhatmaWizardStartOption.beginning),
                label: context.l10n.khatmaWizardBeginningOfMushaf,
              ),
              if (_lastReadPage != null)
                TilawaDropdownItem(
                  value: _startOptionKey(_KhatmaWizardStartOption.lastRead),
                  label: context.l10n.khatmaContinueFromPage(_lastReadPage!),
                )
              else
                TilawaDropdownItem(
                  value: _startOptionKey(_KhatmaWizardStartOption.lastRead),
                  label: context.l10n.lastRead,
                ),
              for (int juz = 1; juz <= 30; juz++)
                TilawaDropdownItem(
                  value: _startOptionKey(
                    _KhatmaWizardStartOption.juz,
                    juz: juz,
                  ),
                  label: context.l10n.khatmaWizardJuzOption(juz),
                ),
            ],
            onChanged: (value) => setState(() {
              _startOption = _parseStartOption(value);
            }),
          ),
          SizedBox(height: tokens.spaceMedium),
          TilawaButton(
            text: _showAdvanced
                ? context.l10n.khatmaWizardHideAdvanced
                : context.l10n.khatmaWizardAdvancedBoundaries,
            variant: TilawaButtonVariant.outline,
            onPressed: () => setState(() => _showAdvanced = !_showAdvanced),
          ),
          if (_showAdvanced) ...[
            SizedBox(height: tokens.spaceLarge),
            TilawaSegmentedControl<_KhatmaBoundaryMode>(
              segments: [
                TilawaSegment(
                  value: _KhatmaBoundaryMode.surah,
                  label: context.l10n.khatmaBoundaryBySurah,
                ),
                TilawaSegment(
                  value: _KhatmaBoundaryMode.page,
                  label: context.l10n.khatmaBoundaryByPage,
                ),
              ],
              selectedValue: _boundaryMode,
              onValueChanged: (selection) =>
                  setState(() => _boundaryMode = selection),
            ),
            SizedBox(height: tokens.spaceLarge),
            if (_boundaryMode == _KhatmaBoundaryMode.surah)
              _KhatmaSurahBoundaryFields(
                startSurah: _startSurah,
                startAyah: _startAyah,
                endSurah: _endSurah,
                endAyah: _endAyah,
                onStartChanged: (surah, ayah) => setState(() {
                  _startSurah = surah;
                  _startAyah = ayah;
                  if (_endSurah < surah ||
                      (_endSurah == surah && _endAyah < ayah)) {
                    _endSurah = surah;
                    _endAyah = ayah;
                  }
                }),
                onEndChanged: (surah, ayah) => setState(() {
                  _endSurah = surah;
                  _endAyah = ayah;
                }),
              )
            else
              _KhatmaPageBoundaryFields(
                startController: _startPageController,
                endController: _endPageController,
                onChanged: () => setState(() {}),
              ),
          ],
          SizedBox(height: tokens.spaceLarge),
          TilawaButton(
            text: context.l10n.khatmaWizardContinue,
            onPressed: _hasValidBoundaries
                ? () => setState(() => _step = 1)
                : null,
          ),
        ] else ...[
          Text(
            context.l10n.khatmaWizardDurationTitle,
            style: theme.textTheme.headlineSmall,
          ),
          SizedBox(height: tokens.spaceSmall),
          Text(
            context.l10n.khatmaWizardDurationSubtitle,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: tokens.spaceLarge),
          Text(
            context.l10n.khatmaWizardDurationLabel,
            style: theme.textTheme.titleMedium,
          ),
          SizedBox(height: tokens.spaceSmall),
          Row(
            children: [
              IconButton(
                onPressed: _durationDays > 1
                    ? () => setState(() => _durationDays--)
                    : null,
                icon: const Icon(Icons.remove_circle_outline),
              ),
              Expanded(
                child: TilawaCard(
                  surface: TilawaCardSurface.flat,
                  child: Padding(
                    padding: EdgeInsets.all(tokens.spaceMedium),
                    child: Text(
                      context.l10n.khatmaDurationDays(_durationDays),
                      style: theme.textTheme.titleMedium,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
              IconButton(
                onPressed: _durationDays < 365
                    ? () => setState(() => _durationDays++)
                    : null,
                icon: const Icon(Icons.add_circle_outline),
              ),
            ],
          ),
          SizedBox(height: tokens.spaceMedium),
          Wrap(
            spacing: tokens.spaceSmall,
            runSpacing: tokens.spaceSmall,
            children: [
              for (final days in const [7, 15, 30, 60])
                TilawaButton(
                  text: context.l10n.khatmaDurationDays(days),
                  variant: TilawaButtonVariant.outline,
                  onPressed: () => setState(() => _durationDays = days),
                ),
            ],
          ),
          if (_dailyPages != null) ...[
            SizedBox(height: tokens.spaceLarge),
            Text(
              context.l10n.khatmaWizardDailyAmountLabel,
              style: theme.textTheme.titleMedium,
            ),
            SizedBox(height: tokens.spaceSmall),
            Text(
              context.l10n.khatmaDailyPages(_dailyPages!),
              style: theme.textTheme.bodyLarge,
            ),
          ],
          SizedBox(height: tokens.spaceLarge),
          TilawaButton(
            text: context.l10n.khatmaWizardContinue,
            onPressed: isLoading || !_hasValidBoundaries
                ? null
                : _requestPreview,
          ),
          SizedBox(height: tokens.spaceSmall),
          TilawaButton(
            text: context.l10n.cancel,
            variant: TilawaButtonVariant.outline,
            onPressed: () => setState(() => _step = 0),
          ),
        ],
      ],
    );
  }
}

class _KhatmaSurahBoundaryFields extends StatelessWidget {
  const _KhatmaSurahBoundaryFields({
    required this.startSurah,
    required this.startAyah,
    required this.endSurah,
    required this.endAyah,
    required this.onStartChanged,
    required this.onEndChanged,
  });

  final int startSurah;
  final int startAyah;
  final int endSurah;
  final int endAyah;
  final void Function(int surah, int ayah) onStartChanged;
  final void Function(int surah, int ayah) onEndChanged;

  @override
  Widget build(BuildContext context) {
    final bool arabic = Localizations.localeOf(context).languageCode == 'ar';
    String name(int surah) =>
        arabic ? getSurahNameArabic(surah) : getSurahNameEnglish(surah);
    return Column(
      spacing: context.tokens.spaceMedium,
      children: [
        TilawaDropdownField<int>(
          value: startSurah,
          semanticLabel: context.l10n.khatmaStartSurah,
          items: [
            for (int surah = 1; surah <= 114; surah++)
              TilawaDropdownItem(
                value: surah,
                label: '$surah. ${name(surah)}',
              ),
          ],
          onChanged: (surah) => onStartChanged(surah, 1),
        ),
        TilawaDropdownField<int>(
          key: ValueKey<int>(startSurah),
          value: startAyah,
          semanticLabel: context.l10n.khatmaStartAyah,
          items: [
            for (int ayah = 1; ayah <= getVerseCount(startSurah); ayah++)
              TilawaDropdownItem(
                value: ayah,
                label: context.l10n.khatmaAyahNumber(ayah),
              ),
          ],
          onChanged: (ayah) => onStartChanged(startSurah, ayah),
        ),
        TilawaDropdownField<int>(
          key: ValueKey<int>(startSurah * 1000 + startAyah),
          value: endSurah,
          semanticLabel: context.l10n.khatmaEndSurah,
          items: [
            for (int surah = startSurah; surah <= 114; surah++)
              TilawaDropdownItem(
                value: surah,
                label: '$surah. ${name(surah)}',
              ),
          ],
          onChanged: (surah) => onEndChanged(surah, getVerseCount(surah)),
        ),
        TilawaDropdownField<int>(
          key: ValueKey<int>(endSurah),
          value: endAyah,
          semanticLabel: context.l10n.khatmaEndAyah,
          items: [
            for (
              int ayah = endSurah == startSurah ? startAyah : 1;
              ayah <= getVerseCount(endSurah);
              ayah++
            )
              TilawaDropdownItem(
                value: ayah,
                label: context.l10n.khatmaAyahNumber(ayah),
              ),
          ],
          onChanged: (ayah) => onEndChanged(endSurah, ayah),
        ),
      ],
    );
  }
}

class _KhatmaPageBoundaryFields extends StatelessWidget {
  const _KhatmaPageBoundaryFields({
    required this.startController,
    required this.endController,
    required this.onChanged,
  });

  final TextEditingController startController;
  final TextEditingController endController;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final EdgeInsets scrollPadding = EdgeInsets.only(
      bottom: context.keyboardInset + 24,
    );
    return Column(
      spacing: context.tokens.spaceMedium,
      children: [
        TilawaTextField(
          controller: startController,
          keyboardType: TextInputType.number,
          label: context.l10n.khatmaStartPageInput,
          helperText: context.l10n.khatmaPageBoundsHelp,
          scrollPadding: scrollPadding,
          onChanged: (_) => onChanged(),
        ),
        TilawaTextField(
          controller: endController,
          keyboardType: TextInputType.number,
          label: context.l10n.khatmaEndPageInput,
          helperText: context.l10n.khatmaPageBoundsHelp,
          scrollPadding: scrollPadding,
          onChanged: (_) => onChanged(),
        ),
      ],
    );
  }
}
