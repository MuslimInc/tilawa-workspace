import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/features/reciters/presentation/screens/reciters_screen.dart';
import 'package:tilawa/shared/widgets/quran_player_system_back.dart';

void main() {
  tearDown(QuranPlayerSystemBackCoordinator.debugReset);

  group('QuranPlayerSystemBackCoordinator', () {
    test('interceptsSystemBack is false when unset', () {
      expect(QuranPlayerSystemBackCoordinator.interceptsSystemBack, isFalse);
    });

    test('setIntercepts updates interceptsSystemBack', () {
      QuranPlayerSystemBackCoordinator.setIntercepts(true);
      expect(QuranPlayerSystemBackCoordinator.interceptsSystemBack, isTrue);
    });

    test('handleSystemBack invokes bound handler', () {
      var handled = 0;
      QuranPlayerSystemBackCoordinator.bind(handle: () => handled++);
      QuranPlayerSystemBackCoordinator.handleSystemBack();
      expect(handled, 1);
    });

    test('unbind clears intercepts and handler', () {
      void handle() {}
      QuranPlayerSystemBackCoordinator.setIntercepts(true);
      QuranPlayerSystemBackCoordinator.bind(handle: handle);
      QuranPlayerSystemBackCoordinator.unbind(handle: handle);
      expect(QuranPlayerSystemBackCoordinator.interceptsSystemBack, isFalse);
      QuranPlayerSystemBackCoordinator.handleSystemBack();
    });
  });

  group('RecitersRootBackScope.canPop', () {
    test('blocks app exit while player intercepts back', () {
      QuranPlayerSystemBackCoordinator.setIntercepts(true);
      expect(RecitersRootBackScope.canPop(0), isFalse);
    });

    test('allows exit on reciters tab when player is hidden', () {
      expect(RecitersRootBackScope.canPop(0), isTrue);
    });

    test('blocks exit on non-reciters tabs', () {
      expect(RecitersRootBackScope.canPop(1), isFalse);
    });
  });
}
