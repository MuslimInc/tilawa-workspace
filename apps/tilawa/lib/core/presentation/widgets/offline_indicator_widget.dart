import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa_core/presentation/bloc/internet_status/internet_status_bloc.dart';
import 'package:tilawa_core/presentation/bloc/internet_status/internet_status_state.dart';

class OfflineIndicatorWidget extends StatelessWidget {
  const OfflineIndicatorWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<InternetStatusBloc, InternetStatusState>(
      builder: (context, state) {
        if (state.status == InternetStatus.connected) {
          return const SizedBox.shrink();
        }

        return Container(
          width: double.infinity,
          color: Colors.red,
          padding: EdgeInsets.symmetric(vertical: 4.h),
          child: Text(
            context.l10n.noInternetConnection,
            style: TextStyle(color: Colors.white, fontSize: 12.sp),
            textAlign: TextAlign.center,
          ),
        );
      },
    );
  }
}
