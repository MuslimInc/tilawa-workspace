import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa/core/utils/file_size_formatter.dart';
import 'package:tilawa/core/utils/toast_utils.dart';

import 'package:tilawa/core/logging/app_logger.dart';
import '../../../../shared/widgets/bottom_player_widget.dart';
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
        error: (s) {
          final String msg =
              (s.message.contains('No internet') ||
                  s.message.contains('internet'))
              ? context.l10n.networkError
              : s.message;
          ToastUtils.showToast(msg: msg);
        },
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
      appBar: AppBar(
        title: Text(context.l10n.downloads),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadDownloads,
            tooltip: context.l10n.refreshDownloads,
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep_rounded),
            onPressed: () => _showClearAllDialog(context),
            tooltip: context.l10n.deleteAll,
          ),
        ],
      ),
      body: Stack(
        children: [
          BlocBuilder<DownloadsBloc, DownloadsState>(
            builder: (context, state) {
              return _DownloadsBody(state: state);
            },
          ),
          const Positioned.fill(child: BottomPlayerWidget()),
        ],
      ),
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

class _DownloadsBody extends StatelessWidget {
  const _DownloadsBody({required this.state});

  final DownloadsState state;

  @override
  Widget build(BuildContext context) {
    return switch (state.status) {
      DownloadsStateStatus.initial || DownloadsStateStatus.loading =>
        const Center(child: CircularProgressIndicator()),
      DownloadsStateStatus.loaded => _DownloadsList(
        downloadsByReciter: state.downloads,
        formattedSize: FileSizeFormatter.formatBytes(
          context,
          state.totalDownloadsSize,
        ),
      ),
      DownloadsStateStatus.error => _ErrorView(
        message: state.errorMessage ?? context.l10n.error,
      ),
    };
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
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
}

class _DownloadsList extends StatelessWidget {
  const _DownloadsList({
    required this.downloadsByReciter,
    required this.formattedSize,
  });

  final Map<String, Map<String, List<DownloadItem>>> downloadsByReciter;
  final String formattedSize;

  @override
  Widget build(BuildContext context) {
    if (downloadsByReciter.isEmpty) {
      return const _EmptyDownloadsView();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _DownloadsSizeWidget(formattedSize: formattedSize),
        Expanded(
          child: ListView(
            padding: EdgeInsets.only(bottom: 120),
            children: [
              for (int i = 0; i < downloadsByReciter.length; i++)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: ReciterDownloadsSection(
                    reciterName: downloadsByReciter.keys.elementAt(i),
                    downloadsByNarrative: downloadsByReciter.values.elementAt(
                      i,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _EmptyDownloadsView extends StatelessWidget {
  const _EmptyDownloadsView();

  @override
  Widget build(BuildContext context) {
    return Center(
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
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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
    );
  }
}

class _DownloadsSizeWidget extends StatelessWidget {
  const _DownloadsSizeWidget({required this.formattedSize});

  final String formattedSize;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TextTheme textTheme = theme.textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: theme.primaryColor.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.primaryColor.withValues(alpha: 0.1)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.sd_storage_rounded, size: 20, color: theme.primaryColor),
            const SizedBox(width: 8),
            Text(
              context.l10n.storageUsed(formattedSize),
              style: textTheme.bodyMedium?.copyWith(
                color: theme.textTheme.bodyMedium?.color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
