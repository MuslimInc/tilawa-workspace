import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa/core/logging/app_logger.dart';
import 'package:tilawa/core/utils/file_size_formatter.dart';
import 'package:tilawa/core/utils/toast_utils.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../../../shared/widgets/quran_player_widget.dart';
import '../../../../shared/widgets/tilawa_back_button.dart';
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

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);

    // Load downloads when the screen is first displayed
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDownloads();
    });
  }

  @override
  void dispose() {
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
    return BlocListener<DownloadsBloc, DownloadsState>(
      listenWhen: (DownloadsState previous, DownloadsState current) =>
          current.uiNotificationSeq != previous.uiNotificationSeq &&
          current.uiNotification != null,
      listener: (BuildContext context, DownloadsState state) {
        final DownloadsStatus status = state.uiNotification!;
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
        context.read<DownloadsBloc>().add(const ClearDownloadsUiNotification());
      },
      child: Scaffold(
        appBar: AppBar(
          leading: context.canPop() ? const TilawaBackButton() : null,
          title: Text(context.l10n.downloads),
          actions: [
            TilawaIconActionButton(
              icon: Icons.refresh_rounded,
              onTap: _loadDownloads,
            ),
            SizedBox(width: 8),
            TilawaIconActionButton(
              icon: Icons.delete_sweep_rounded,
              onTap: () => _showClearAllDialog(context),
            ),
            SizedBox(width: 8),
          ],
        ),
        body: Stack(
          children: [
            BlocBuilder<DownloadsBloc, DownloadsState>(
              builder: (context, state) {
                return _DownloadsBody(state: state);
              },
            ),
            const Positioned.fill(child: QuranPlayerWidget()),
          ],
        ),
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
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
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
      DownloadsStateStatus.initial ||
      DownloadsStateStatus.loading => const TilawaLoadingIndicator(),
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
      child: TilawaIllustratedState(
        visual: const TilawaStateVisual(
          icon: Icons.cloud_off_rounded,
          tone: TilawaStateVisualTone.error,
        ),
        title: message,
        semanticLabel: message,
        primaryAction: TilawaButton(
          text: context.l10n.retry,
          variant: TilawaButtonVariant.secondary,
          leadingIcon: const Icon(Icons.refresh_rounded),
          onPressed: () {
            context.read<DownloadsBloc>().add(const LoadDownloads());
          },
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
    return TilawaIllustratedState(
      visual: const TilawaStateVisual(
        icon: Icons.offline_pin_rounded,
        tone: TilawaStateVisualTone.tertiary,
      ),
      title: context.l10n.noDownloadsYet,
      subtitle: context.l10n.downloadSurahsOffline,
      semanticLabel: context.l10n.noDownloadsYet,
      primaryAction: TilawaButton(
        text: context.l10n.reciters,
        leadingIcon: const Icon(Icons.record_voice_over_rounded),
        onPressed: () => context.go('/'),
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
    final tokens = theme.tokens;
    final colorScheme = theme.colorScheme;
    final TextTheme textTheme = theme.textTheme;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: tokens.spaceLarge,
        vertical: tokens.spaceSmall,
      ),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: tokens.spaceLarge,
          vertical: tokens.spaceMedium,
        ),
        decoration: BoxDecoration(
          color: colorScheme.primaryContainer.withValues(alpha: 0.46),
          borderRadius: BorderRadius.circular(tokens.radiusMedium),
          border: Border.all(
            color: colorScheme.primary.withValues(alpha: tokens.opacitySubtle),
            width: tokens.borderWidthThin,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.sd_storage_rounded,
              size: tokens.iconSizeMedium,
              color: colorScheme.primary,
            ),
            SizedBox(width: tokens.spaceSmall),
            Text(
              context.l10n.storageUsed(formattedSize),
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
