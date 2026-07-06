import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa/features/audio_player/presentation/bloc/audio_player_bloc.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../cubit/reciters_search_cubit.dart';
import '../reciter_semantics_ids.dart';
import '../widgets/reciter_card.dart';
import '../widgets/reciters_catalog_search_field.dart';

/// Dedicated reciter search surface — keyboard stays off the catalog list.
class RecitersSearchScreen extends StatefulWidget {
  const RecitersSearchScreen({super.key});

  @override
  State<RecitersSearchScreen> createState() => _RecitersSearchScreenState();
}

class _RecitersSearchScreenState extends State<RecitersSearchScreen> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  bool _focusScheduled = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _focusNode = FocusNode();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_focusScheduled) {
      return;
    }
    _focusScheduled = true;
    _scheduleKeyboardFocus();
  }

  /// Opens the IME after the push transition finishes.
  ///
  /// A [Hero] around an editable [TextField] drops focus when the flight ends,
  /// which dismisses the keyboard. Focus is scheduled on the settled route
  /// instead.
  void _scheduleKeyboardFocus() {
    final Animation<double>? routeAnimation = ModalRoute.of(context)?.animation;

    void requestFocusWhenReady() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_focusNode.canRequestFocus) {
          return;
        }
        FocusScope.of(context).requestFocus(_focusNode);
      });
    }

    if (routeAnimation == null ||
        routeAnimation.status == AnimationStatus.completed) {
      requestFocusWhenReady();
      return;
    }

    void onRouteAnimationStatus(AnimationStatus status) {
      if (status != AnimationStatus.completed) {
        return;
      }
      routeAnimation.removeStatusListener(onRouteAnimationStatus);
      requestFocusWhenReady();
    }

    routeAnimation.addStatusListener(onRouteAnimationStatus);
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;
    final double keyboardInset = context.keyboardInset;

    return Scaffold(
      // Keep the catalog chrome at a fixed height; inset the list instead.
      resizeToAvoidBottomInset: false,
      appBar: TilawaCatalogAppBar(
        title: context.l10n.reciters,
        bottomContent: RecitersCatalogSearchField(
          controller: _controller,
          focusNode: _focusNode,
          semanticsIdentifier: ReciterSemanticsIds.recitersSearchField,
          scrollPadding: EdgeInsets.only(bottom: keyboardInset + 24),
          onChanged: context.read<RecitersSearchCubit>().queryChanged,
          onClear: () {
            _controller.clear();
            context.read<RecitersSearchCubit>().queryChanged('');
          },
          onTapOutside: (_) => FocusScope.of(context).unfocus(),
        ),
      ),
      body: BlocBuilder<RecitersSearchCubit, RecitersSearchState>(
        builder: (context, state) {
          final bool showBottomPlayer = context.select((AudioPlayerBloc bloc) {
            final AudioPlayerState audioState = bloc.state;
            return audioState.shouldShowBottomPlayer &&
                audioState.currentAudio != null;
          });
          final double listBottomInset =
              keyboardInset +
              (showBottomPlayer
                  ? tokens.spaceSmall
                  : context.floatingBottomPadding);

          return switch (state) {
            RecitersSearchInitial() => const SizedBox.shrink(),
            RecitersSearchLoading() => const _RecitersSearchLoading(),
            RecitersSearchError(:final message) => _RecitersSearchHint(
              message: message,
            ),
            RecitersSearchLoaded(:final query, :final results)
                when results.isEmpty =>
              TilawaIllustratedState(
                icon: Icons.search_off_rounded,
                title: context.l10n.noRecitersForQuery(query),
                subtitle: context.l10n.tryDifferentSearch,
                semanticLabel: context.l10n.noRecitersForQuery(query),
              ),
            RecitersSearchLoaded(:final results) => ListView.separated(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: EdgeInsetsDirectional.fromSTEB(
                tokens.spaceMedium,
                tokens.spaceMedium,
                tokens.spaceMedium,
                tokens.spaceMedium + listBottomInset,
              ),
              itemCount: results.length,
              separatorBuilder: (_, _) => SizedBox(height: tokens.spaceSmall),
              itemBuilder: (context, index) {
                return ReciterCard(reciter: results[index]);
              },
            ),
          };
        },
      ),
    );
  }
}

class _RecitersSearchHint extends StatelessWidget {
  const _RecitersSearchHint({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Align(
      alignment: AlignmentDirectional.topCenter,
      child: Padding(
        padding: EdgeInsets.all(theme.tokens.spaceLarge),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

class _RecitersSearchLoading extends StatelessWidget {
  const _RecitersSearchLoading();

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).tokens;
    return Align(
      alignment: AlignmentDirectional.topCenter,
      child: Padding(
        padding: EdgeInsets.all(tokens.spaceLarge),
        child: const LinearProgressIndicator(),
      ),
    );
  }
}
