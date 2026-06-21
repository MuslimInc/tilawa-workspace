import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../domain/entities/teacher_application.dart';
import '../../utils/phone_normalizer.dart';
import '../../utils/specialization_labels.dart';
import '../blocs/teacher_application/teacher_application_bloc.dart';
import '../blocs/teacher_application/teacher_application_event.dart';
import '../blocs/teacher_application/teacher_application_state.dart';
import '../failure_ui/quran_sessions_failure_ui.dart';
import '../widgets/quran_sessions_form_field_shell.dart';

/// Form screen for filling a teacher application (draft → pending).
///
/// Fields: phone, country code, contact method, teaching languages,
/// specializations, bio.
///
/// [onSubmitted] is called when the application reaches `pending` status.
class TeacherApplicationScreen extends StatefulWidget {
  const TeacherApplicationScreen({
    super.key,
    required this.userId,
    required this.onSubmitted,
  });

  final String userId;
  final VoidCallback onSubmitted;

  @override
  State<TeacherApplicationScreen> createState() =>
      _TeacherApplicationScreenState();
}

class _TeacherApplicationScreenState extends State<TeacherApplicationScreen> {
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _bioCtrl;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _phoneCtrl = TextEditingController();
    _bioCtrl = TextEditingController();
    context.read<TeacherApplicationBloc>().add(
      TeacherApplicationLoadRequested(userId: widget.userId),
    );
  }

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _bioCtrl.dispose();
    super.dispose();
  }

  void _syncControllers(TeacherApplicationEditing state) {
    if (!_initialized) {
      _initialized = true;
      // Seed from phoneRaw (what the user typed), not the normalized E.164 value.
      if (_phoneCtrl.text != state.phoneRaw) {
        _phoneCtrl.text = state.phoneRaw;
      }
      if (_bioCtrl.text != (state.application.bio ?? '')) {
        _bioCtrl.text = state.application.bio ?? '';
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('طلب تسجيل كمحفظ')),
      body: BlocConsumer<TeacherApplicationBloc, TeacherApplicationState>(
        listener: (context, state) {
          if (state is TeacherApplicationStatusLoaded &&
              state.application.isPending) {
            widget.onSubmitted();
          }
          if (state is TeacherApplicationFailureState) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.failure.toLocalizedMessage(context)),
              ),
            );
            // Restore the previous state so the user can correct input.
            context.read<TeacherApplicationBloc>()
            // ignore: invalid_use_of_visible_for_testing_member
            .emit(state.previousState);
          }
        },
        builder: (context, state) => switch (state) {
          TeacherApplicationInitial() ||
          TeacherApplicationLoading() => const Center(
            child: CircularProgressIndicator(),
          ),
          TeacherApplicationNotStarted(:final userId) => _NotStartedView(
            onStart: () => context.read<TeacherApplicationBloc>().add(
              TeacherApplicationStartRequested(userId: userId),
            ),
          ),
          TeacherApplicationSubmitting() => const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 12),
                Text('جارٍ إرسال الطلب…'),
              ],
            ),
          ),
          TeacherApplicationEditing() => _FormBody(
            state: state,
            phoneController: _phoneCtrl,
            bioController: _bioCtrl,
            onInit: _syncControllers,
          ),
          _ => const SizedBox.shrink(),
        },
      ),
    );
  }
}

// ── Not started view ──────────────────────────────────────────────────────────

class _NotStartedView extends StatelessWidget {
  const _NotStartedView({required this.onStart});

  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.menu_book_outlined,
            size: 80,
            color: scheme.primary,
          ),
          const SizedBox(height: 24),
          Text(
            'أصبح محفظًا على تلاوة',
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'انضم إلى نخبة المعلمين المعتمدين وساعد الطلاب في رحلتهم مع القرآن الكريم.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          TilawaButton(
            text: 'ابدأ طلب التسجيل',
            leadingIcon: const Icon(Icons.arrow_forward),
            onPressed: onStart,
            isFullWidth: true,
            size: TilawaButtonSize.large,
          ),
        ],
      ),
    );
  }
}

// ── Form body ─────────────────────────────────────────────────────────────────

class _FormBody extends StatelessWidget {
  const _FormBody({
    required this.state,
    required this.phoneController,
    required this.bioController,
    required this.onInit,
  });

  final TeacherApplicationEditing state;
  final TextEditingController phoneController;
  final TextEditingController bioController;
  final void Function(TeacherApplicationEditing) onInit;

  static const _availableLanguages = [
    ('ar', 'العربية'),
    ('en', 'الإنجليزية'),
    ('ur', 'الأردية'),
    ('fr', 'الفرنسية'),
    ('tr', 'التركية'),
    ('ms', 'الملايوية'),
  ];

  static const _availableSpecializations = [
    'tajweed',
    'recitation',
    'hifz',
    'review',
    'children',
    'qaida',
    'tafsir',
    'arabic',
  ];

  @override
  Widget build(BuildContext context) {
    onInit(state);
    final bloc = context.read<TeacherApplicationBloc>();
    final application = state.application;
    final countryCode = application.phoneCountryCode ?? 'EG';

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Phone ────────────────────────────────────────────────────────
          _SectionTitle('رقم الهاتف *'),
          const SizedBox(height: 4),
          Text(
            'مطلوب للتحقق من هويتك. يظهر للإدارة فقط.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          // Force LTR layout so the country picker stays on the left
          // and the phone digits read left-to-right regardless of locale.
          Directionality(
            textDirection: TextDirection.ltr,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 110,
                  child: _CountryCodePicker(
                    selected: countryCode,
                    onChanged: (code) => bloc.add(
                      TeacherApplicationPhoneCountryCodeChanged(code),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    textDirection: TextDirection.ltr,
                    style: Theme.of(context).textTheme.bodyLarge,
                    decoration: QuranSessionsFormFieldShell.decoration(
                      context,
                      hintText: PhoneNormalizer.hint(countryCode),
                      // visiblePhoneError is null until the user has
                      // touched the field or tapped submit.
                      errorText: state.visiblePhoneError,
                    ),
                    onChanged: (v) =>
                        bloc.add(TeacherApplicationPhoneChanged(v.trim())),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ── Contact method ───────────────────────────────────────────────
          _SectionTitle('طريقة التواصل المفضلة'),
          const SizedBox(height: 8),
          _ContactMethodPicker(
            selected: application.preferredContactMethod,
            onChanged: (m) =>
                bloc.add(TeacherApplicationContactMethodChanged(m)),
          ),
          const SizedBox(height: 24),

          // ── Teaching languages ───────────────────────────────────────────
          _SectionTitle('لغات التدريس * (اختر واحدة أو أكثر)'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _availableLanguages.map((entry) {
              final (code, label) = entry;
              final selected = application.teachingLanguages.contains(code);
              return TilawaSelectionPill(
                label: label,
                selected: selected,
                onTap: () => bloc.add(TeacherApplicationLanguageToggled(code)),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),

          // ── Specializations ──────────────────────────────────────────────
          _SectionTitle('التخصصات * (اختر واحداً أو أكثر)'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _availableSpecializations.map((code) {
              final selected = application.specializations.contains(code);
              return TilawaSelectionPill(
                label: SpecializationLabels.arabic(code),
                selected: selected,
                onTap: () =>
                    bloc.add(TeacherApplicationSpecializationToggled(code)),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),

          // ── Bio ──────────────────────────────────────────────────────────
          _SectionTitle('نبذة تعريفية *'),
          const SizedBox(height: 8),
          TextFormField(
            controller: bioController,
            minLines: 4,
            maxLines: 8,
            maxLength: 500,
            textAlignVertical: TextAlignVertical.top,
            style: Theme.of(context).textTheme.bodyLarge,
            decoration: QuranSessionsFormFieldShell.decoration(
              context,
              hintText: 'أخبر الطلاب عن خبرتك ومؤهلاتك وأسلوبك في التدريس…',
              alignLabelWithHint: true,
            ),
            onChanged: (v) => bloc.add(TeacherApplicationBioChanged(v)),
          ),
          const SizedBox(height: 32),

          // ── Submit ───────────────────────────────────────────────────────
          // Always dispatch so the BLoC can set submitAttempted=true
          // and reveal validation errors even before canSubmit is true.
          TilawaButton(
            text: 'إرسال الطلب للمراجعة',
            onPressed: () =>
                bloc.add(const TeacherApplicationSubmitRequested()),
            isFullWidth: true,
            size: TilawaButtonSize.large,
          ),
          const SizedBox(height: 12),
          if (!state.canSubmit)
            Text(
              'أكمل جميع الحقول المطلوبة (*) لتتمكن من الإرسال.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
        ],
      ),
    );
  }
}

// ── Country code picker ───────────────────────────────────────────────────────

class _CountryCodePicker extends StatelessWidget {
  const _CountryCodePicker({required this.selected, required this.onChanged});

  final String? selected;
  final ValueChanged<String> onChanged;

  static const _options = [
    ('SA', '🇸🇦 +966'),
    ('EG', '🇪🇬 +20'),
    ('AE', '🇦🇪 +971'),
    ('KW', '🇰🇼 +965'),
    ('QA', '🇶🇦 +974'),
    ('BH', '🇧🇭 +973'),
    ('OM', '🇴🇲 +968'),
    ('JO', '🇯🇴 +962'),
    ('GB', '🇬🇧 +44'),
    ('US', '🇺🇸 +1'),
    ('CA', '🇨🇦 +1'),
    ('PK', '🇵🇰 +92'),
    ('IN', '🇮🇳 +91'),
    ('MY', '🇲🇾 +60'),
    ('TR', '🇹🇷 +90'),
  ];

  @override
  Widget build(BuildContext context) {
    return TilawaDropdownField<String>(
      value: selected,
      semanticLabel: 'رمز الدولة',
      items: [
        for (final e in _options) TilawaDropdownItem(value: e.$1, label: e.$2),
      ],
      onChanged: onChanged,
    );
  }
}

// ── Contact method picker ─────────────────────────────────────────────────────

class _ContactMethodPicker extends StatelessWidget {
  const _ContactMethodPicker({required this.selected, required this.onChanged});

  final PreferredContactMethod? selected;
  final ValueChanged<PreferredContactMethod> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      children: PreferredContactMethod.values.map((m) {
        return TilawaSelectionPill(
          label: _label(m),
          selected: selected == m,
          onTap: () => onChanged(m),
        );
      }).toList(),
    );
  }

  String _label(PreferredContactMethod m) => switch (m) {
    PreferredContactMethod.whatsapp => 'واتساب',
    PreferredContactMethod.phone => 'هاتف',
    PreferredContactMethod.email => 'بريد إلكتروني',
  };
}

// ── Section title ─────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: Theme.of(context).textTheme.titleSmall?.copyWith(
      fontWeight: FontWeight.w600,
    ),
  );
}
