import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../bloc/localization_bloc.dart';

/// Segmented Arabic / English control wired to [LocalizationBloc].
class AppLanguageSwitcher extends StatelessWidget {
  const AppLanguageSwitcher({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LocalizationBloc, LocalizationState>(
      builder: (context, state) {
        return TilawaLanguageSwitcher(
          compact: compact,
          currentLanguage: state.locale.languageCode,
          languages: const <String>['ar', 'en'],
          getLanguageName: (String code) =>
              code == 'ar' ? 'العربية' : 'English',
          onLanguageChanged: (String code) {
            context.read<LocalizationBloc>().add(ChangeLanguage(Locale(code)));
          },
        );
      },
    );
  }
}
