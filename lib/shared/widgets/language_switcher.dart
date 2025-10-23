import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muzakri/core/config/language_config.dart';
import 'package:muzakri/features/localization/presentation/bloc/localization_bloc.dart';

class LanguageSwitcher extends StatelessWidget {
  const LanguageSwitcher({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LocalizationBloc, LocalizationState>(
      builder: (context, state) {
        final currentLocale = state.locale;

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
                      const Icon(Icons.check, color: Colors.blue),
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
                      const Icon(Icons.check, color: Colors.blue),
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
