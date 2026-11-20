import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

class FirebaseBootstrap {
  const FirebaseBootstrap._();

  static Future<void> initialize() async {
    await Firebase.initializeApp();

    try {
      const recaptchaKey = String.fromEnvironment('RECAPTCHA_V3_KEY');
      if (!kIsWeb) {
        await FirebaseAppCheck.instance.activate(
          androidProvider: kDebugMode
              ? AndroidProvider.debug
              : AndroidProvider.playIntegrity,
          appleProvider:
              kDebugMode ? AppleProvider.debug : AppleProvider.appAttest,
        );
      } else if (recaptchaKey.isNotEmpty) {
        await FirebaseAppCheck.instance.activate(
          webProvider: ReCaptchaV3Provider(recaptchaKey),
        );
      }
    } catch (_) {
      // App Check must be configured before production, but its absence
      // should not prevent Firebase Authentication from starting.
    }

    await FirebaseCrashlytics.instance
        .setCrashlyticsCollectionEnabled(!kDebugMode);
  }
}
