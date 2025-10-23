import 'package:flutter/material.dart';
import 'package:muzakri/core/config/currency_config.dart';

/// Widget for displaying currency amounts consistently across the app
class CurrencyDisplay extends StatelessWidget {
  const CurrencyDisplay({
    super.key,
    required this.amount,
    this.style,
    this.textAlign,
    this.showSymbol = true,
    this.decimals,
  });

  /// The amount to display
  final double amount;

  /// Text style for the amount
  final TextStyle? style;

  /// Text alignment
  final TextAlign? textAlign;

  /// Whether to show the currency symbol
  final bool showSymbol;

  /// Number of decimal places (overrides default from config)
  final int? decimals;

  @override
  Widget build(BuildContext context) {
    final decimalPlaces = decimals ?? CurrencyConfig.decimalPlaces;
    final formattedAmount = amount.toStringAsFixed(decimalPlaces);

    if (!showSymbol) {
      return Text(formattedAmount, style: style, textAlign: textAlign);
    }

    return RichText(
      textAlign: textAlign ?? TextAlign.start,
      text: TextSpan(
        style: style,
        children: [
          TextSpan(text: formattedAmount),
          TextSpan(
            text: ' ${CurrencyConfig.currencySymbol}',
            style: style?.copyWith(
              fontWeight: FontWeight.w500,
              color: style?.color?.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }
}

/// Extension for easy currency formatting
extension CurrencyFormatting on double {
  /// Format as currency string
  String toCurrency({bool showSymbol = true, int? decimals}) {
    final decimalPlaces = decimals ?? CurrencyConfig.decimalPlaces;
    final formattedAmount = toStringAsFixed(decimalPlaces);

    if (!showSymbol) {
      return formattedAmount;
    }

    if (CurrencyConfig.symbolBeforeAmount) {
      return '${CurrencyConfig.currencySymbol} $formattedAmount';
    } else {
      return '$formattedAmount ${CurrencyConfig.currencySymbol}';
    }
  }
}
