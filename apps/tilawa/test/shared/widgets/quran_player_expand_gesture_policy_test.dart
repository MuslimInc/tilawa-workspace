import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/shared/widgets/quran_player_expand_gesture_policy.dart';
import 'package:tilawa/shared/widgets/quran_player_expand_physics.dart';

void main() {
  group('QuranPlayerExpandGesturePolicy', () {
    group('audit: double delta application (#1)', () {
      test(
        'when pointer route is attached only pointerRoute may apply deltas',
        () {
          const bool routeAttached = true;

          expect(
            QuranPlayerExpandGesturePolicy.shouldApplyRecognizerDragDelta(
              pointerRouteAttached: routeAttached,
              channel: QuranPlayerExpandDragChannel.footerRecognizer,
            ),
            isFalse,
          );
          expect(
            QuranPlayerExpandGesturePolicy.shouldApplyRecognizerDragDelta(
              pointerRouteAttached: routeAttached,
              channel: QuranPlayerExpandDragChannel.expandedRecognizer,
            ),
            isFalse,
          );
          expect(
            QuranPlayerExpandGesturePolicy.shouldApplyRecognizerDragDelta(
              pointerRouteAttached: routeAttached,
              channel: QuranPlayerExpandDragChannel.pointerRoute,
            ),
            isTrue,
          );
        },
      );

      test('duplicate recognizer + route apply doubles progress travel', () {
        const double travel = 724;
        const double delta = -72.4;

        final double once = QuranPlayerExpandPhysics.applyDragDelta(
          current: 0,
          dragPixels: delta,
          travelPixels: travel,
        );
        final double twice = QuranPlayerExpandPhysics.applyDragDelta(
          current: once,
          dragPixels: delta,
          travelPixels: travel,
        );

        expect(once, closeTo(0.1, 0.001));
        expect(twice, closeTo(0.2, 0.001));
        expect(twice - once, closeTo(once, 0.001));
      });
    });

    group('audit: global pointer route scoping (#2)', () {
      test('ignores move events from non-active pointers', () {
        expect(
          QuranPlayerExpandGesturePolicy.shouldPointerRouteApplyMove(
            isUserDraggingExpand: true,
            activePointerId: 7,
            eventPointerId: 8,
          ),
          isFalse,
        );
        expect(
          QuranPlayerExpandGesturePolicy.shouldPointerRouteApplyMove(
            isUserDraggingExpand: true,
            activePointerId: 7,
            eventPointerId: 7,
          ),
          isTrue,
        );
      });

      test('first move may claim pointer when active id unset', () {
        expect(
          QuranPlayerExpandGesturePolicy.shouldPointerRouteApplyMove(
            isUserDraggingExpand: true,
            activePointerId: null,
            eventPointerId: 3,
          ),
          isTrue,
        );
      });
    });

    group('audit: snap velocity race (#3)', () {
      test('pointer route finishes when recognizer end was lost', () {
        expect(
          QuranPlayerExpandGesturePolicy.shouldPointerRouteFinishOnRelease(
            pointerRouteAttached: true,
            dragEndHandled: false,
            activePointerId: 7,
            eventPointerId: 7,
          ),
          isTrue,
        );
        expect(
          QuranPlayerExpandGesturePolicy.shouldPointerRouteFinishOnRelease(
            pointerRouteAttached: true,
            dragEndHandled: true,
            activePointerId: 7,
            eventPointerId: 7,
          ),
          isFalse,
        );
        expect(
          QuranPlayerExpandGesturePolicy.shouldPointerRouteFinishOnRelease(
            pointerRouteAttached: false,
            dragEndHandled: false,
            activePointerId: 7,
            eventPointerId: 7,
          ),
          isFalse,
        );
      });

      test('pointer route ignores release from non-active pointer', () {
        expect(
          QuranPlayerExpandGesturePolicy.shouldPointerRouteFinishOnRelease(
            pointerRouteAttached: true,
            dragEndHandled: false,
            activePointerId: 7,
            eventPointerId: 99,
          ),
          isFalse,
        );
      });

      test('upward fling expands at mid progress when velocity is known', () {
        const double progress = 0.35;
        const double upwardVelocity = -900;

        final PlayerExpandSnapTarget snap =
            QuranPlayerExpandPhysics.resolveSnap(
              progress: progress,
              primaryVelocity: upwardVelocity,
              progressThreshold: 0.45,
              velocityThreshold: 500,
            );

        expect(snap, PlayerExpandSnapTarget.expand);
      });

      test('zero velocity at mid progress collapses without upward fling', () {
        final PlayerExpandSnapTarget snap =
            QuranPlayerExpandPhysics.resolveSnap(
              progress: 0.35,
              primaryVelocity: 0,
              progressThreshold: 0.45,
              velocityThreshold: 500,
            );

        expect(snap, PlayerExpandSnapTarget.collapse);
      });
    });
  });
}
