import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/features/location/application/services/location_state_machine.dart';
import 'package:tilawa/features/location/domain/models/location_state.dart';

void main() {
  group('LocationStateMachine', () {
    late LocationStateMachine stateMachine;

    setUp(() {
      stateMachine = LocationStateMachine();
    });

    test('initial state is permissionNotRequested', () {
      expect(
        stateMachine.state.status,
        LocationStateStatus.permissionNotRequested,
      );
      expect(stateMachine.state.isManualOverride, false);
    });

    test('transitions to denied when permission is denied', () {
      stateMachine.handlePermissionDenied();
      expect(stateMachine.state.status, LocationStateStatus.denied);
    });

    test(
      'transitions to permanentlyDenied when permission is permanently denied',
      () {
        stateMachine.handlePermissionPermanentlyDenied();
        expect(
          stateMachine.state.status,
          LocationStateStatus.permanentlyDenied,
        );
      },
    );

    test(
      'transitions to manualLocationSelected when manual override is chosen',
      () {
        stateMachine.handleManualOverrideSelected();
        expect(
          stateMachine.state.status,
          LocationStateStatus.manualLocationSelected,
        );
        expect(stateMachine.state.isManualOverride, true);
      },
    );

    test('resets to automatic location correctly', () {
      stateMachine.handleManualOverrideSelected();
      stateMachine.resetToAutomatic();
      expect(
        stateMachine.state.status,
        LocationStateStatus.permissionNotRequested,
      );
      expect(stateMachine.state.isManualOverride, false);
    });
  });
}
