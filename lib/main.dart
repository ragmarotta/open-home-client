import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

// Tema
import 'core/theme/app_theme.dart';

// Localização
import 'core/localization/app_localizations.dart';

// Persistência
import 'core/persistence/local_database.dart';

// Repositórios
import 'domain/repositories/device_repository.dart';
import 'domain/repositories/climate_repository.dart';
import 'domain/repositories/audio_repository.dart';
import 'domain/repositories/monitoring_repository.dart';

// Repositórios Mock (Dados Simulados)
import 'data/repositories/mock_device_repository.dart';
import 'data/repositories/mock_climate_repository.dart';
import 'data/repositories/mock_audio_repository.dart';
import 'data/repositories/mock_monitoring_repository.dart';

// Gerenciadores de Estado (BLoCs)
import 'presentation/blocs/device/device_bloc.dart';
import 'presentation/blocs/climate/climate_bloc.dart';
import 'presentation/blocs/audio/audio_bloc.dart';
import 'presentation/blocs/monitoring/monitoring_bloc.dart';
import 'presentation/blocs/settings/settings_bloc.dart';
import 'presentation/blocs/tuya/tuya_bloc.dart';
import 'presentation/blocs/room/room_bloc.dart';

// Telas Principais
import 'presentation/screens/main_navigation_screen.dart';

/// Função principal que inicializa os serviços básicos do Flutter e inicia o app.
void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Instanciação das implementações de dados locais mockados.
  final deviceRepository = MockDeviceRepository();
  final climateRepository = MockClimateRepository();
  final audioRepository = MockAudioRepository();
  final monitoringRepository = MockMonitoringRepository();
  
  // Banco de dados local para persistência de integrações e espaços
  final localDatabase = LocalDatabase();

  runApp(
    OpenHomeApp(
      deviceRepository: deviceRepository,
      climateRepository: climateRepository,
      audioRepository: audioRepository,
      monitoringRepository: monitoringRepository,
      localDatabase: localDatabase,
    ),
  );
}

/// Widget raiz do aplicativo Open Home.
/// 
/// Realiza a injeção global de dependências através do `MultiRepositoryProvider`
/// e do `MultiBlocProvider`, além de gerenciar a inicialização do tema e do idioma.
class OpenHomeApp extends StatelessWidget {
  final DeviceRepository deviceRepository;
  final ClimateRepository climateRepository;
  final AudioRepository audioRepository;
  final MonitoringRepository monitoringRepository;
  final LocalDatabase localDatabase;

  const OpenHomeApp({
    super.key,
    required this.deviceRepository,
    required this.climateRepository,
    required this.audioRepository,
    required this.monitoringRepository,
    required this.localDatabase,
  });

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<DeviceRepository>.value(value: deviceRepository),
        RepositoryProvider<ClimateRepository>.value(value: climateRepository),
        RepositoryProvider<AudioRepository>.value(value: audioRepository),
        RepositoryProvider<MonitoringRepository>.value(value: monitoringRepository),
        RepositoryProvider<LocalDatabase>.value(value: localDatabase),
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
          BlocProvider<SettingsBloc>(
            create: (context) => SettingsBloc()..add(LoadSettingsEvent()),
          ),
          BlocProvider<TuyaBloc>(
            create: (context) => TuyaBloc(localDatabase)..add(CheckTuyaConnection()),
          ),
          BlocProvider<RoomBloc>(
            create: (context) => RoomBloc(localDatabase),
          ),
        ],
        child: BlocBuilder<SettingsBloc, SettingsState>(
          builder: (context, settingsState) {
            return MaterialApp(
              title: 'Open Home',
              debugShowCheckedModeBanner: false,
              theme: AppTheme.darkTheme,
              locale: settingsState.locale,
              supportedLocales: const [
                Locale('pt'),
                Locale('en'),
              ],
              localizationsDelegates: const [
                AppLocalizationsDelegate(),
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              home: const MainNavigationScreen(),
            );
          },
        ),
      ),
    );
  }
}
