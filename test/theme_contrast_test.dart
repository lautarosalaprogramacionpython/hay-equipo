import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hay_equipo/app/app_theme.dart';

double _contrast(Color first, Color second) {
  final firstLuminance = first.computeLuminance();
  final secondLuminance = second.computeLuminance();
  final lighter =
      firstLuminance > secondLuminance ? firstLuminance : secondLuminance;
  final darker =
      firstLuminance > secondLuminance ? secondLuminance : firstLuminance;
  return (lighter + 0.05) / (darker + 0.05);
}

void main() {
  test('light and dark themes keep primary button text readable', () {
    for (final brightness in Brightness.values) {
      final scheme = buildAppTheme(brightness).colorScheme;
      expect(
        _contrast(scheme.onPrimary, scheme.primary),
        greaterThanOrEqualTo(4.5),
      );
      expect(
        _contrast(scheme.onSecondary, scheme.secondary),
        greaterThanOrEqualTo(4.5),
      );
    }
  });
}
