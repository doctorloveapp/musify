import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musify/utilities/language_utils.dart';

void main() {
  test('an Italian regional device locale resolves to Italian', () {
    expect(
      resolveSupportedDeviceLocale(const [Locale('it', 'IT')]),
      const Locale('it'),
    );
  });

  test('resolution tries the next device locale before English fallback', () {
    expect(
      resolveSupportedDeviceLocale(const [Locale('nl', 'NL'), Locale('fr')]),
      const Locale('fr'),
    );
    expect(
      resolveSupportedDeviceLocale(const [Locale('nl', 'NL')]),
      const Locale('en'),
    );
  });
}
