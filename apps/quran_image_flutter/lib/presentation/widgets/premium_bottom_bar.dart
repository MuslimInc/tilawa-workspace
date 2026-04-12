import 'package:flutter/material.dart';
import '../../domain/domain.dart';

class PremiumBottomBar extends StatelessWidget {
  final PageState state;

  const PremiumBottomBar({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFBF4E4),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: const Color(0xFFC5A358).withValues(alpha: 0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Page Number
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFC5A358).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFC5A358)),
            ),
            child: Text(
              state.displayPage.toString(),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF5D4037),
              ),
            ),
          ),
          const Spacer(),
          // Juz & Hizb
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                state.juzTitle,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF5D4037),
                ),
              ),
              Text(
                state.hizbTitle,
                style: const TextStyle(
                  fontSize: 10,
                  color: Color(0xFFC5A358),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
