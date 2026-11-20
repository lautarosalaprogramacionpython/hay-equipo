import 'package:material_ui/material_ui.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'app_shell.dart';
import 'app_theme.dart';
import 'auth_screen.dart';
import 'demo_store.dart';
import 'production_shell.dart';
import 'ui_kit.dart';

class HayEquipoApp extends StatefulWidget {
  const HayEquipoApp({required this.demoMode, super.key});

  final bool demoMode;

  @override
  State<HayEquipoApp> createState() => _HayEquipoAppState();
}

class _HayEquipoAppState extends State<HayEquipoApp> {
  late final DemoStore _store = DemoStore();
  late final Future<void> _ready = _store.initialize();

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _store,
        builder: (context, _) => MaterialApp(
          title: 'Hay Equipo',
          debugShowCheckedModeBanner: false,
          theme: buildAppTheme(Brightness.light),
          darkTheme: buildAppTheme(Brightness.dark),
          themeMode: _store.themeMode,
          home: widget.demoMode
              ? FutureBuilder<void>(
                  future: _ready,
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return StartupErrorScreen(error: snapshot.error!);
                    }
                    if (snapshot.connectionState != ConnectionState.done) {
                      return const StartupScreen();
                    }
                    return AppShell(store: _store);
                  },
                )
              : StreamBuilder<User?>(
                  stream: FirebaseAuth.instance.authStateChanges(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const StartupScreen();
                    }
                    final user = snapshot.data;
                    if (user == null) return const AuthScreen();
                    return ProductionShell(user: user);
                  },
                ),
        ),
      );

  @override
  void dispose() {
    _store.dispose();
    super.dispose();
  }
}

class StartupScreen extends StatelessWidget {
  const StartupScreen({super.key});

  @override
  Widget build(BuildContext context) => const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
}

class StartupErrorScreen extends StatelessWidget {
  const StartupErrorScreen({required this.error, super.key});

  final Object error;

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 40),
                  const SizedBox(height: 12),
                  Text(
                    'No se pudo preparar la demo',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(error.toString(), textAlign: TextAlign.center),
                ],
              ),
            ),
          ),
        ),
      );
}

class ProductionHandoffScreen extends StatelessWidget {
  const ProductionHandoffScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const BrandMark(size: 60),
                    const SizedBox(height: 24),
                    Text(
                      'Hay Equipo',
                      style: Theme.of(context).textTheme.displayLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'La experiencia de demostración se habilita con '
                      '`--dart-define=DEMO_MODE=true`.',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 16),
                    const LocalDemoBadge(
                      label: 'Modo conectado pendiente de integración',
                      icon: Icons.construction_outlined,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Esta compilación no simula inicio de sesión ni envía '
                      'datos a un backend. Revisá README.md para la entrega '
                      'y los siguientes pasos de producción.',
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
}
