import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:mocktail/mocktail.dart';

import 'package:list_nest/main.dart';
import 'package:list_nest/models/list.dart';

// Mock PathProviderPlatform for testing Hive
class MockPathProviderPlatform extends Mock
    with MockPlatformInterfaceMixin
    implements PathProviderPlatform {
  @override
  Future<String?> getApplicationDocumentsPath() async {
    return './test/temp_hive_dir';
  }

  // Implement all abstract methods from PathProviderPlatform
  @override
  Future<String?> getApplicationCachePath() => Future.value(null);

  @override
  Future<String?> getApplicationSupportPath() => Future.value(null);

  @override
  Future<String?> getDownloadsPath() => Future.value(null);

  @override
  Future<List<String>?> getExternalCachePaths() => Future.value(null);

  @override
  Future<String?> getExternalStoragePath() => Future.value(null);

  @override
  Future<List<String>?> getExternalStoragePaths({dynamic type}) =>
      Future.value(null);

  @override
  Future<String?> getLibraryPath() => Future.value(null);

  @override
  Future<String?> getTemporaryPath() => Future.value(null);
}

void main() {
  setUpAll(() async {
    // Initialize Hive for tests with a temporary directory
    PathProviderPlatform.instance = MockPathProviderPlatform();
    await Hive.initFlutter();
    Hive.registerAdapter(AppListAdapter());
    Hive.registerAdapter(AppListItemAdapter());
  });

  tearDownAll(() async {
    // Clean up Hive after all tests are done
    await Hive.deleteFromDisk();
  });

  testWidgets('App starts without Hive errors', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Expect to find the title of the app, indicating it started successfully
    expect(find.text('ListNest'), findsOneWidget);
  });
}
