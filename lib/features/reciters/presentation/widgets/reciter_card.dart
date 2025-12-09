import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../../../router/app_router_config.dart';
import '../../../../shared/models/reciter_model.dart';

class ReciterCard extends StatelessWidget {
  const ReciterCard({super.key, required this.reciter});

  final Reciter reciter;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Container(
      margin: EdgeInsets.symmetric(vertical: 6.h, horizontal: 4.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16.r),
        // boxShadow removed
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.2),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16.r),
          onTap: () {
            ReciterDetailsRoute(
              reciter: reciter,
              reciterId: reciter.id.toString(),
            ).push(context);
          },
          child: Padding(
            padding: EdgeInsets.all(16.r),
            child: Row(
              children: [
                _buildAvatar(context),
                SizedBox(width: 16.w),
                Expanded(child: _buildInfo(context)),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16.sp,
                  color: theme.colorScheme.onSurfaceVariant,
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
      width: 56.r,
      height: 56.r,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).primaryColor.withValues(alpha: 0.8),
            Theme.of(context).primaryColor,
          ],
        ),
        // boxShadow removed
      ),
      child: Center(
        child: Text(
          reciter.letter,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 24.sp,
          ),
        ),
      ),
    );
  }

  Widget _buildInfo(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          reciter.name,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: 16.sp,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        SizedBox(height: 4.h),
        Row(
          children: [
            Icon(
              Icons.library_music_rounded,
              size: 14.sp,
              color: Theme.of(context).primaryColor,
            ),
            SizedBox(width: 4.w),
            Expanded(
              child: Text(
                AppLocalizations.of(
                  context,
                )!.recitationsAvailable(reciter.moshaf.length),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 12.sp,
                ),
              ),
            ),
          ],
        ),
        if (reciter.moshaf.isNotEmpty) ...[
          SizedBox(height: 2.h),
          Text(
            reciter.moshaf.first.name,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontSize: 11.sp,
              color: Theme.of(context).colorScheme.outline,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }
}
