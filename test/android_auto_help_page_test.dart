import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:musify/localization/app_localizations.dart';
import 'package:musify/screens/android_auto_help_page.dart';

void main() {
  testWidgets('shows the Android Auto sideload guide in Italian', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('it'),
        localizationsDelegates: [
          AppLocalizations.delegate,
          ...GlobalMaterialLocalizations.delegates,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: AndroidAutoHelpPage(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Usare Musify in Android Auto'), findsOneWidget);
    expect(find.text('Apri le impostazioni di Android Auto'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Consenti le origini sconosciute'),
      300,
      scrollable: find.byType(Scrollable),
    );

    expect(find.text('Consenti le origini sconosciute'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
