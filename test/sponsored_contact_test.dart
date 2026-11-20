import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hay_equipo/app/demo_store.dart';
import 'package:hay_equipo/app/profile_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('sponsorship contact is manual and does not process payments',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final store = DemoStore();
    await store.initialize();
    addTearDown(store.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: ProfileScreen(store: store)),
      ),
    );
    await tester.pumpAndSettle();

    final tile = find.text('Promocionar un comercio o torneo');
    await tester.ensureVisible(tile);
    await tester.tap(tile);
    await tester.pumpAndSettle();

    expect(find.text('Espacios patrocinados'), findsOneWidget);
    expect(find.textContaining('revisa cada propuesta manualmente'),
        findsOneWidget);
    expect(find.textContaining('no procesa pagos'), findsOneWidget);
  });
}
