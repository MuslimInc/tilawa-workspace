import 'package:checks/checks.dart';
import 'package:test/test.dart';
import 'package:tilawa/core/navigation/notification_destination.dart';
import 'package:tilawa/router/deep_link_resolver.dart';

void main() {
  group('Athkar notification destinations restore progress', () {
    const DeepLinkResolver resolver = DeepLinkResolver();

    test('morning Athkar location includes restore-progress', () {
      final NotificationDestination destination = resolver.athkarMorning();

      check(destination.location).contains('restore-progress=true');
    });

    test('evening Athkar location includes restore-progress', () {
      final NotificationDestination destination = resolver.athkarEvening();

      check(destination.location).contains('restore-progress=true');
    });
  });
}
