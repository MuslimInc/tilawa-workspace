import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';

import '../../../../core/entities/reciter_entity.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../router/app_router_config.dart';

class ReciterCard extends StatelessWidget {
  const ReciterCard({super.key, required this.reciter});

  final ReciterEntity reciter;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Container(
      margin: EdgeInsets.symmetric(vertical: 8.h, horizontal: 8.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.1),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20.r),
          onTap: () {
            ReciterDetailsRoute(
              reciterId: reciter.id.toString(),
              $extra: reciter,
            ).push(context);
          },
          child: Padding(
            padding: EdgeInsets.all(12.r),
            child: Row(
              children: [
                _buildAvatar(context),
                SizedBox(width: 14.w),
                Expanded(child: _buildInfo(context)),
                Container(
                  padding: EdgeInsets.all(8.r),
                  decoration: BoxDecoration(
                    color: theme.primaryColor.withValues(alpha: 0.05),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.chevron_right_rounded,
                    size:
                        20, // Use static size if possible for const, otherwise leave dynamic
                    color: Color(
                      0xB22196F3,
                    ), // Approximation or leave dynamic if theme dependent
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(BuildContext context) {
    return Container(
      width: 60.r,
      height: 60.r,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18.r),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).primaryColor.withValues(alpha: 0.9),
            Theme.of(context).primaryColor,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Center(
        child: Text(
          reciter.letter,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 26.sp,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }

  Widget _buildInfo(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          reciter.name,
          style: theme.textTheme.titleMedium?.copyWith(
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.3,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        SizedBox(height: 6.h),
        Row(
          children: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: theme.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.library_music_rounded,
                    size: 12,
                    color: Colors.blue, // Approximation or leave dynamic
                  ),
                  SizedBox(width: 4.w),
                  Text(
                    AppLocalizations.of(
                      context,
                    )!.recitationsAvailable(reciter.moshaf.length),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.primaryColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 11.sp,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (reciter.moshaf.isNotEmpty) ...[
          SizedBox(height: 6.h),
          Text(
            reciter.moshaf.first.name,
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: 11.sp,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }
}
