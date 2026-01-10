import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../bloc/settings/quran_settings_bloc.dart';

class QuranPageTopBar extends StatelessWidget {
  const QuranPageTopBar({
    super.key,
    required this.surahNameEnglish,
    required this.juzNumber,
  });

  final String surahNameEnglish;
  final int juzNumber;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      margin: const EdgeInsets.only(top: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            surahNameEnglish,
            style: GoogleFonts.amiri(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: const Color(0xFFA1887F), // Brownish gray
            ),
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(
                  Icons.text_fields, // 'Aa' icon equivalent
                  color: Color(0xFFA1887F),
                  size: 20,
                ),
                onPressed: () => _showTextSettings(context),
                tooltip: 'Change Font Size',
              ),
              const SizedBox(width: 8),
              Text(
                'Part $juzNumber',
                style: GoogleFonts.amiri(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFFA1887F),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showTextSettings(BuildContext context) {
    final QuranSettingsBloc settingsBloc = context.read<QuranSettingsBloc>();
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFFFFFBF3),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (modalContext) {
        return BlocProvider.value(
          value: settingsBloc,
          child: BlocBuilder<QuranSettingsBloc, QuranSettingsState>(
            builder: (context, state) {
              return Container(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Text Size',
                      style: GoogleFonts.amiri(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.brown,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Icon(
                          Icons.text_fields,
                          size: 16,
                          color: Colors.brown,
                        ),
                        Expanded(
                          child: Slider(
                            value: state.settings.fontSize,
                            min: 20.0,
                            max: 60.0,
                            divisions: 8, // Steps of 5
                            activeColor: Colors.amber[900],
                            inactiveColor: Colors.brown.withValues(alpha: 0.2),
                            onChanged: (value) {
                              settingsBloc.add(
                                QuranSettingsEvent.updateFontSize(value),
                              );
                            },
                          ),
                        ),
                        const Icon(
                          Icons.text_fields,
                          size: 32,
                          color: Colors.brown,
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}
