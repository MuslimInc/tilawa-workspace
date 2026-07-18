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

    return TilawaShellChildScaffold(
      // Material AppBar — Saved Reels is a secondary list, not a branded shell header.
      // ignore: tilawa_lints/tilawa_ui_component
      appBar: AppBar(title: Text(l10n.reelsSavedTitle)),
      body: BlocBuilder<SavedReelsCubit, SavedReelsState>(
        builder: (context, state) {
          return switch (state.status) {
            SavedReelsStatus.initial ||
            SavedReelsStatus.loading => const Center(
              child: CircularProgressIndicator.adaptive(),
            ),
            SavedReelsStatus.error => Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(l10n.reelsLoadError),
                  SizedBox(height: tokens.spaceMedium),
                  TilawaButton(
                    onPressed: () => context.read<SavedReelsCubit>().load(),
                    text: l10n.reelsRetry,
                  ),
                ],
              ),
            ),
            SavedReelsStatus.empty => Center(child: Text(l10n.reelsSavedEmpty)),
            SavedReelsStatus.ready => GridView.builder(
              padding: EdgeInsets.all(tokens.spaceMedium),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: tokens.spaceSmall,
                crossAxisSpacing: tokens.spaceSmall,
                childAspectRatio: 9 / 14,
              ),
              itemCount: state.reels.length,
              itemBuilder: (context, index) {
                final reel = state.reels[index];
                return TilawaCard(
                  onTap: () =>
                      ReelsRoute(initialReelId: reel.id).push<void>(context),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CachedNetworkImage(
                        imageUrl: reel.thumbUrl,
                        fit: BoxFit.cover,
                      ),
                      Positioned(
                        left: tokens.spaceExtraSmall,
                        right: tokens.spaceExtraSmall,
                        bottom: tokens.spaceExtraSmall,
                        child: Text(
                          reel.sheikhName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.labelMedium
                              ?.copyWith(
                                color: Colors.white,
                                shadows: const [
                                  Shadow(blurRadius: 6, color: Colors.black87),
                                ],
                              ),
                        ),
                      ),
                      Positioned(
                        top: 0,
                        right: 0,
                        child: IconButton(
                          icon: const Icon(Icons.bookmark_remove_outlined),
                          color: Colors.white,
                          onPressed: () =>
                              context.read<SavedReelsCubit>().unsave(reel.id),
                        ),
                      ),
                      Positioned(
                        top: tokens.spaceExtraSmall,
                        left: tokens.spaceExtraSmall,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: Colors.black45,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: tokens.spaceExtraSmall,
                              vertical: 2,
                            ),
                            child: Text(
                              ReelCategoryLabels.forId(
                                context,
                                reel.categoryId,
                              ),
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(color: Colors.white),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          };
        },
      ),
    );
  }
}
