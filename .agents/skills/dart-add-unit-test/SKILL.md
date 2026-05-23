---
name: dart-add-unit-test
description: >-
  Write unit tests with package:test. In Tilawa, prefer package:checks
  assertions and fake/stub dependencies over mockito unless mocks are required.
metadata:
  model: models/gemini-3.1-pro-preview
  last_modified: Sat, 23 May 2026 12:00:00 GMT
---
# Testing Dart and Flutter Applications

## Tilawa conventions

- Prefer **`package:checks`** for assertions (`dart-migrate-to-checks-package`).
- Prefer **fakes or stubs** over mocks; use `mockito` only when interaction
  verification or codegen mocks are explicitly needed.
- Mirror `lib/` under `test/`; run with `flutter test` in app packages.

## Contents
- [Structuring Test Files](#structuring-test-files)
- [Writing Tests](#writing-tests)
- [Executing Tests](#executing-tests)
- [Test Implementation Workflow](#test-implementation-workflow)
- [Examples](#examples)

## Structuring Test Files
Organize test files to mirror the `lib` directory structure to maintain predictability.

* Place all test code within the `test` directory at the root of the package.
* Append `_test.dart` to the end of all test file names (e.g., `lib/src/utils.dart` should be tested in `test/src/utils_test.dart`).
* If writing integration tests, place them in an `integration_test` directory at the root of the package.

## Writing Tests
Utilize `package:test` as the standard testing library for Dart applications.

* Import `package:test/test.dart` (or `package:flutter_test/flutter_test.dart`
  for Flutter).
* In Tilawa packages that use checks: `import 'package:checks/checks.dart';`
* Group related tests using `group()`.
* Define cases with `test()`.
* **Assertions:** Prefer `package:checks` (e.g. `check(that).equals(...)`).
  Legacy `expect()` + matchers are acceptable in packages not yet migrated.
* Use `async`/`await` for asynchronous tests.
* Use `setUp()` and `tearDown()` for shared fixtures.
* **Dependencies:** Inject fakes/stubs implementing the same interface. Use
  `mockito` only when the user requests mocks or interaction verification.

## Executing Tests
Select the appropriate test runner based on the project type and test location.

* If working on a pure Dart project, execute tests using the `dart test` command.
* If working on a Flutter project, execute tests using the `flutter test` command.
* If running integration tests, explicitly specify the directory path, as the default runner ignores it: `dart test integration_test` or `flutter test integration_test`.

## Test Implementation Workflow

Follow this sequential workflow when implementing new test suites. Copy the checklist to track your progress.

### Task Progress
- [ ] 1. Create the test file in the `test/` directory, ensuring the `_test.dart` suffix.
- [ ] 2. Import `package:test/test.dart` and the target library.
- [ ] 3. Define a `main()` function.
- [ ] 4. Initialize shared resources or mocks using `setUp()`.
- [ ] 5. Write `test()` cases grouped by functionality using `group()`.
- [ ] 6. Execute the test suite using the appropriate CLI command.
- [ ] 7. **Feedback Loop**: Run test -> Review stack trace for failures -> Fix implementation or assertions -> Re-run until passing.

## Examples

### Standard Unit Test Suite
Demonstrates grouping, setup, synchronous, and asynchronous testing.

```dart
import 'package:test/test.dart';
import 'package:my_package/calculator.dart';

void main() {
  group('Calculator', () {
    late Calculator calc;

    setUp(() {
      calc = Calculator();
    });

    test('adds two numbers correctly', () {
      expect(calc.add(2, 3), equals(5));
    });

    test('handles asynchronous operations', () async {
      final result = await calc.fetchRemoteValue();
      expect(result, isNotNull);
      expect(result, greaterThan(0));
    });
  });
}
```

### Fake repository (preferred in Tilawa)

```dart
class FakeUserRepository implements UserRepository {
  User? user;

  @override
  Future<Either<Failure, User>> getUser(String id) async {
    if (user == null) {
      return Left(ServerFailure());
    }
    return Right(user!);
  }
}
```

### Mocking with Mockito (when required)
Demonstrates configuring a mock object for dependency injection testing.

```dart
import 'package:test/test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:my_package/api_client.dart';
import 'package:my_package/data_service.dart';

// Generate the mock using build_runner: dart run build_runner build
@GenerateNiceMocks([MockSpec<ApiClient>()])
import 'data_service_test.mocks.dart';

void main() {
  group('DataService', () {
    late MockApiClient mockApiClient;
    late DataService dataService;

    setUp(() {
      mockApiClient = MockApiClient();
      dataService = DataService(apiClient: mockApiClient);
    });

    test('returns parsed data on successful API call', () async {
      // Configure the mock
      when(mockApiClient.get('/data')).thenAnswer((_) async => '{"id": 1}');

      // Execute the system under test
      final result = await dataService.fetchData();

      // Verify outcomes and interactions
      expect(result.id, equals(1));
      verify(mockApiClient.get('/data')).called(1);
    });
  });
}
```
