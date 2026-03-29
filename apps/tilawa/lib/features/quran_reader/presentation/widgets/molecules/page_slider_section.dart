import 'package:flutter/material.dart';
import 'package:tilawa/features/quran_reader/presentation/widgets/atoms/mushaf_slider.dart';
import 'package:tilawa/features/quran_reader/presentation/theme/quran_reader_theme.dart';

/// A complete slider Molecule with range labels (1-604).
class PageSliderSection extends StatelessWidget {
  const PageSliderSection({
    super.key,
    required this.totalPages,
    required this.sliderValue,
    required this.primaryColor,
    required this.textColor,
    required this.borderColor,
    required this.isDark,
    required this.onChanged,
    required this.onChangeStart,
    required this.onChangeEnd,
  });

  final int totalPages;
  final double sliderValue;
  final Color primaryColor;
  final Color textColor;
  final Color borderColor;
  final bool isDark;
  final ValueChanged<double> onChanged;
  final ValueChanged<double> onChangeStart;
  final ValueChanged<double> onChangeEnd;

  @override
  Widget build(BuildContext context) {
    final navTheme = PageNavigationBarTheme.of(context);
    final readerTheme = QuranReaderTheme.of(context);

    return Container(
      padding: navTheme.sliderSectionPadding,
      decoration: BoxDecoration(
        color: textColor.withValues(alpha: isDark ? 0.06 : 0.04),
        borderRadius: BorderRadius.circular(navTheme.sliderSectionRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.16 : 0.05),
            blurRadius: 12,
            spreadRadius: -8,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: SizedBox(
        height: navTheme.sliderStageHeight,
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Row(
            spacing: navTheme.sliderRangeGap,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$totalPages',
                style: readerTheme.sliderRangeTextStyle.copyWith(
                  color: textColor.withValues(alpha: 0.6),
                ),
              ),
              Expanded(
                child: Align(
                  alignment: Alignment.center,
                  child: SizedBox(
                    height: navTheme.sliderHeight,
                    child: MushafSlider(
                      value: sliderValue,
                      min: 1,
                      max: totalPages.toDouble(),
                      onChanged: onChanged,
                      onChangeStart: onChangeStart,
                      onChangeEnd: onChangeEnd,
                      activeColor: primaryColor,
                      isDark: isDark,
                    ),
                  ),
                ),
              ),
              Text(
                '1',
                style: readerTheme.sliderRangeTextStyle.copyWith(
                  color: textColor.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
