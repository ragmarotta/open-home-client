import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// Theme
import 'core/theme/app_theme.dart';

// Repositories
import 'domain/repositories/device_repository.dart';
import 'domain/repositories/climate_repository.dart';
import 'domain/repositories/audio_repository.dart';
import 'domain/repositories/monitoring_repository.dart';

// Mock Repositories
import 'data/repositories/mock_device_repository.dart';
import 'data/repositories/mock_climate_repository.dart';
import 'data/repositories/mock_audio_repository.dart';
import 'data/repositories/mock_monitoring_repository.dart';

// Blocs
import 'presentation/blocs/device/device_bloc.dart';
import 'presentation/blocs/climate/climate_bloc.dart';
import 'presentation/blocs/audio/audio_bloc.dart';
import 'presentation/blocs/monitoring/monitoring_bloc.dart';

// Screens
import 'presentation/screens/main_navigation_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Instantiate Mock Repositories
  final deviceRepository = MockDeviceRepository();
  final climateRepository = MockClimateRepository();
  final audioRepository = MockAudioRepository();
  final monitoringRepository = MockMonitoringRepository();

  runApp(
    OpenHomeApp(
      deviceRepository: deviceRepository,
      climateRepository: climateRepository,
      audioRepository: audioRepository,
      monitoringRepository: monitoringRepository,
    ),
  );
}

class OpenHomeApp extends StatelessWidget {
  final DeviceRepository deviceRepository;
  final ClimateRepository climateRepository;
  final AudioRepository audioRepository;
  final MonitoringRepository monitoringRepository;

  const OpenHomeApp({
    super.key,
    required this.deviceRepository,
    required this.climateRepository,
    required this.audioRepository,
    required this.monitoringRepository,
  });

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<DeviceRepository>.value(value: deviceRepository),
        RepositoryProvider<ClimateRepository>.value(value: climateRepository),
        RepositoryProvider<AudioRepository>.value(value: audioRepository),
        RepositoryProvider<MonitoringRepository>.value(value: monitoringRepository),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<DeviceBloc>(
            create: (context) => DeviceBloc(deviceRepository),
          ),
          BlocProvider<ClimateBloc>(
            create: (context) => ClimateBloc(climateRepository),
          ),
          BlocProvider<AudioBloc>(
            create: (context) => AudioBloc(audioRepository),
          ),
          BlocProvider<MonitoringBloc>(
            create: (context) => MonitoringBloc(monitoringRepository),
          ),
        ],
        child: MaterialApp(
          title: 'Open Home',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.darkTheme,
          home: const MainNavigationScreen(),
        ),
      ),
    );
  }
}
