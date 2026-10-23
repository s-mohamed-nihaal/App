import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:unani_academy/main.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await Supabase.initialize(
      url: 'https://vgizrsmymuvidivlviza.supabase.co',
      anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZnaXpyc215bXV2aWRpdmx2aXphIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzM5NDYwNDEsImV4cCI6MjA4OTUyMjA0MX0.2OzUlbdWy6cyXosX7jIT6CCoKlgbySvB16nSAtWKwj8',
    );
  });

  testWidgets('App loads smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: MyApp()));
    expect(find.byType(MaterialApp), findsOneWidget);
    // Pump past the 2-second splash timer and animation
    await tester.pumpAndSettle(const Duration(seconds: 3));
  });
}
