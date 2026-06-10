import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Primary sections shown in the Reciters home screen.
enum RecitersHomeTab { all, favorites, downloads }

/// Base event for Reciters home tab changes.
abstract class RecitersTabsEvent extends Equatable {
  const RecitersTabsEvent();

  @override
  List<Object?> get props => [];
}

/// Selects a primary Reciters home tab.
class RecitersTabSelected extends RecitersTabsEvent {
  const RecitersTabSelected(this.tab);

  final RecitersHomeTab tab;

  @override
  List<Object?> get props => [tab];
}

/// Current primary tab selection for the Reciters home screen.
class RecitersTabsState extends Equatable {
  const RecitersTabsState({this.selectedTab = RecitersHomeTab.all});

  final RecitersHomeTab selectedTab;

  int get selectedIndex => selectedTab.index;

  @override
  List<Object?> get props => [selectedTab];
}

/// Coordinates Reciters home tab selection.
class RecitersTabsBloc extends Bloc<RecitersTabsEvent, RecitersTabsState> {
  RecitersTabsBloc({RecitersHomeTab initialTab = RecitersHomeTab.all})
    : super(RecitersTabsState(selectedTab: initialTab)) {
    // Rapid tab taps/swipes should converge on the latest requested tab.
    on<RecitersTabSelected>(_onTabSelected, transformer: restartable());
  }

  void _onTabSelected(
    RecitersTabSelected event,
    Emitter<RecitersTabsState> emit,
  ) {
    if (event.tab == state.selectedTab) {
      return;
    }

    emit(RecitersTabsState(selectedTab: event.tab));
  }
}
