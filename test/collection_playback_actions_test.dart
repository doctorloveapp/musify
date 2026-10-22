import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:musify/widgets/collection_playback_actions.dart';

void main() {
  Widget buildActions(double width) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: width,
            child: CollectionPlaybackActions(
              playLabel: 'Riproduci',
              shuffleLabel: 'Riproduzione casuale',
              shareTooltip: 'Condividi',
              onPlay: () {},
              onShuffle: () {},
              onShare: () {},
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('keeps Italian action labels on one line on compact screens', (
    tester,
  ) async {
    await tester.pumpWidget(buildActions(360));
    await tester.pumpAndSettle();

    final playRect = tester.getRect(find.text('Riproduci'));
    final shuffleRect = tester.getRect(find.text('Riproduzione casuale'));

    expect(tester.takeException(), isNull);
    expect(playRect.height, lessThan(30));
    expect(shuffleRect.height, lessThan(30));
    expect(shuffleRect.top, greaterThan(playRect.bottom));
  });

  testWidgets('uses one action row when enough width is available', (
    tester,
  ) async {
    await tester.pumpWidget(buildActions(700));
    await tester.pumpAndSettle();

    final playRect = tester.getRect(find.text('Riproduci'));
    final shuffleRect = tester.getRect(find.text('Riproduzione casuale'));

    expect(tester.takeException(), isNull);
    expect(shuffleRect.center.dy, closeTo(playRect.center.dy, 1));
  });
}
