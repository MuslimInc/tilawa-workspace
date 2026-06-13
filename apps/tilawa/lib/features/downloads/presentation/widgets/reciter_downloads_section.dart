import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa/core/utils/file_size_formatter.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/entities/download_item.dart';
import '../bloc/downloads_bloc.dart';
import 'download_item_card.dart';

// Auto-expand when the list is short enough that the expand affordance adds
// friction without payoff.
const int _kAutoExpandItemThreshold = 3;

class ReciterDownloadsSection extends StatefulWidget {
  const ReciterDownloadsSection({
    super.key,
    required this.reciterName,
    required this.downloadsByNarrative,
  });

  final String reciterName;
  final Map<String, List<DownloadItem>> downloadsByNarrative;

  @override
  State<ReciterDownloadsSection> createState() =>
      _ReciterDownloadsSectionState();
}

class _ReciterDownloadsSectionState extends State<ReciterDownloadsSection> {
  late bool _isExpanded;

  List<DownloadItem> get _allDownloads => widget.downloadsByNarrative.values
      .expand((downloads) => downloads)
      .toList();

  @override
  void initState() {
    super.initState();
    _isExpanded = _allDownloads.length <= _kAutoExpandItemThreshold;
  }

  @override
  Widget build(BuildContext context) {
    final List<DownloadItem> downloads = _allDownloads;
    final theme = Theme.of(context);
    final tokens = theme.tokens;
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 0,
      shadowColor: colorScheme.shadow.withValues(alpha: tokens.opacityShadow),
      color: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(tokens.radiusLarge),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(
            alpha: tokens.opacityMedium,
          ),
          width: tokens.borderWidthThin,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: DecoratedBox(
        decoration: BoxDecoration(color: colorScheme.surface),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildReciterHeader(context, downloads),
            AnimatedCrossFade(
              firstChild: const SizedBox(height: 0, width: double.infinity),
              secondChild: Column(
                children: [
                  TilawaDivider(
                    height: 1,
                    color: colorScheme.outlineVariant.withValues(
                      alpha: tokens.opacitySubtle,
                    ),
                  ),
                  _buildDownloadsList(context),
                ],
              ),
              crossFadeState: _isExpanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: tokens.durationMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReciterHeader(
    BuildContext context,
    List<DownloadItem> downloads,
  ) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;
    final colorScheme = theme.colorScheme;

    return InkWell(
      onTap: () => setState(() => _isExpanded = !_isExpanded),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: tokens.spaceLarge,
          vertical: tokens.spaceMedium,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _ReciterAvatar(reciterName: widget.reciterName),
            SizedBox(width: tokens.spaceMedium),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.reciterName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: tokens.spaceTiny),
                  _ReciterMetaLine(downloads: downloads),
                ],
              ),
            ),
            AnimatedRotation(
              turns: _isExpanded ? 0.5 : 0,
              duration: tokens.durationFast,
              child: Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 18,
                color: colorScheme.onSurfaceVariant.withValues(
                  alpha: tokens.opacityMedium,
                ),
              ),
            ),
            _OverflowMenu(
              onDeleteAll: () => _showDeleteReciterDialog(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDownloadsList(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;
    final colorScheme = theme.colorScheme;
    final Color dividerColor = colorScheme.outlineVariant.withValues(
      alpha: tokens.opacitySubtle,
    );

    if (widget.downloadsByNarrative.length == 1) {
      final List<DownloadItem> downloads =
          widget.downloadsByNarrative.values.first;
      return _DownloadList(
        downloads: downloads,
        dividerColor: dividerColor,
        horizontalPadding: tokens.spaceLarge,
        onDelete: _dispatchDelete,
      );
    }

    return Column(
      children: widget.downloadsByNarrative.entries.map((entry) {
        final String narrativeName = entry.key;
        final List<DownloadItem> narrativeDownloads = entry.value;
        final bool isLastNarrative =
            entry.key == widget.downloadsByNarrative.keys.last;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(
                horizontal: tokens.spaceLarge,
                vertical: tokens.spaceSmall,
              ),
              color: colorScheme.surfaceContainerLowest,
              child: Text(
                narrativeName,
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colorScheme.primary,
                  letterSpacing: 0.4,
                ),
              ),
            ),
            _DownloadList(
              downloads: narrativeDownloads,
              dividerColor: dividerColor,
              horizontalPadding: tokens.spaceLarge,
              onDelete: _dispatchDelete,
            ),
            if (!isLastNarrative) TilawaDivider(height: 1, color: dividerColor),
          ],
        );
      }).toList(),
    );
  }

  void _dispatchDelete(String downloadId) {
    context.read<DownloadsBloc>().add(
      DeleteDownloadEvent(downloadId: downloadId),
    );
  }

  void _showDeleteReciterDialog(BuildContext parentContext) {
    final DownloadsBloc downloadsBloc = parentContext.read<DownloadsBloc>();
    final String reciterName = widget.reciterName;

    showDialog<void>(
      context: parentContext,
      builder: (dialogContext) => AlertDialog(
        title: Text(dialogContext.l10n.deleteAll),
        content: Text(
          AppLocalizations.of(
            dialogContext,
          )!.deleteAllDownloadsConfirmation(reciterName),
        ),
        actions: [
          TilawaButton(
            text: dialogContext.l10n.cancel,
            variant: TilawaButtonVariant.ghost,
            onPressed: () => Navigator.of(dialogContext).pop(),
          ),
          TilawaButton(
            text: dialogContext.l10n.deleteAll,
            variant: TilawaButtonVariant.danger,
            onPressed: () {
              Navigator.of(dialogContext).pop();
              downloadsBloc.add(
                DeleteReciterDownloads(reciterName: reciterName),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ReciterAvatar extends StatelessWidget {
  const _ReciterAvatar({required this.reciterName});

  final String reciterName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final tokens = theme.tokens;
    final String initial = reciterName.isNotEmpty
        ? reciterName.characters.first.toUpperCase()
        : 'R';

    return Container(
      width: 44,
      height: 44,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: colorScheme.primaryContainer,
        border: Border.all(
          color: colorScheme.primary.withValues(alpha: tokens.opacitySubtle),
          width: tokens.borderWidthThin,
        ),
      ),
      child: Text(
        initial,
        style: theme.textTheme.titleMedium?.copyWith(
          color: colorScheme.onPrimaryContainer,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _ReciterMetaLine extends StatelessWidget {
  const _ReciterMetaLine({required this.downloads});

  final List<DownloadItem> downloads;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final int count = downloads.length;
    final String surahWord = count == 1
        ? 'surah'
        : context.l10n.surahs.toLowerCase();
    final int totalBytes = downloads.fold<int>(
      0,
      (sum, d) => sum + (d.fileSize > 0 ? d.fileSize : d.downloadedSize),
    );
    final String sizeText = totalBytes > 0
        ? ' · ${FileSizeFormatter.formatBytes(context, totalBytes)}'
        : '';

    return Text(
      '$count $surahWord$sizeText',
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: theme.textTheme.bodySmall?.copyWith(
        color: colorScheme.onSurfaceVariant,
      ),
    );
  }
}

class _OverflowMenu extends StatelessWidget {
  const _OverflowMenu({required this.onDeleteAll});

  final VoidCallback onDeleteAll;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final tokens = theme.tokens;

    return PopupMenuButton<String>(
      icon: Icon(
        Icons.more_vert_rounded,
        color: colorScheme.onSurfaceVariant,
      ),
      tooltip: context.l10n.deleteAll,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(tokens.radiusMedium),
      ),
      onSelected: (value) {
        if (value == 'delete_all') onDeleteAll();
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'delete_all',
          child: Row(
            children: [
              Icon(
                Icons.delete_outline_rounded,
                color: colorScheme.error,
                size: tokens.iconSizeMedium,
              ),
              SizedBox(width: tokens.spaceMedium),
              Text(
                context.l10n.deleteAll,
                style: TextStyle(color: colorScheme.error),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DownloadList extends StatelessWidget {
  const _DownloadList({
    required this.downloads,
    required this.dividerColor,
    required this.horizontalPadding,
    required this.onDelete,
  });

  final List<DownloadItem> downloads;
  final Color dividerColor;
  final double horizontalPadding;
  final void Function(String downloadId) onDelete;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: downloads.asMap().entries.map((entry) {
        final int index = entry.key;
        final DownloadItem download = entry.value;
        return Column(
          children: [
            DownloadItemCard(
              download: download,
              onDelete: () => onDelete(download.id),
            ),
            if (index != downloads.length - 1)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                child: TilawaDivider(height: 1, color: dividerColor),
              ),
          ],
        );
      }).toList(),
    );
  }
}
