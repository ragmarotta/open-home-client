import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:open_home_client/main.dart';
import 'package:open_home_client/data/repositories/mock_device_repository.dart';
import 'package:open_home_client/data/repositories/mock_climate_repository.dart';
import 'package:open_home_client/data/repositories/mock_audio_repository.dart';
import 'package:open_home_client/data/repositories/mock_monitoring_repository.dart';

import 'package:open_home_client/core/persistence/local_database.dart';

void main() {
  testWidgets('OpenHomeApp smoke test - renders main navigation and dashboard', (WidgetTester tester) async {
    // Instantiate Mock Repositories
    final deviceRepository = MockDeviceRepository();
    final climateRepository = MockClimateRepository();
    final audioRepository = MockAudioRepository();
    final monitoringRepository = MockMonitoringRepository();
    final localDatabase = LocalDatabase();

    // Build our app and trigger a frame.
    await tester.pumpWidget(
      OpenHomeApp(
        deviceRepository: deviceRepository,
        climateRepository: climateRepository,
        audioRepository: audioRepository,
        monitoringRepository: monitoringRepository,
        localDatabase: localDatabase,
      ),
    );

    // Verify that the title "Smart Dashboard" appears.
    // Note: Since dashboard has loading states, we may need to pump to trigger the BLoC loaded state.
    await tester.pumpAndSettle();

    expect(find.text('Painel Inteligente'), findsOneWidget);
    expect(find.byIcon(Icons.meeting_room), findsOneWidget);
  });
}
