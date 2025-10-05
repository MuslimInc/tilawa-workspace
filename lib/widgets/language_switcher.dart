import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muzakri/bloc/localization/localization_bloc.dart';

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
                value: const Locale('ar'),
                child: Row(
                  children: [
                    Text(
                      'العربية',
                      style: TextStyle(
                        fontWeight: currentLocale.languageCode == 'ar'
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                    if (currentLocale.languageCode == 'ar')
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
