import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:gap/gap.dart';
import 'package:tilawa_core/config/language_config.dart';
import 'package:tilawa_ui/theme/color_scheme.dart';

import '../../features/localization/presentation/bloc/localization_bloc.dart';

class LanguageSwitcher extends StatelessWidget {
  const LanguageSwitcher({
    super.key,
    this.showText = true,
    this.textColor,
    this.iconColor,
    this.backgroundColor,
  });

  final bool showText;
  final Color? textColor;
  final Color? iconColor;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LocalizationBloc, LocalizationState>(
      builder: (context, state) {
        final Locale currentLocale = state.locale;

        return PopupMenuButton<Locale>(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
          offset: const Offset(0, 40),
          elevation: 4,
          onSelected: (Locale locale) {
            context.read<LocalizationBloc>().add(ChangeLanguage(locale));
          },
          itemBuilder: (BuildContext context) {
            return [
              _buildMenuItem(
                context,
                locale: const Locale(arabicLanguageCode),
                label: 'العربية',
                isSelected: currentLocale.languageCode == arabicLanguageCode,
              ),
              _buildMenuItem(
                context,
                locale: const Locale(englishLanguageCode),
                label: 'English',
                isSelected: currentLocale.languageCode == englishLanguageCode,
              ),
            ];
          },
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: backgroundColor ?? Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.1),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.language_rounded,
                  color: iconColor ?? Colors.white,
                  size: 20.sp,
                ),
                if (showText) ...[
                  Gap(8.w),
                  Text(
                    currentLocale.languageCode.toUpperCase(),
                    style: TextStyle(
                      color: textColor ?? Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14.sp,
                    ),
                  ),
                  Gap(4.w),
                  Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: (iconColor ?? Colors.white).withValues(alpha: 0.7),
                    size: 16.sp,
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  PopupMenuItem<Locale> _buildMenuItem(
    BuildContext context, {
    required Locale locale,
    required String label,
    required bool isSelected,
  }) {
    return PopupMenuItem<Locale>(
      value: locale,
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected
                    ? context.primaryColor
                    : context.colorScheme.onSurface,
              ),
            ),
          ),
          if (isSelected)
            Icon(Icons.check_rounded, color: context.primaryColor, size: 20.sp),
        ],
      ),
    );
  }
}
