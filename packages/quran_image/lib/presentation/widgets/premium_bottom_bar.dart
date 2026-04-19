import 'package:flutter/material.dart';
import 'package:quran_image/presentation/mappers/app_message_mapper.dart';

import '../../../l10n/app_localizations.dart';
import '../../core/perf_logger.dart';
import '../../domain/domain.dart';

class PremiumBottomBar extends StatelessWidget {
  final PageState state;

  const PremiumBottomBar({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final sw = PerfLogger.startTimer();
    final size = MediaQuery.sizeOf(context);
    final l10n = AppLocalizations.of(context)!;
    final height = MediaQuery.sizeOf(context).height;

    final bottomBar = Container(
      margin: EdgeInsets.fromLTRB(
        size.width * 0.04,
        0,
        size.width * 0.04,
        size.height * 0.010,
      ),
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: height * 0.001),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF9F2),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: const Color(0xFFC5A358).withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          // Page Number
          _PageNumber(pageNumber: state.displayPage),
          const Spacer(),
          // Juz & Hizb
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Text(
              //   JuzMessage(state.juzNumber).localize(l10n),
              //   style: const TextStyle(
              //     fontSize: 12,
              //     fontWeight: FontWeight.bold,
              //     color: Color(0xFF5D4037),
              //   ),
              // ),
              Text(
                HizbMessage(state.hizbNumber).localize(l10n),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF5D4037),
                ),
              ),
            ],
          ),
        ],
      ),
    );
    PerfLogger.logElapsed(
      sw,
      widgetName: 'PremiumBottomBar',
      message: 'build displayPage=${state.displayPage}',
    );
    return bottomBar;
  }
}

class _PageNumber extends StatelessWidget {
  const _PageNumber({required this.pageNumber});

  final int pageNumber;

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.sizeOf(context).height;
    return Container(
      width: height * 0.05,
      height: height * 0.05,
      alignment: Alignment.center,
      padding: EdgeInsets.all(1),
      decoration: BoxDecoration(
        color: const Color(0xFFC5A358).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFC5A358)),
      ),
      child: Center(
        child: Text(
          pageNumber.toString(),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF5D4037),
          ),
        ),
      ),
    );
  }
}
