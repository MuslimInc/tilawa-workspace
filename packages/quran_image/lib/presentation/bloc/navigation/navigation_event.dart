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
  final int? initialPage;

  const NavigationInitialized({this.initialPage});

  @override
  List<Object?> get props => [initialPage];
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

/// Event triggered when page changes from PageView
class PageChanged extends NavigationEvent {
  final int pageNumber;

  const PageChanged(this.pageNumber);

  @override
  List<Object?> get props => [pageNumber];
}

/// Event to persist the last visited page.
class LastVisitedPageSaved extends NavigationEvent {
  final int pageNumber;

  const LastVisitedPageSaved(this.pageNumber);

  @override
  List<Object?> get props => [pageNumber];
}

/// Event triggered when a page navigation retry is requested.
class NavigationRetryRequested extends NavigationEvent {
  const NavigationRetryRequested();
}
