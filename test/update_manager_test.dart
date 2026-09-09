import 'package:flutter_test/flutter_test.dart';
import 'package:musify/services/update_manager.dart';

void main() {
  group('GitHub release version parsing', () {
    test('accepts semantic tags with an optional prefix', () {
      expect(releaseVersionFromTag('12.0.0'), '12.0.0');
      expect(releaseVersionFromTag('v12.3.4'), '12.3.4');
      expect(releaseVersionFromTag('release-12.3.4'), '12.3.4');
    });

    test('ignores tags without a semantic version', () {
      expect(releaseVersionFromTag('release_zero'), isNull);
      expect(releaseVersionFromTag(null), isNull);
    });

    test('compares major, minor and patch numerically', () {
      expect(isLatestVersionHigher('11.0.0', '12.0.0'), isTrue);
      expect(isLatestVersionHigher('11.0.0', '11.1.0'), isTrue);
      expect(isLatestVersionHigher('11.0.0', '11.0.1'), isTrue);
      expect(isLatestVersionHigher('11.0.0', '11.0.0'), isFalse);
      expect(isLatestVersionHigher('11.0.0', '10.9.9'), isFalse);
    });
  });
}
