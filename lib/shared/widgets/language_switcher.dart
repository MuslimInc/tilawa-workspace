import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/config/language_config.dart';
import '../../core/theme/color_scheme.dart';
import '../../features/localization/presentation/bloc/localization_bloc.dart';

class LanguageSwitcher extends StatelessWidget {
  const LanguageSwitcher({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LocalizationBloc, LocalizationState>(
      builder: (context, state) {
        final Locale currentLocale = state.locale;

        return PopupMenuButton<Locale>(
          icon: const Icon(Icons.language),
          onSelected: (Locale locale) {
            context.read<LocalizationBloc>().add(ChangeLanguage(locale));
          },
          itemBuilder: (BuildContext context) {
            return [
              PopupMenuItem<Locale>(
                value: Locale(LanguageConfig.defaultLanguageCode),
                child: Row(
                  children: [
                    Text(
                      'العربية',
                      style: TextStyle(
                        fontWeight:
                            currentLocale.languageCode ==
                                LanguageConfig.defaultLanguageCode
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                    if (currentLocale.languageCode ==
                        LanguageConfig.defaultLanguageCode)
                      Icon(Icons.check, color: context.primaryColor),
                  ],
                ),
              ),
              PopupMenuItem<Locale>(
                value: const Locale('en'),
                child: Row(
                  children: [
                    Text(
                      'English',
                      style: TextStyle(
                        fontWeight: currentLocale.languageCode == 'en'
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                    if (currentLocale.languageCode == 'en')
                      Icon(Icons.check, color: context.primaryColor),
                  ],
                ),
              ),
            ];
          },
        );
      },
    );
  }
}
