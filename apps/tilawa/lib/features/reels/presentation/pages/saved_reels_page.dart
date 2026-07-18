import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa/router/app_router_config.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../cubit/saved_reels_cubit.dart';
import '../cubit/saved_reels_state.dart';
import '../utils/reel_category_labels.dart';

class SavedReelsPage extends StatefulWidget {
  const SavedReelsPage({super.key});

  @override
  State<SavedReelsPage> createState() => _SavedReelsPageState();
}

class _SavedReelsPageState extends State<SavedReelsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SavedReelsCubit>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final tokens = context.tokens;
    final radius = tokens.resolveRadius(family: TilawaRadiusFamily.card);

    return TilawaShellChildScaffold(
      appBar: TilawaCatalogAppBar.titleOnly(title: l10n.reelsSavedTitle),
      body: BlocBuilder<SavedReelsCubit, SavedReelsState>(
        builder: (context, state) {
          return switch (state.status) {
            SavedReelsStatus.initial ||
            SavedReelsStatus.loading => const Center(
              child: CircularProgressIndicator.adaptive(),
            ),
            SavedReelsStatus.error => Center(
              child: Padding(
                padding: EdgeInsets.all(tokens.spaceLarge),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      l10n.reelsLoadError,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    SizedBox(height: tokens.spaceMedium),
                    TilawaButton(
                      onPressed: () => context.read<SavedReelsCubit>().load(),
                      text: l10n.reelsRetry,
                    ),
                  ],
                ),
              ),
            ),
            SavedReelsStatus.empty => TilawaEmptyState(
              icon: Icons.bookmark_border,
              title: l10n.reelsSavedEmpty,
            ),
            SavedReelsStatus.ready => GridView.builder(
              padding: EdgeInsets.all(tokens.spaceMedium),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: tokens.spaceSmall,
                crossAxisSpacing: tokens.spaceSmall,
                childAspectRatio: 9 / 16,
              ),
              itemCount: state.reels.length,
              itemBuilder: (context, index) {
                final reel = state.reels[index];
                // Sibling Stack: card navigates; unsave is a separate action.
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    TilawaCard(
                      padding: EdgeInsets.zero,
                      expandHeight: true,
                      borderRadius: radius,
                      onTap: () => ReelsRoute(
                        initialReelId: reel.id,
                      ).push<void>(context),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          CachedNetworkImage(
                            imageUrl: reel.thumbUrl,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                          ),
                          Positioned(
                            left: 0,
                            right: 0,
                            bottom: 0,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    Colors.black.withValues(alpha: 0.75),
                                  ],
                                ),
                              ),
                              child: Padding(
                                padding: EdgeInsets.fromLTRB(
                                  tokens.spaceSmall,
                                  tokens.spaceLarge,
                                  tokens.spaceSmall,
                                  tokens.spaceSmall,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      ReelCategoryLabels.forId(
                                        context,
                                        reel.categoryId,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelSmall
                                          ?.copyWith(color: Colors.white70),
                                    ),
                                    Text(
                                      reel.sheikhName,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelMedium
                                          ?.copyWith(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Positioned.directional(
                      textDirection: Directionality.of(context),
                      top: tokens.spaceExtraSmall,
                      end: tokens.spaceExtraSmall,
                      child: Material(
                        color: Colors.black45,
                        shape: const CircleBorder(),
                        child: IconButton(
                          visualDensity: VisualDensity.compact,
                          icon: const Icon(
                            Icons.bookmark_remove_outlined,
                            color: Colors.white,
                          ),
                          tooltip: l10n.reelsActionSave,
                          onPressed: () =>
                              context.read<SavedReelsCubit>().unsave(reel.id),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          };
        },
      ),
    );
  }
}
