import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/market_config.dart';
import '../../domain/entities/user_profile.dart';
import '../failure_ui/quran_sessions_failure_ui.dart';
import '../blocs/profile_completion/profile_completion_bloc.dart';
import '../blocs/profile_completion/profile_completion_event.dart';
import '../blocs/profile_completion/profile_completion_state.dart';

/// Gate screen shown before booking when the student's profile is incomplete.
///
/// Collects: gender, date of birth, country, city.
/// On success, pops with [true] so the caller knows the profile is now
/// complete and can retry eligibility.
class ProfileCompletionScreen extends StatefulWidget {
  const ProfileCompletionScreen({super.key, required this.userId});

  final String userId;

  @override
  State<ProfileCompletionScreen> createState() =>
      _ProfileCompletionScreenState();
}

class _ProfileCompletionScreenState extends State<ProfileCompletionScreen> {
  @override
  void initState() {
    super.initState();
    context.read<ProfileCompletionBloc>().add(
      ProfileLoadRequested(userId: widget.userId),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('إكمال الملف الشخصي')),
      body: BlocConsumer<ProfileCompletionBloc, ProfileCompletionState>(
        listener: (context, state) {
          if (state is ProfileCompletionSaved) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('تم حفظ ملفك الشخصي بنجاح')),
            );
            Navigator.of(context).pop(true);
          }
          if (state is ProfileCompletionFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.failure.toLocalizedMessage(context)),
              ),
            );
          }
        },
        builder: (context, state) => switch (state) {
          ProfileCompletionInitial() ||
          ProfileCompletionLoading() => const Center(
            child: CircularProgressIndicator(),
          ),
          ProfileCompletionSaving() => const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 12),
                Text('جارٍ حفظ البيانات…'),
              ],
            ),
          ),
          ProfileCompletionSaved() => const SizedBox.shrink(),
          ProfileCompletionFailure(:final failure) => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(failure.toLocalizedMessage(context)),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () => context.read<ProfileCompletionBloc>().add(
                    ProfileLoadRequested(userId: widget.userId),
                  ),
                  child: const Text('إعادة المحاولة'),
                ),
              ],
            ),
          ),
          ProfileCompletionEditing(
            :final userId,
            :final availableMarkets,
            :final selectedGender,
            :final selectedDateOfBirth,
            :final selectedMarket,
            :final selectedCity,
            :final availableCities,
            :final canSubmit,
          ) =>
            SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Header ─────────────────────────────────────────────
                  Icon(
                    Icons.person_outline_rounded,
                    size: 64,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'أخبرنا عن نفسك',
                    style: Theme.of(context).textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'نحتاج إلى هذه المعلومات لمطابقتك مع المعلم المناسب '
                    'وعرض الأسعار الصحيحة لمنطقتك.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),

                  // ── Gender picker ──────────────────────────────────────
                  Text(
                    'الجنس',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  _GenderPicker(
                    selected: selectedGender,
                    onChanged: (g) => context.read<ProfileCompletionBloc>().add(
                      GenderSelected(g),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── Date of birth ──────────────────────────────────────
                  Text(
                    'تاريخ الميلاد',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  _DateOfBirthField(
                    selected: selectedDateOfBirth,
                    onChanged: (d) => context.read<ProfileCompletionBloc>().add(
                      DateOfBirthSet(d),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── Country picker ─────────────────────────────────────
                  Text(
                    'الدولة',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  _CountryPicker(
                    markets: availableMarkets,
                    selected: selectedMarket,
                    onChanged: (m) => context.read<ProfileCompletionBloc>().add(
                      CountrySelected(m),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── City picker ────────────────────────────────────────
                  Text(
                    'المدينة',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  _CityPicker(
                    cities: availableCities,
                    selected: selectedCity,
                    countrySelected: selectedMarket != null,
                    onChanged: (c) => context.read<ProfileCompletionBloc>().add(
                      CitySelected(c),
                    ),
                  ),
                  const SizedBox(height: 40),

                  // ── Submit ─────────────────────────────────────────────
                  FilledButton(
                    onPressed: canSubmit
                        ? () => context.read<ProfileCompletionBloc>().add(
                            ProfileSubmitted(userId: userId),
                          )
                        : null,
                    child: const Text('حفظ والمتابعة'),
                  ),
                ],
              ),
            ),
        },
      ),
    );
  }
}

// ── Gender picker ─────────────────────────────────────────────────────────────

class _GenderPicker extends StatelessWidget {
  const _GenderPicker({required this.selected, required this.onChanged});

  final UserGender? selected;
  final ValueChanged<UserGender> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _GenderOption(
            label: 'ذكر',
            icon: Icons.male_rounded,
            gender: UserGender.male,
            isSelected: selected == UserGender.male,
            onTap: () => onChanged(UserGender.male),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _GenderOption(
            label: 'أنثى',
            icon: Icons.female_rounded,
            gender: UserGender.female,
            isSelected: selected == UserGender.female,
            onTap: () => onChanged(UserGender.female),
          ),
        ),
      ],
    );
  }
}

class _GenderOption extends StatelessWidget {
  const _GenderOption({
    required this.label,
    required this.icon,
    required this.gender,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final UserGender gender;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      decoration: BoxDecoration(
        color: isSelected
            ? scheme.primaryContainer
            : scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? scheme.primary : Colors.transparent,
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            children: [
              Icon(
                icon,
                size: 32,
                color: isSelected ? scheme.primary : scheme.onSurfaceVariant,
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? scheme.primary : scheme.onSurfaceVariant,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Date of birth field ───────────────────────────────────────────────────────

class _DateOfBirthField extends StatelessWidget {
  const _DateOfBirthField({required this.selected, required this.onChanged});

  final DateTime? selected;
  final ValueChanged<DateTime> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dateFmt = DateFormat('d MMMM y', 'ar');

    return OutlinedButton.icon(
      icon: const Icon(Icons.calendar_today_outlined),
      label: Text(
        selected != null ? dateFmt.format(selected!) : 'اختر تاريخ الميلاد',
        style: TextStyle(
          color: selected != null ? scheme.onSurface : scheme.onSurfaceVariant,
        ),
      ),
      onPressed: () async {
        final now = DateTime.now();
        final picked = await showDatePicker(
          context: context,
          initialDate: selected ?? DateTime(now.year - 20, now.month, now.day),
          firstDate: DateTime(1930),
          lastDate: now,
          helpText: 'اختر تاريخ الميلاد',
        );
        if (picked != null) onChanged(picked);
      },
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.all(16),
        alignment: AlignmentDirectional.centerStart,
      ),
    );
  }
}

// ── Country picker ────────────────────────────────────────────────────────────

class _CountryPicker extends StatelessWidget {
  const _CountryPicker({
    required this.markets,
    required this.selected,
    required this.onChanged,
  });

  final List<MarketConfig> markets;
  final MarketConfig? selected;
  final ValueChanged<MarketConfig> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return DropdownButtonFormField<MarketConfig>(
      initialValue: selected,
      hint: Text(
        'اختر الدولة',
        style: TextStyle(color: scheme.onSurfaceVariant),
      ),
      decoration: InputDecoration(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      items: markets
          .where((m) => m.isEnabled)
          .map(
            (m) => DropdownMenuItem<MarketConfig>(
              value: m,
              child: Text(m.countryName),
            ),
          )
          .toList(),
      onChanged: (m) {
        if (m != null) onChanged(m);
      },
    );
  }
}

// ── City picker ───────────────────────────────────────────────────────────────

class _CityPicker extends StatelessWidget {
  const _CityPicker({
    required this.cities,
    required this.selected,
    required this.countrySelected,
    required this.onChanged,
  });

  final List<CityConfig> cities;
  final CityConfig? selected;
  final bool countrySelected;
  final ValueChanged<CityConfig> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return DropdownButtonFormField<CityConfig>(
      initialValue: selected,
      hint: Text(
        countrySelected ? 'اختر المدينة' : 'اختر الدولة أولاً',
        style: TextStyle(color: scheme.onSurfaceVariant),
      ),
      decoration: InputDecoration(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      items: cities
          .map(
            (c) => DropdownMenuItem<CityConfig>(
              value: c,
              child: Text(c.cityName),
            ),
          )
          .toList(),
      onChanged: countrySelected
          ? (c) {
              if (c != null) onChanged(c);
            }
          : null,
    );
  }
}
