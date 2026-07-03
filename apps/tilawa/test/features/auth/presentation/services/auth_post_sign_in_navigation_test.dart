import 'package:checks/checks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/features/auth/presentation/services/auth_post_sign_in_navigation.dart';
import 'package:tilawa/router/app_router_config.dart';

void main() {
  test('routes google and email sign-in to home', () async {
    final String destination = await resolvePostAuthDestination('u1');

    check(destination).equals(const HomeRoute().location);
  });

  test('mandatory profile completion location kept for legacy deep links', () {
    check(
      mandatoryProfileCompletionLocation(),
    ).equals('/sessions/profile/complete?mandatory=true');
  });
}
