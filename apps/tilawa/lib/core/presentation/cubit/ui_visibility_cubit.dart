import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

/// Cubit to manage the visibility of global and screen-specific UI chrome.
/// Used for "Immersive Mode" in the Quran Reader.
@lazySingleton
class UiVisibilityCubit extends Cubit<bool> {
  UiVisibilityCubit() : super(true);

  /// Toggles the UI visibility state.
  void toggle() => emit(!state);

  /// Forces the UI to be visible.
  void show() => emit(true);

  /// Forces the UI to be hidden.
  void hide() => emit(false);
}
