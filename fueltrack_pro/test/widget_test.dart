import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fueltrack_pro/app.dart';
import 'package:fueltrack_pro/models/app_settings.dart';
import 'package:fueltrack_pro/providers/settings_provider.dart';

class _TestSettingsNotifier extends SettingsNotifier {
  @override
  Future<AppSettings> build() async => AppSettings.defaults();
}

void main() {
  testWidgets('App loads bootstrap screen', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          settingsProvider.overrideWith(_TestSettingsNotifier.new),
        ],
        child: const FuelTrackApp(),
      ),
    );
    await tester.pump();

    expect(find.text('FuelTrack Pro'), findsOneWidget);
    expect(find.textContaining('Project scaffold ready'), findsOneWidget);
  });
}
