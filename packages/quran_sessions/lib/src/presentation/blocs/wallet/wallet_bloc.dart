import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/usecases/get_wallet_snapshot_usecase.dart';
import 'wallet_event.dart';
import 'wallet_state.dart';

class WalletBloc extends Bloc<WalletEvent, WalletState> {
  WalletBloc({required this._getWalletSnapshot})
    : super(const WalletInitial()) {
    on<WalletLoadRequested>(_onLoadRequested);
  }

  final GetWalletSnapshotUseCase _getWalletSnapshot;

  Future<void> _onLoadRequested(
    WalletLoadRequested event,
    Emitter<WalletState> emit,
  ) async {
    emit(const WalletLoading());

    final result = await _getWalletSnapshot(event.userId);
    result.fold(
      (failure) => emit(WalletFailure(failure)),
      (snapshot) => emit(
        WalletSuccess(
          wallet: snapshot.wallet,
          transactions: snapshot.transactions,
        ),
      ),
    );
  }
}
