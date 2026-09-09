import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:musify/localization/app_localizations.dart';
import 'package:musify/screens/about_page.dart';

void main() {
  testWidgets('About page shows the current Musify branding', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('it'),
        localizationsDelegates: [
          AppLocalizations.delegate,
          ...GlobalMaterialLocalizations.delegates,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: AboutPage(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Musify'), findsOneWidget);
    expect(find.text('v11.0.0'), findsOneWidget);
    expect(find.text('Dan King'), findsOneWidget);
    expect(find.text('Valeri Gokadze'), findsNothing);
  });
}
