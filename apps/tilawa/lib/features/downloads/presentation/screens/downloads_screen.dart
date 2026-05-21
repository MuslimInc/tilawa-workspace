import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa/core/logging/app_logger.dart';
import 'package:tilawa/core/utils/file_size_formatter.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../domain/entities/download_item.dart';
import '../bloc/downloads_bloc.dart';
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
        context.read<DownloadsBloc>().add(const ClearDownloadsUiNotification());
      },
      child: Scaffold(
        appBar: TilawaAppBar(
          titleWidget: BlocBuilder<DownloadsBloc, DownloadsState>(
            buildWhen: (previous, current) =>
                previous.totalDownloadsSize != current.totalDownloadsSize,
            builder: (context, state) {
              return _DownloadsAppBarTitle(
                totalBytes: state.totalDownloadsSize,
              );
            },
          ),
          actions: [
            TilawaIconActionButton(
              icon: Icons.refresh_rounded,
              onTap: _loadDownloads,
            ),
            TilawaIconActionButton(
              icon: Icons.delete_sweep_rounded,
              onTap: () => _showClearAllDialog(context),
            ),
            SizedBox(width: 8),
          ],
        ),
        body: BlocBuilder<DownloadsBloc, DownloadsState>(
          builder: (context, state) {
            return _DownloadsBody(state: state);
          },
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
    return switch (state.status) {
      DownloadsStateStatus.initial ||
      DownloadsStateStatus.loading => const TilawaLoadingIndicator(),
      DownloadsStateStatus.loaded => _DownloadsList(
        downloadsByReciter: state.downloads,
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
  const _DownloadsList({required this.downloadsByReciter});

  final Map<String, Map<String, List<DownloadItem>>> downloadsByReciter;

  @override
  Widget build(BuildContext context) {
    if (downloadsByReciter.isEmpty) {
      return const _EmptyDownloadsView();
    }

    final tokens = Theme.of(context).tokens;
    return TilawaContentBounds(
      kind: TilawaContentKind.settings,
      child: ListView(
        padding: EdgeInsets.only(top: tokens.spaceSmall, bottom: 120),
        children: [
          for (int i = 0; i < downloadsByReciter.length; i++)
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: tokens.spaceLarge,
                vertical: tokens.spaceSmall,
              ),
              child: ReciterDownloadsSection(
                reciterName: downloadsByReciter.keys.elementAt(i),
                downloadsByNarrative: downloadsByReciter.values.elementAt(i),
              ),
            ),
        ],
      ),
    );
  }
}

class _DownloadsAppBarTitle extends StatelessWidget {
  const _DownloadsAppBarTitle({required this.totalBytes});

  final int totalBytes;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final String title = context.l10n.downloads;

    if (totalBytes <= 0) {
      return Text(title);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(title),
        Text(
          context.l10n.storageUsed(
            FileSizeFormatter.formatBytes(context, totalBytes),
          ),
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
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

