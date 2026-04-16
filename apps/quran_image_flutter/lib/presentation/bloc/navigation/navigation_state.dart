import 'package:equatable/equatable.dart';

import '../../../domain/domain.dart';

/// States for the [NavigationBloc].
///
/// These states represent the various UI states for navigation
/// controls and page management.
abstract class NavigationState extends Equatable {
  const NavigationState();

  @override
  List<Object?> get props => [];
}

/// Initial state before navigation is initialized
class NavigationInitial extends NavigationState {
  const NavigationInitial();
}

/// State when navigation is loading
class NavigationLoading extends NavigationState {
  const NavigationLoading();
}

/// State when navigation is ready with loaded data
class NavigationLoaded extends NavigationState {
  final PageState pageState;
  final NavigationVisibility visibility;

  const NavigationLoaded({required this.pageState, required this.visibility});

  /// Creates a copy with modified fields
  NavigationLoaded copyWith({
    PageState? pageState,
    NavigationVisibility? visibility,
  }) {
    return NavigationLoaded(
      pageState: pageState ?? this.pageState,
      visibility: visibility ?? this.visibility,
    );
  }

  @override
  List<Object?> get props => [pageState, visibility];
}

/// State when navigation encounters an error
class NavigationError extends NavigationState {
  final AppMessage appMessage;

  const NavigationError(this.appMessage);

  @override
  List<Object?> get props => [appMessage];
}
