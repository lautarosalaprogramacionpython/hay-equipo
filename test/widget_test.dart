import 'package:flutter_test/flutter_test.dart';
import 'package:hay_equipo/app/hay_equipo_app.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('demo opens on the football community home', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const HayEquipoApp(demoMode: true));
    await tester.pumpAndSettle();

    expect(find.text('¿Hay equipo?'), findsOneWidget);
    expect(find.text('Buscar partido'), findsOneWidget);
    expect(find.text('Demo · datos locales'), findsOneWidget);
  });
}
