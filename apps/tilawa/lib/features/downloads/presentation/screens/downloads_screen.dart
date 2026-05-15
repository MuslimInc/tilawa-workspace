import 'dart:math' as math;

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
          TilawaButton(
            text: context.l10n.cancel,
            variant: TilawaButtonVariant.ghost,
            onPressed: () => Navigator.of(context).pop(),
          ),
          TilawaButton(
            text: context.l10n.deleteAll,
            variant: TilawaButtonVariant.danger,
            onPressed: () {
              Navigator.of(context).pop();
              context.read<DownloadsBloc>().add(const ClearAllDownloads());
            },
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
    return Stack(
      children: [
        const Positioned.fill(child: _DownloadsAmbientBackground()),
        Positioned.fill(
          child: switch (state.status) {
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
          },
        ),
      ],
    );
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

    final List<DownloadItem> downloads = downloadsByReciter.values
        .expand((narratives) => narratives.values)
        .expand((items) => items)
        .toList(growable: false);
    final int completedCount = downloads
        .where((download) => download.status == DownloadStatus.completed)
        .length;
    final int downloadingCount = downloads
        .where(
          (download) => download.status == DownloadStatus.downloading,
        )
        .length;

    return _DownloadsContentBounds(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _DownloadsSummaryCard(
            formattedSize: formattedSize,
            totalCount: downloads.length,
            completedCount: completedCount,
            downloadingCount: downloadingCount,
          ),
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
      ),
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

class _DownloadsContentBounds extends StatelessWidget {
  const _DownloadsContentBounds({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).tokens;

    return LayoutBuilder(
      builder: (context, constraints) {
        return Align(
          alignment: Alignment.topCenter,
          child: SizedBox(
            width: math.min(
              constraints.maxWidth,
              tokens.contentMaxWidthSettings,
            ),
            height: constraints.maxHeight,
            child: child,
          ),
        );
      },
    );
  }
}

class _DownloadsSummaryCard extends StatelessWidget {
  const _DownloadsSummaryCard({
    required this.formattedSize,
    required this.totalCount,
    required this.completedCount,
    required this.downloadingCount,
  });

  final String formattedSize;
  final int totalCount;
  final int completedCount;
  final int downloadingCount;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final tokens = theme.tokens;
    final colorScheme = theme.colorScheme;
    final TextTheme textTheme = theme.textTheme;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: tokens.spaceLarge,
        vertical: tokens.spaceMedium,
      ),
      child: Container(
        padding: EdgeInsets.all(tokens.spaceLarge),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(tokens.radiusLarge),
          border: Border.all(
            color: colorScheme.outlineVariant,
            width: tokens.borderWidthThin,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                TilawaIconBox(
                  icon: Icons.offline_pin_rounded,
                  iconColor: colorScheme.primary,
                  backgroundColor: colorScheme.surface.withValues(
                    alpha: tokens.opacityGlass,
                  ),
                ),
                SizedBox(width: tokens.spaceMedium),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.l10n.downloads,
                        style: textTheme.titleMedium?.copyWith(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: tokens.spaceExtraSmall),
                      Text(
                        context.l10n.storageUsed(formattedSize),
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: tokens.spaceLarge),
            Wrap(
              spacing: tokens.spaceSmall,
              runSpacing: tokens.spaceSmall,
              children: [
                _DownloadsMetricChip(
                  icon: Icons.library_music_rounded,
                  label: '$totalCount ${context.l10n.surahs}',
                ),
                _DownloadsMetricChip(
                  icon: Icons.check_circle_rounded,
                  label: '${context.l10n.completed}: $completedCount',
                ),
                if (downloadingCount > 0)
                  _DownloadsMetricChip(
                    icon: Icons.downloading_rounded,
                    label: '${context.l10n.downloading}: $downloadingCount',
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DownloadsMetricChip extends StatelessWidget {
  const _DownloadsMetricChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final tokens = theme.tokens;
    final colorScheme = theme.colorScheme;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: tokens.spaceMedium,
        vertical: tokens.spaceSmall,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: tokens.opacityGlass),
        borderRadius: BorderRadius.circular(tokens.radiusExtraLarge),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(
            alpha: tokens.opacitySubtle,
          ),
          width: tokens.borderWidthThin,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: tokens.iconSizeSmall, color: colorScheme.primary),
          SizedBox(width: tokens.spaceExtraSmall),
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _DownloadsAmbientBackground extends StatelessWidget {
  const _DownloadsAmbientBackground();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ExcludeSemantics(
      child: CustomPaint(
        painter: _DownloadsAmbientPainter(
          colorScheme: theme.colorScheme,
          tokens: theme.tokens,
        ),
      ),
    );
  }
}

class _DownloadsAmbientPainter extends CustomPainter {
  const _DownloadsAmbientPainter({
    required this.colorScheme,
    required this.tokens,
  });

  final ColorScheme colorScheme;
  final TilawaDesignTokens tokens;

  @override
  void paint(Canvas canvas, Size size) {
    final shortest = size.shortestSide;
    final topCenter = Offset(size.width * 0.18, size.height * 0.12);
    final lowerCenter = Offset(size.width * 0.82, size.height * 0.72);

    final primaryStroke = Paint()
      ..color = colorScheme.primary.withValues(
        alpha: tokens.opacitySubtle * 0.34,
      )
      ..style = PaintingStyle.stroke
      ..strokeWidth = tokens.borderWidthThin;
    final tertiaryStroke = Paint()
      ..color = colorScheme.tertiary.withValues(
        alpha: tokens.opacitySubtle * 0.28,
      )
      ..style = PaintingStyle.stroke
      ..strokeWidth = tokens.borderWidthThin;

    for (final factor in <double>[0.46, 0.7]) {
      canvas.drawArc(
        Rect.fromCircle(center: topCenter, radius: shortest * factor),
        -math.pi * 0.1,
        math.pi * 0.5,
        false,
        primaryStroke,
      );
    }

    for (final factor in <double>[0.48, 0.74]) {
      canvas.drawArc(
        Rect.fromCircle(center: lowerCenter, radius: shortest * factor),
        math.pi * 0.92,
        math.pi * 0.46,
        false,
        tertiaryStroke,
      );
    }
  }

  @override
  bool shouldRepaint(_DownloadsAmbientPainter oldDelegate) {
    return oldDelegate.colorScheme != colorScheme ||
        oldDelegate.tokens != tokens;
  }
}
