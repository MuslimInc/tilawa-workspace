import 'package:flutter/material.dart';

import '../atoms/tilawa_empty_state.dart';
import '../foundation/tilawa_icons.dart';
import '../atoms/tilawa_error_state.dart';
import '../atoms/tilawa_loading_indicator.dart';

/// Screen-level async region states for [TilawaAsyncContent].
enum TilawaAsyncContentState {
  loading,
  empty,
  error,
  content,
}

/// Switches between loading, empty, error, and content regions with kit
/// defaults (spec 015 FR-C01).
class TilawaAsyncContent extends StatelessWidget {
  const TilawaAsyncContent({
    super.key,
    required this.state,
    required this.builder,
    this.loadingBuilder,
    this.emptyBuilder,
    this.errorBuilder,
    this.skeleton,
    this.onRetry,
    this.isRetrying = false,
    this.emptyIcon = TilawaIcons.searchOff,
    this.emptyTitle = 'Nothing here yet',
    this.emptySubtitle,
    this.errorIcon = TilawaIcons.errorOutline,
    this.errorTitle = 'Something went wrong',
    this.errorSubtitle,
    this.retryLabel = 'Try again',
  });

  final TilawaAsyncContentState state;
  final WidgetBuilder builder;
  final WidgetBuilder? loadingBuilder;
  final WidgetBuilder? emptyBuilder;
  final WidgetBuilder? errorBuilder;

  /// Optional skeleton shown in [TilawaAsyncContentState.loading] instead of
  /// the default spinner.
  final Widget? skeleton;

  final VoidCallback? onRetry;
  final bool isRetrying;

  final IconData emptyIcon;
  final String emptyTitle;
  final String? emptySubtitle;

  final IconData errorIcon;
  final String errorTitle;
  final String? errorSubtitle;
  final String retryLabel;

  @override
  Widget build(BuildContext context) {
    return switch (state) {
      TilawaAsyncContentState.loading => _TilawaAsyncLoadingRegion(
        skeleton: skeleton,
        loadingBuilder: loadingBuilder,
      ),
      TilawaAsyncContentState.empty =>
        emptyBuilder?.call(context) ??
            _TilawaAsyncEmptyRegion(
              icon: emptyIcon,
              title: emptyTitle,
              subtitle: emptySubtitle,
            ),
      TilawaAsyncContentState.error =>
        errorBuilder?.call(context) ??
            _TilawaAsyncErrorRegion(
              icon: errorIcon,
              title: errorTitle,
              subtitle: errorSubtitle,
              retryLabel: onRetry != null ? retryLabel : null,
              onRetry: onRetry,
              isRetrying: isRetrying,
            ),
      TilawaAsyncContentState.content => builder(context),
    };
  }
}

class _TilawaAsyncLoadingRegion extends StatelessWidget {
  const _TilawaAsyncLoadingRegion({
    this.skeleton,
    this.loadingBuilder,
  });

  final Widget? skeleton;
  final WidgetBuilder? loadingBuilder;

  @override
  Widget build(BuildContext context) {
    if (skeleton != null) {
      return skeleton!;
    }
    return loadingBuilder?.call(context) ??
        const Center(child: TilawaLoadingIndicator());
  }
}

class _TilawaAsyncEmptyRegion extends StatelessWidget {
  const _TilawaAsyncEmptyRegion({
    required this.icon,
    required this.title,
    this.subtitle,
  });

  final IconData icon;
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return TilawaEmptyState(
      icon: icon,
      title: title,
      subtitle: subtitle,
    );
  }
}

class _TilawaAsyncErrorRegion extends StatelessWidget {
  const _TilawaAsyncErrorRegion({
    required this.icon,
    required this.title,
    this.subtitle,
    this.retryLabel,
    this.onRetry,
    this.isRetrying = false,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final String? retryLabel;
  final VoidCallback? onRetry;
  final bool isRetrying;

  @override
  Widget build(BuildContext context) {
    return TilawaErrorState(
      icon: icon,
      title: title,
      subtitle: subtitle,
      retryLabel: retryLabel,
      onRetry: onRetry,
      isRetrying: isRetrying,
    );
  }
}
