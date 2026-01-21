import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa/core/utils/toast_utils.dart';
import 'package:tilawa_core/entities/reciter_entity.dart';

import '../../../../features/surah/domain/entities/surah_entity.dart';
import '../bloc/reciter_download_bloc.dart';

class DownloadAllButton extends StatelessWidget {
  const DownloadAllButton({
    super.key,
    required this.reciter,
    required this.surahs,
  });
  final ReciterEntity reciter;
  final List<SurahEntity> surahs;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 0.0),
      child: BlocConsumer<ReciterDownloadBloc, ReciterDownloadState>(
        listenWhen: (previous, current) => current.shouldShowError(previous),
        listener: (context, state) {
          if (state.isNetworkError) {
            ToastUtils.showToast(msg: context.l10n.networkError);
          }
        },
        builder: (context, state) {
          final bool isDownloading = state.isDownloadingAll;
          final double progress = state.progress;
          final bool isAllDownloaded = state.isAllDownloaded;

          if (isAllDownloaded) {
            return UnconstrainedBox(
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 16.w),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(
                    color: Theme.of(
                      context,
                    ).primaryColor.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.check_circle_rounded,
                      color: Theme.of(context).primaryColor,
                      size: 16.sp,
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      context.l10n.allDownloaded,
                      style: TextStyle(
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 12.sp,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return UnconstrainedBox(
            child: InkWell(
              key: const Key('reciter_details_download_all_button'),
              onTap: () {
                if (state.isPending) return;
                if (isDownloading) {
                  context.read<ReciterDownloadBloc>().add(
                    CancelReciterDownloadAll(reciterName: reciter.name),
                  );
                } else {
                  context.read<ReciterDownloadBloc>().add(
                    StartReciterDownloadAll(reciter: reciter, surahs: surahs),
                  );
                }
              },
              borderRadius: BorderRadius.circular(24.r),
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 24.w),
                decoration: BoxDecoration(
                  color: isDownloading
                      ? Theme.of(context).primaryColor.withValues(alpha: 0.1)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(24.r),
                  border: Border.all(
                    color: isDownloading
                        ? Theme.of(context).primaryColor
                        : Theme.of(context).dividerColor,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isDownloading)
                      SizedBox(
                        width: 14.w,
                        height: 14.w,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          value: progress,
                          color: Theme.of(context).primaryColor,
                        ),
                      )
                    else
                      Icon(
                        Icons.cloud_download_outlined,
                        color: Theme.of(context).textTheme.bodyMedium?.color,
                        size: 18.sp,
                      ),
                    SizedBox(width: 8.w),
                    Text(
                      isDownloading
                          ? context.l10n.pauseProgressWithCount(
                              (progress * 100).toInt(),
                              state.downloadedCount,
                              state.totalCount,
                            )
                          : (progress > 0 && progress < 1.0)
                          ? context.l10n.completeDownloadingWithCount(
                              state.downloadedCount,
                              state.totalCount,
                            )
                          : context.l10n.downloadAllWithCount(
                              state.downloadedCount,
                              state.totalCount,
                            ),
                      style: TextStyle(
                        color: Theme.of(context).textTheme.bodyMedium?.color,
                        fontWeight: FontWeight.w500,
                        fontSize: 13.sp,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
