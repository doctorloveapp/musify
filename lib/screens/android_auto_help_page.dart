import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:material_ui/material_ui.dart';
import 'package:musify/constants/app_constants.dart';
import 'package:musify/extensions/l10n.dart';
import 'package:musify/utilities/url_launcher.dart';

const _officialAndroidAutoTestingGuide =
    'https://developer.android.com/training/cars/testing#enable_developer_mode';

class AndroidAutoHelpPage extends StatelessWidget {
  const AndroidAutoHelpPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n!;
    final colorScheme = Theme.of(context).colorScheme;
    final steps = [
      (l10n.androidAutoStep1Title, l10n.androidAutoStep1Body),
      (l10n.androidAutoStep2Title, l10n.androidAutoStep2Body),
      (l10n.androidAutoStep3Title, l10n.androidAutoStep3Body),
      (l10n.androidAutoStep4Title, l10n.androidAutoStep4Body),
    ];

    return Scaffold(
      appBar: AppBar(title: Text(l10n.androidAuto)),
      body: ListView(
        padding: commonSingleChildScrollViewPadding,
        children: [
          Card(
            elevation: 0,
            color: colorScheme.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Icon(
                    FluentIcons.vehicle_car_24_filled,
                    size: 48,
                    color: colorScheme.onPrimaryContainer,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    l10n.androidAutoGuideTitle,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.androidAutoGuideIntro,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: colorScheme.onPrimaryContainer),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          for (var index = 0; index < steps.length; index++) ...[
            _GuideStep(
              number: index + 1,
              title: steps[index].$1,
              body: steps[index].$2,
            ),
            if (index != steps.length - 1) const SizedBox(height: 8),
          ],
          const SizedBox(height: 12),
          Card(
            elevation: 0,
            color: colorScheme.tertiaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    FluentIcons.shield_24_filled,
                    color: colorScheme.onTertiaryContainer,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.androidAutoSecurityTitle,
                          style: TextStyle(
                            color: colorScheme.onTertiaryContainer,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l10n.androidAutoSecurityBody,
                          style: TextStyle(
                            color: colorScheme.onTertiaryContainer,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            icon: const Icon(FluentIcons.open_24_regular),
            label: Text(l10n.openOfficialAndroidAutoGuide),
            onPressed: () =>
                launchURL(Uri.parse(_officialAndroidAutoTestingGuide)),
          ),
          const SizedBox(height: 28),
        ],
      ),
    );
  }
}

class _GuideStep extends StatelessWidget {
  const _GuideStep({
    required this.number,
    required this.title,
    required this.body,
  });

  final int number;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
              child: Text(
                '$number',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 5),
                  Text(body),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
