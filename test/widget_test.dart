// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lebedew_app/core/config/app_config.dart';
import 'package:lebedew_app/core/config/injection.dart';
import 'package:lebedew_app/main.dart';
import 'package:lebedew_app/presentation/screens/login_screen.dart';

void main() {
  setUpAll(() async {
    // Initialisiere AppConfig für Tests
    await AppConfig.initialize(
      env: Environment.development,
      resetSecureStorage: true,
    );
    
    // Initialisiere Dependency Injection
    await setupDependencies();
  });
  
  testWidgets('App startet und zeigt Login-Screen', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          // Hier können Provider-Overrides für Tests definiert werden
        ],
        child: const MyApp(),
      ),
    );

    // Verify that the login screen is shown
    expect(find.byType(LoginScreen), findsOneWidget);
  });
}
