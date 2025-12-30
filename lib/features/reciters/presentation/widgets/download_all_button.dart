import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import '../../../../core/entities/reciter_entity.dart';
import '../../../../core/extensions.dart';
import '../../../../core/utils/toast_utils.dart';
import '../bloc/reciter_details_bloc.dart';
import '../bloc/reciter_download_bloc.dart';

class DownloadAllButton extends StatelessWidget {
  const DownloadAllButton({
    super.key,
    required this.reciter,
    required this.parentState,
  });
  final ReciterEntity reciter;
  final ReciterDetailsState parentState;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: BlocBuilder<ReciterDownloadBloc, ReciterDownloadState>(
        builder: (context, state) {
          final bool isDownloading = state.isDownloadingAll;
          final double progress = state.progress;

          return SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                if (isDownloading) {
                  context.read<ReciterDownloadBloc>().add(
                    CancelReciterDownloadAll(reciterName: reciter.name),
                  );
                } else {
                  context.read<ReciterDownloadBloc>().add(
                    StartReciterDownloadAll(
                      reciter: reciter,
                      surahs: parentState.surahList,
                    ),
                  );
                  ToastUtils.showToast(msg: context.l10n.downloadingAllSurahs);
                }
              },
              icon: isDownloading
                  ? SizedBox(
                      width: 20.w,
                      height: 20.w,
                      child: const Icon(
                        Icons.pause_rounded,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.download_rounded, color: Colors.white),
              label: Text(
                isDownloading
                    ? '${context.l10n.pause} ${(progress * 100).toInt()}%'
                    : (progress > 0 && progress < 1.0)
                    ? context.l10n.completeDownloading
                    : context.l10n.downloadAll,
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 16.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.r),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
