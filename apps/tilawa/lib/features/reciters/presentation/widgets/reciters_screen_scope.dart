import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tilawa/core/di/injection.dart';

import '../../../localization/presentation/bloc/localization_bloc.dart';
import '../../domain/usecases/get_reciters_use_case.dart';
import '../bloc/alphabet_scrollbar/alphabet_scrollbar_bloc.dart';
import '../bloc/reciters_bloc.dart';
import '../screens/reciters_screen.dart';

/// Composition root for [RecitersScreen] (main tab 0).
class RecitersScreenScope extends StatelessWidget {
  const RecitersScreenScope({super.key, this.child});

  /// When set (e.g. in widget tests), replaces [RecitersScreen].
  final Widget? child;

  static RecitersBloc _createRecitersBloc(String catalogLanguageCode) {
    final getReciters = getIt<GetRecitersUseCase>();
    return RecitersBloc(
      getReciters,
      initialReciters: getReciters.takeCachedSuccessForStartup(),
      catalogLanguageCode: catalogLanguageCode,
    );
  }

  @override
  Widget build(BuildContext context) {
    final String catalogLanguageCode = context
        .read<LocalizationBloc>()
        .state
        .locale
        .languageCode;
    final RecitersBloc recitersBloc = _createRecitersBloc(catalogLanguageCode);

    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => recitersBloc),
        BlocProvider(create: (_) => getIt<AlphabetScrollbarBloc>()),
      ],
      child: _RecitersCatalogLanguageSync(
        child: child ?? const RecitersScreen(),
      ),
    );
  }
}

/// Ensures the reciters catalog matches the active app locale.
///
/// [LocalizationBloc] listeners inside [RecitersScreen] miss changes that
/// happened before the tab was first built, so we reconcile on mount too.
class _RecitersCatalogLanguageSync extends StatefulWidget {
  const _RecitersCatalogLanguageSync({required this.child});

  final Widget child;

  @override
  State<_RecitersCatalogLanguageSync> createState() =>
      _RecitersCatalogLanguageSyncState();
}

class _RecitersCatalogLanguageSyncState
    extends State<_RecitersCatalogLanguageSync> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncCatalogLanguage());
  }

  void _syncCatalogLanguage() {
    if (!mounted) {
      return;
    }
    final String languageCode = context
        .read<LocalizationBloc>()
        .state
        .locale
        .languageCode;
    context.read<RecitersBloc>().add(LanguageChanged(languageCode));
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<LocalizationBloc, LocalizationState>(
      listenWhen: (LocalizationState previous, LocalizationState current) =>
          previous.locale != current.locale,
      listener: (context, state) {
        context.read<RecitersBloc>().add(
          LanguageChanged(state.locale.languageCode),
        );
      },
      child: widget.child,
    );
  }
}
