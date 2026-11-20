import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';

import 'app/hay_equipo_app.dart';
import 'core/firebase_bootstrap.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  const demoMode = bool.fromEnvironment('DEMO_MODE');
  if (demoMode && kReleaseMode) {
    throw StateError(
      'DEMO_MODE no puede habilitarse en una compilación de producción.',
    );
  }
  if (!demoMode) {
    try {
      await FirebaseBootstrap.initialize();
    } catch (error) {
      runApp(const FirebaseConfigurationScreen(error: ''));
      return;
    }
  }
  runApp(HayEquipoApp(demoMode: demoMode));
}

class FirebaseConfigurationScreen extends StatelessWidget {
  const FirebaseConfigurationScreen({required this.error, super.key});

  final String error;

  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: SafeArea(
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: 560),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Firebase no está configurado',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 12),
                      Text(
                        'Para activar el modo producción configurá un proyecto '
                        'Firebase con flutterfire configure, agregá '
                        'google-services.json / GoogleService-Info.plist y '
                        'habilitá los proveedores que correspondan.',
                      ),
                      SizedBox(height: 12),
                      Text(
                        'No se inició ningún backend y no se enviaron datos.',
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
}
