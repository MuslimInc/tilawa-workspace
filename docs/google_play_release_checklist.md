# Tilawa Google Play Release Checklist

## 1. Version and Branch

- [ ] Confirm release branch is stable and merged to master.
- [ ] Update app version in apps/tilawa/pubspec.yaml.
- [ ] Update CHANGELOG.md with release notes.
- [ ] Create and push release tag (example: v0.1.4+21).

## 2. Security and Signing

- [ ] Ensure apps/tilawa/android/key.properties exists locally or in CI secret.
- [ ] Verify release keystore alias and passwords are valid.
- [ ] Confirm release build is signed with upload key (not debug key).
- [ ] Verify cleartext traffic remains disabled in Android manifest.

## 3. Quality Gates

- [ ] melos bootstrap
- [ ] melos run analyze
- [ ] melos run format
- [ ] melos run test
- [ ] Resolve all failing tests and analyzer warnings configured as fatal.

## 4. Build Artifacts

- [ ] Build production AAB: cd apps/tilawa && flutter build appbundle --release
- [ ] Verify artifact exists: apps/tilawa/build/app/outputs/bundle/release/app-release.aab
- [ ] Smoke test release build on physical Android devices.

## 5. Play Console Readiness

- [ ] Upload AAB to internal testing first.
- [ ] Complete Data Safety and privacy policy declarations.
- [ ] Validate required permissions rationale (notifications, location, camera).
- [ ] Check pre-launch report for crashes and ANRs.
- [ ] Roll out staged production (for example 5%, 20%, 50%, 100%).

## 6. Post Release

- [ ] Monitor Crashlytics and ANR dashboards.
- [ ] Monitor analytics for startup failures and playback regressions.
- [ ] Prepare hotfix branch and rollback plan.
