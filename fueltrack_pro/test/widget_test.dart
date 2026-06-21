import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fueltrack_pro/app.dart';
import 'package:fueltrack_pro/models/app_settings.dart';
import 'package:fueltrack_pro/providers/settings_provider.dart';

class _TestSettingsNotifier extends SettingsNotifier {
  @override
  Future<AppSettings> build() async =>
      AppSettings.defaults().copyWith(onboardingCompleted: false);
}

void main() {
  testWidgets('App loads onboarding welcome screen', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          settingsProvider.overrideWith(_TestSettingsNotifier.new),
        ],
        child: const FuelTrackApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('FuelTrack Pro'), findsWidgets);
    expect(find.text('Get Started'), findsOneWidget);
    expect(find.text('Skip'), findsOneWidget);
  });
}
