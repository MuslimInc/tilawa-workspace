import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tilawa/core/navigation/notification_launch_dedup.dart';

import 'notification_launch_dedup_test.mocks.dart';

@GenerateMocks([SharedPreferencesAsync])
void main() {
  late MockSharedPreferencesAsync mockPrefs;
  const int pid = 9001;

  setUp(() {
    mockPrefs = MockSharedPreferencesAsync();
    when(mockPrefs.getInt(NotificationLaunchDedup.lastNotifPidKey)).thenAnswer(
      (_) async => pid,
    );
    when(mockPrefs.getInt(NotificationLaunchDedup.lastNotifIdKey)).thenAnswer(
      (_) async => null,
    );
    when(
      mockPrefs.getString(NotificationLaunchDedup.lastNotifPayloadSigKey),
    ).thenAnswer((_) async => null);
    when(
      mockPrefs.getInt(NotificationLaunchDedup.schemaVersionKey),
    ).thenAnswer((_) async => NotificationLaunchDedup.currentSchemaVersion);
    when(mockPrefs.setInt(any, any)).thenAnswer((_) async {});
    when(mockPrefs.setString(any, any)).thenAnswer((_) async {});
  });

  group('launchSignature', () {
    test('prefers payload over id when payload is present', () {
      expect(
        NotificationLaunchDedup.launchSignature(
          notificationId: 1001,
          payload: 'morning_athkar_20260627',
        ),
        'p:morning_athkar_20260627',
      );
    });

    test('falls back to id when payload empty', () {
      expect(
        NotificationLaunchDedup.launchSignature(
          notificationId: 42,
          payload: '',
        ),
        'i:42',
      );
    });

    test('returns null when both id and payload missing', () {
      expect(
        NotificationLaunchDedup.launchSignature(
          notificationId: null,
          payload: null,
        ),
        isNull,
      );
    });
  });

  group('isProcessedLaunch', () {
    test('same payload signature in same process is processed', () async {
      when(
        mockPrefs.getString(NotificationLaunchDedup.lastNotifPayloadSigKey),
      ).thenAnswer((_) async => 'p:morning_athkar_20260627');

      expect(
        await NotificationLaunchDedup.isProcessedLaunch(
          launchNotificationId: 1001,
          launchPayload: 'morning_athkar_20260627',
          prefs: mockPrefs,
          pid: pid,
        ),
        isTrue,
      );
    });

    test('different process pid is never processed', () async {
      when(
        mockPrefs.getInt(NotificationLaunchDedup.lastNotifPidKey),
      ).thenAnswer(
        (_) async => pid + 1,
      );

      expect(
        await NotificationLaunchDedup.isProcessedLaunch(
          launchNotificationId: 1001,
          launchPayload: 'morning_athkar_20260627',
          prefs: mockPrefs,
          pid: pid,
        ),
        isFalse,
      );
    });

    test('different notification id in same process is fresh', () async {
      when(
        mockPrefs.getString(NotificationLaunchDedup.lastNotifPayloadSigKey),
      ).thenAnswer((_) async => 'p:morning_athkar_20260627');

      expect(
        await NotificationLaunchDedup.isProcessedLaunch(
          launchNotificationId: 1002,
          launchPayload: 'evening_athkar_20260627',
          prefs: mockPrefs,
          pid: pid,
        ),
        isFalse,
      );
    });

    test('same id with different payload is fresh', () async {
      when(
        mockPrefs.getString(NotificationLaunchDedup.lastNotifPayloadSigKey),
      ).thenAnswer((_) async => 'p:morning_athkar_20260627');

      expect(
        await NotificationLaunchDedup.isProcessedLaunch(
          launchNotificationId: 1001,
          launchPayload: 'morning_athkar_20260628',
          prefs: mockPrefs,
          pid: pid,
        ),
        isFalse,
      );
    });

    test('payload-only handled launch blocks id-less replay', () async {
      when(
        mockPrefs.getString(NotificationLaunchDedup.lastNotifPayloadSigKey),
      ).thenAnswer((_) async => 'p:{"type":"prayer","prayer_key":"fajr"}');

      expect(
        await NotificationLaunchDedup.isProcessedLaunch(
          launchNotificationId: null,
          launchPayload: '{"type":"prayer","prayer_key":"fajr"}',
          prefs: mockPrefs,
          pid: pid,
        ),
        isTrue,
      );
    });

    test('missing id and payload never treated as processed', () async {
      expect(
        await NotificationLaunchDedup.isProcessedLaunch(
          launchNotificationId: null,
          launchPayload: null,
          prefs: mockPrefs,
          pid: pid,
        ),
        isFalse,
      );
    });

    test(
      'repairs corrupted id-only cache and blocks payload replay on hot restart',
      () async {
        when(
          mockPrefs.getString(NotificationLaunchDedup.lastNotifPayloadSigKey),
        ).thenAnswer((_) async => 'i:1001');
        when(
          mockPrefs.getInt(NotificationLaunchDedup.lastNotifIdKey),
        ).thenAnswer(
          (_) async => 1001,
        );

        expect(
          await NotificationLaunchDedup.isProcessedLaunch(
            launchNotificationId: 1001,
            launchPayload: 'morning_athkar_20260627',
            prefs: mockPrefs,
            pid: pid,
          ),
          isTrue,
        );

        verify(
          mockPrefs.setString(
            NotificationLaunchDedup.lastNotifPayloadSigKey,
            'p:morning_athkar_20260627',
          ),
        ).called(1);
      },
    );
  });

  group('persist', () {
    test('writes pid and payload signature', () async {
      await NotificationLaunchDedup.persist(
        notificationId: 1001,
        payload: 'morning_athkar_20260627',
        prefs: mockPrefs,
        pid: pid,
      );

      verify(
        mockPrefs.setInt(NotificationLaunchDedup.lastNotifPidKey, pid),
      ).called(1);
      verify(
        mockPrefs.setString(
          NotificationLaunchDedup.lastNotifPayloadSigKey,
          'p:morning_athkar_20260627',
        ),
      ).called(1);
      verify(
        mockPrefs.setInt(NotificationLaunchDedup.lastNotifIdKey, 1001),
      ).called(1);
    });

    test(
      'does not downgrade payload signature to id-only in same process',
      () async {
        when(
          mockPrefs.getString(NotificationLaunchDedup.lastNotifPayloadSigKey),
        ).thenAnswer((_) async => 'p:morning_athkar_20260627');

        await NotificationLaunchDedup.persist(
          notificationId: 1001,
          prefs: mockPrefs,
          pid: pid,
        );

        verifyNever(
          mockPrefs.setString(
            NotificationLaunchDedup.lastNotifPayloadSigKey,
            'i:1001',
          ),
        );
        verify(
          mockPrefs.setInt(NotificationLaunchDedup.lastNotifIdKey, 1001),
        ).called(1);
      },
    );
  });
}
