import 'package:equatable/equatable.dart';

/// Events for the [NavigationBloc].
///
/// These events represent user interactions and system triggers
/// that affect navigation visibility and page state.
abstract class NavigationEvent extends Equatable {
  const NavigationEvent();

  @override
  List<Object?> get props => [];
}

/// Event to initialize navigation state
class NavigationInitialized extends NavigationEvent {
  const NavigationInitialized();
}

/// Event to show navigation controls
class NavigationShown extends NavigationEvent {
  const NavigationShown();
}

/// Event to hide navigation controls
class NavigationHidden extends NavigationEvent {
  const NavigationHidden();
}

/// Event triggered when user starts interacting
class NavigationInteractionStarted extends NavigationEvent {
  const NavigationInteractionStarted();
}

/// Event triggered when user ends interacting
class NavigationInteractionEnded extends NavigationEvent {
  const NavigationInteractionEnded();
}

/// Event to toggle navigation visibility
class NavigationToggled extends NavigationEvent {
  const NavigationToggled();
}

class NavigationAutoHideChecked extends NavigationEvent {
  const NavigationAutoHideChecked();
}

/// Event to preview a page during slider drag (no navigation)
class PagePreviewed extends NavigationEvent {
  final int pageNumber;

  const PagePreviewed(this.pageNumber);

  @override
  List<Object?> get props => [pageNumber];
}

/// Event to navigate to a specific page
class PageNavigated extends NavigationEvent {
  final int pageNumber;

  const PageNavigated(this.pageNumber);

  @override
  List<Object?> get props => [pageNumber];
}

/// Event to navigate to next page
class NextPageRequested extends NavigationEvent {
  const NextPageRequested();
}

/// Event to navigate to previous page
class PreviousPageRequested extends NavigationEvent {
  const PreviousPageRequested();
}

/// Event triggered when page changes from PageView
class PageChanged extends NavigationEvent {
  final int pageNumber;

  const PageChanged(this.pageNumber);

  @override
  List<Object?> get props => [pageNumber];
}
