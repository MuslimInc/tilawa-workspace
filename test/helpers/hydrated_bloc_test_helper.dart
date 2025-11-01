import 'package:hydrated_bloc/hydrated_bloc.dart';

/// Initializes HydratedStorage for testing
/// This should be called in setUpAll before creating any HydratedBloc instances
/// Uses web storage directory which works in test environment
/// Note: This may fail if Hive is not properly initialized, in which case
/// the test will need to handle storage initialization differently
Future<void> initializeHydratedStorageForTest() async {
  try {
    // Try to build storage with web directory (works in test environment)
    HydratedBloc.storage = await HydratedStorage.build(
      storageDirectory: HydratedStorageDirectory.web,
    );
  } catch (e) {
    // If initialization fails, create a minimal mock storage
    // This allows tests to run even if full storage initialization fails
    HydratedBloc.storage = _MockHydratedStorage();
  }
}

/// A minimal mock storage that prevents errors but doesn't actually persist data
class _MockHydratedStorage implements Storage {
  final Map<String, dynamic> _data = {};

  @override
  Future<void> write(String key, dynamic value) async {
    _data[key] = value;
  }

  @override
  Future<dynamic> read(String key) async {
    return _data[key];
  }

  @override
  Future<void> delete(String key) async {
    _data.remove(key);
  }

  @override
  Future<void> clear() async {
    _data.clear();
  }

  @override
  Future<void> close() async {
    _data.clear();
  }
}

/// Clears HydratedStorage after tests
/// This should be called in tearDownAll
Future<void> clearHydratedStorageForTest() async {
  try {
    await HydratedBloc.storage.clear();
  } catch (e) {
    // Storage may not have been initialized, ignore
  }
}
