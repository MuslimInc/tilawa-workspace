import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa/core/layout/list_scroll_bottom_padding.dart';
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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDownloads();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _loadDownloads() {
    logger.d('DownloadsScreen: Loading downloads...');
    context.read<DownloadsBloc>().add(const LoadDownloads());
  }

  void _onScroll() {
    // Handle scroll events if needed
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final int totalBytes = context.select<DownloadsBloc, int>(
      (DownloadsBloc bloc) => bloc.state.totalDownloadsSize,
    );

    return BlocListener<DownloadsBloc, DownloadsState>(
      listenWhen: (DownloadsState previous, DownloadsState current) =>
          current.uiNotificationSeq != previous.uiNotificationSeq &&
          current.uiNotification != null,
      listener: (BuildContext context, DownloadsState state) {
        context.read<DownloadsBloc>().add(const ClearDownloadsUiNotification());
      },
      child: Scaffold(
        appBar: _DownloadsScreenAppBar.fromContext(
          totalBytes: totalBytes,
          onRefresh: _loadDownloads,
        ),
        body: BlocBuilder<DownloadsBloc, DownloadsState>(
          builder: (context, state) {
            return _DownloadsBody(state: state);
          },
        ),
      ),
    );
  }
}

class DownloadsTabView extends StatefulWidget {
  const DownloadsTabView({super.key});

  @override
  State<DownloadsTabView> createState() => _DownloadsTabViewState();
}

class _DownloadsTabViewState extends State<DownloadsTabView>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      context.read<DownloadsBloc>().add(const LoadDownloads());
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return BlocListener<DownloadsBloc, DownloadsState>(
      listenWhen: (DownloadsState previous, DownloadsState current) =>
          current.uiNotificationSeq != previous.uiNotificationSeq &&
          current.uiNotification != null,
      listener: (BuildContext context, DownloadsState state) {
        context.read<DownloadsBloc>().add(const ClearDownloadsUiNotification());
      },
      child: BlocBuilder<DownloadsBloc, DownloadsState>(
        builder: (context, state) {
          return _DownloadsBody(state: state);
        },
      ),
    );
  }
}

class DownloadsNestedTabView extends StatefulWidget {
  const DownloadsNestedTabView({super.key, this.onBrowseReciters});

  final VoidCallback? onBrowseReciters;

  @override
  State<DownloadsNestedTabView> createState() => _DownloadsNestedTabViewState();
}

class _DownloadsNestedTabViewState extends State<DownloadsNestedTabView>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      context.read<DownloadsBloc>().add(const LoadDownloads());
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return BlocListener<DownloadsBloc, DownloadsState>(
      listenWhen: (DownloadsState previous, DownloadsState current) =>
          current.uiNotificationSeq != previous.uiNotificationSeq &&
          current.uiNotification != null,
      listener: (BuildContext context, DownloadsState state) {
        context.read<DownloadsBloc>().add(const ClearDownloadsUiNotification());
      },
      child: BlocBuilder<DownloadsBloc, DownloadsState>(
        builder: (context, state) {
          return _DownloadsSliverBody(
            state: state,
            onBrowseReciters: widget.onBrowseReciters,
          );
        },
      ),
    );
  }
}

class _DownloadsScreenAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  const _DownloadsScreenAppBar({
    required this.totalBytes,
    required this.onRefresh,
  });

  factory _DownloadsScreenAppBar.fromContext({
    required int totalBytes,
    required VoidCallback onRefresh,
  }) {
    return _DownloadsScreenAppBar(
      totalBytes: totalBytes,
      onRefresh: onRefresh,
    );
  }

  final int totalBytes;
  final VoidCallback onRefresh;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return TilawaCatalogAppBar(
      title: context.l10n.downloads,
      leading: TilawaAppBarChrome.catalogBackButton(
        context: context,
        onPressed: () => Navigator.maybePop(context),
      ),
      titleWidget: totalBytes > 0
          ? _DownloadsAppBarTitle(totalBytes: totalBytes)
          : null,
      actions: <Widget>[
        _DownloadsRefreshButton(onPressed: onRefresh),
        _DownloadsClearAllButton(enabled: totalBytes > 0),
      ],
    );
  }
}

class _DownloadsRefreshButton extends StatelessWidget {
  const _DownloadsRefreshButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return TilawaIconActionButton(
      icon: Icons.refresh_rounded,
      onTap: onPressed,
    );
  }
}

class _DownloadsClearAllButton extends StatelessWidget {
  const _DownloadsClearAllButton({required this.enabled});

  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return TilawaIconActionButton(
      icon: Icons.delete_sweep_rounded,
      enabled: enabled,
      onTap: () {
        if (enabled) {
          _ClearAllDownloadsDialog.show(context);
        }
      },
    );
  }
}

class _ClearAllDownloadsDialog extends StatelessWidget {
  const _ClearAllDownloadsDialog({required this.downloadsBloc});

  final DownloadsBloc downloadsBloc;

  static Future<void> show(BuildContext context) {
    final DownloadsBloc downloadsBloc = context.read<DownloadsBloc>();
    return showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) => _ClearAllDownloadsDialog(
        downloadsBloc: downloadsBloc,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
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
            downloadsBloc.add(const ClearAllDownloads());
          },
        ),
      ],
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

class _DownloadsSliverBody extends StatelessWidget {
  const _DownloadsSliverBody({
    required this.state,
    this.onBrowseReciters,
  });

  final DownloadsState state;
  final VoidCallback? onBrowseReciters;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      key: const PageStorageKey<String>('reciters_downloads_tab'),
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      slivers: [
        SliverOverlapInjector(
          handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
        ),
        switch (state.status) {
          DownloadsStateStatus.initial ||
          DownloadsStateStatus.loading => const SliverFillRemaining(
            hasScrollBody: false,
            child: TilawaLoadingIndicator(),
          ),
          DownloadsStateStatus.loaded => _DownloadsSliverList(
            downloadsByReciter: state.downloads,
            onBrowseReciters: onBrowseReciters,
          ),
          DownloadsStateStatus.error => SliverFillRemaining(
            child: _ErrorView(
              message: state.errorMessage ?? context.l10n.error,
            ),
          ),
        },
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
      child: TilawaErrorState(
        icon: Icons.cloud_off_rounded,
        title: message,
        retryLabel: context.l10n.retry,
        onRetry: () {
          context.read<DownloadsBloc>().add(const LoadDownloads());
        },
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
        padding: EdgeInsets.only(
          top: tokens.spaceSmall,
          bottom: listScrollBottomPadding(context),
        ),
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

class _DownloadsSliverList extends StatelessWidget {
  const _DownloadsSliverList({
    required this.downloadsByReciter,
    this.onBrowseReciters,
  });

  final Map<String, Map<String, List<DownloadItem>>> downloadsByReciter;
  final VoidCallback? onBrowseReciters;

  @override
  Widget build(BuildContext context) {
    if (downloadsByReciter.isEmpty) {
      return SliverFillRemaining(
        child: _EmptyDownloadsView(onBrowseReciters: onBrowseReciters),
      );
    }

    final tokens = Theme.of(context).tokens;
    return SliverToBoxAdapter(
      child: TilawaContentBounds(
        kind: TilawaContentKind.settings,
        child: Padding(
          padding: EdgeInsets.only(
            top: tokens.spaceSmall,
            bottom: listScrollBottomPadding(context),
          ),
          child: Column(
            children: [
              for (int i = 0; i < downloadsByReciter.length; i++)
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: tokens.spaceLarge,
                    vertical: tokens.spaceSmall,
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
    final tokens = theme.tokens;
    final String title = context.l10n.downloads;
    final TextStyle? titleStyle = theme.textTheme.titleLarge?.copyWith(
      fontWeight: FontWeight.w700,
    );

    if (totalBytes <= 0) {
      return Text(title, style: titleStyle);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      spacing: tokens.spaceTiny,
      children: [
        Text(title, style: titleStyle),
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
  const _EmptyDownloadsView({this.onBrowseReciters});

  final VoidCallback? onBrowseReciters;

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: TilawaIllustratedState(
        icon: Icons.offline_pin_rounded,
        title: context.l10n.noDownloadsYet,
        subtitle: context.l10n.downloadSurahsOffline,
        semanticLabel: context.l10n.noDownloadsYet,
        primaryAction: TilawaButton(
          text: context.l10n.reciters,
          leadingIcon: const Icon(Icons.record_voice_over_rounded),
          onPressed: onBrowseReciters ?? () => context.go('/'),
        ),
      ),
    );
  }
}
