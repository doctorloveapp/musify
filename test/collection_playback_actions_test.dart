import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:musify/widgets/collection_playback_actions.dart';

void main() {
  Widget buildActions(double width, {VoidCallback? onEdit}) {
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
              onEdit: onEdit,
              editTooltip: 'Ordina brani',
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

  testWidgets('favorites pencil fits before Share and opens reorder', (
    tester,
  ) async {
    var edited = false;
    await tester.pumpWidget(buildActions(300, onEdit: () => edited = true));
    await tester.pumpAndSettle();
    final edit = find.byTooltip('Ordina brani');
    final share = find.byTooltip('Condividi');
    expect(tester.getRect(edit).right, lessThan(tester.getRect(share).left));
    expect(tester.getRect(find.text('Riproduci')).height, lessThan(30));
    await tester.tap(edit);
    expect(edited, isTrue);
    expect(tester.takeException(), isNull);
  });
}
