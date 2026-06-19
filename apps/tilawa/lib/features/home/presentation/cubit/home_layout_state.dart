import 'package:equatable/equatable.dart';

import '../../domain/entities/home_layout_mode.dart';

class HomeLayoutState extends Equatable {
  const HomeLayoutState({this.mode = HomeLayoutMode.list});

  final HomeLayoutMode mode;

  HomeLayoutState copyWith({HomeLayoutMode? mode}) {
    return HomeLayoutState(mode: mode ?? this.mode);
  }

  @override
  List<Object?> get props => [mode];
}
