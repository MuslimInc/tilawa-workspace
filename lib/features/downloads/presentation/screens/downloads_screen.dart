import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';

import '../../../../core/extensions.dart';
import '../../../../core/utils/file_size_formatter.dart';
import '../../../../core/utils/toast_utils.dart';
import '../../../../main.dart';
import '../../domain/entities/download_item.dart';
import '../bloc/downloads_bloc.dart';
import '../bloc/downloads_status.dart';
import '../widgets/reciter_downloads_section.dart';

class DownloadsScreen extends StatefulWidget {
  const DownloadsScreen({super.key});

  @override
  State<DownloadsScreen> createState() => _DownloadsScreenState();
}

class _DownloadsScreenState extends State<DownloadsScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final ScrollController _scrollController = ScrollController();
  StreamSubscription<DownloadsStatus>? _statusSubscription;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);

    // Listen to status events
    _statusSubscription = context.read<DownloadsBloc>().statusStream.listen((
      status,
    ) {
      status.mapOrNull(
        error: (s) => ToastUtils.showToast(msg: s.message),
        premiumRequired: (s) => ToastUtils.showToast(msg: s.message),
        playbackInitiated: (s) => ToastUtils.showToast(msg: s.message),
      );
    });

    // Load downloads when the screen is first displayed
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDownloads();
    });
  }

  @override
  void dispose() {
    _statusSubscription?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reload downloads each time the screen becomes visible
    // This happens when user switches to downloads tab from bottom navigation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDownloads();
    });
  }

  void _loadDownloads() {
    // Always load downloads - no conditions
    logger.d('DownloadsScreen: Loading downloads...');
    context.read<DownloadsBloc>().add(const LoadDownloads());
  }

  void _onScroll() {
    // Handle scroll events if needed
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    return Scaffold(
      body: BlocBuilder<DownloadsBloc, DownloadsState>(
        builder: (context, state) {
          return CustomScrollView(
            slivers: [
              _buildAppBar(context, state),
              _buildBody(context, state),
              // Add some bottom padding for floating action buttons or player
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          );
        },
      ),
    );
  }

  SliverAppBar _buildAppBar(BuildContext context, DownloadsState state) {
    final int totalBytes = state.totalDownloadsSize;
    final String formattedSize = FileSizeFormatter.formatBytes(totalBytes);
    final ThemeData theme = Theme.of(context);
    final TextTheme textTheme = theme.textTheme;

    return SliverAppBar(
      expandedHeight: 120.0,
      floating: true,
      pinned: true,
      title: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(context.l10n.downloads),
          if (state.status == DownloadsStateStatus.loaded &&
              state.downloads.isNotEmpty)
            Text(
              context.l10n.storageUsed(formattedSize),
              style: TextStyle(
                color: textTheme.bodySmall?.color,
                fontSize: 12.sp,
                fontWeight: FontWeight.normal,
              ),
            ),
        ],
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                theme.primaryColor.withValues(alpha: 0.1),
                theme.scaffoldBackgroundColor,
              ],
            ),
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh_rounded),
          onPressed: _loadDownloads,
          tooltip: context.l10n.refreshDownloads,
        ),
        IconButton(
          icon: const Icon(Icons.delete_sweep_rounded, color: Colors.redAccent),
          onPressed: () => _showClearAllDialog(context),
          tooltip: context.l10n.deleteAll,
        ),
      ],
    );
  }

  Widget _buildBody(BuildContext context, DownloadsState state) {
    switch (state.status) {
      case DownloadsStateStatus.initial:
      case DownloadsStateStatus.loading:
        return const SliverFillRemaining(
          child: Center(child: CircularProgressIndicator()),
        );
      case DownloadsStateStatus.loaded:
        return _buildDownloadsList(context, state.downloads);
      case DownloadsStateStatus.error:
        return _buildError(context, state.errorMessage ?? context.l10n.error);
    }
  }

  Widget _buildError(BuildContext context, String message) {
    return SliverFillRemaining(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: const TextStyle(fontSize: 16, color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                context.read<DownloadsBloc>().add(const LoadDownloads());
              },
              icon: const Icon(Icons.refresh),
              label: Text(context.l10n.retry),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDownloadsList(
    BuildContext context,
    Map<String, Map<String, List<DownloadItem>>> downloadsByReciter,
  ) {
    if (downloadsByReciter.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.download_done_rounded,
                  size: 64,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                context.l10n.noDownloadsYet,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                context.l10n.downloadSurahsOffline,
                style: TextStyle(
                  fontSize: 16,
                  color: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        final String reciterName = downloadsByReciter.keys.elementAt(index);
        final Map<String, List<DownloadItem>> narrativeDownloads =
            downloadsByReciter[reciterName] ?? {};

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ReciterDownloadsSection(
            reciterName: reciterName,
            downloadsByNarrative: narrativeDownloads,
          ),
        );
      }, childCount: downloadsByReciter.length),
    );
  }

  void _showClearAllDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.clearAllDownloads),
        content: Text(context.l10n.clearAllDownloadsMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(context.l10n.cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.read<DownloadsBloc>().add(const ClearAllDownloads());
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(context.l10n.deleteAll),
          ),
        ],
      ),
    );
  }
}
