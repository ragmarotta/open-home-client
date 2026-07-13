import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../core/persistence/local_database.dart';
import '../../../data/repositories/tuya_cloud_repository.dart';

// --- Events ---

/// Classe base abstrata para todos os eventos da integração da Tuya.
abstract class TuyaEvent extends Equatable {
  const TuyaEvent();

  @override
  List<Object?> get props => [];
}

/// Verifica o status da conexão da Tuya baseado nas credenciais salvas no banco.
class CheckTuyaConnection extends TuyaEvent {}

/// Tenta autenticar e salvar as novas credenciais da Tuya no banco local.
class ConnectTuya extends TuyaEvent {
  final String clientId;
  final String clientSecret;
  final String region;

  const ConnectTuya({
    required this.clientId,
    required this.clientSecret,
    required this.region,
  });

  @override
  List<Object?> get props => [clientId, clientSecret, region];
}

/// Desconecta o app da Tuya Cloud, limpando a base local de dados.
class DisconnectTuya extends TuyaEvent {}

/// Sincroniza e recarrega todos os dispositivos vinculados da nuvem.
class SyncDevices extends TuyaEvent {}

/// Altera o status (ligar/desligar) de um dispositivo específico.
class ToggleTuyaDevice extends TuyaEvent {
  final String deviceId;
  final bool value;

  const ToggleTuyaDevice({required this.deviceId, required this.value});

  @override
  List<Object?> get props => [deviceId, value];
}

/// Define uma propriedade de um dispositivo (ex: temperatura do ar ou abertura de cortina).
class SetTuyaDeviceProperty extends TuyaEvent {
  final String deviceId;
  final String code;
  final dynamic value;

  const SetTuyaDeviceProperty({
    required this.deviceId,
    required this.code,
    required this.value,
  });

  @override
  List<Object?> get props => [deviceId, code, value];
}

// --- States ---

/// Classe base abstrata contendo os estados de conexão da Tuya.
abstract class TuyaState extends Equatable {
  const TuyaState();

  @override
  List<Object?> get props => [];
}

/// Estado inicial da integração.
class TuyaInitial extends TuyaState {}

/// Estado indicando que o fluxo de conexão ou sincronização está carregando.
class TuyaConnecting extends TuyaState {}

/// Estado indicando que o aplicativo está sincronizado com a nuvem da Tuya.
class TuyaConnected extends TuyaState {
  final String clientId;
  final String region;
  final List<TuyaDeviceModel> devices;

  const TuyaConnected({
    required this.clientId,
    required this.region,
    required this.devices,
  });

  @override
  List<Object?> get props => [clientId, region, devices];
}

/// Estado de desconexão da conta Tuya Cloud.
class TuyaDisconnected extends TuyaState {}

/// Estado de falha ou erro ao conectar/sincronizar credenciais da Tuya.
class TuyaError extends TuyaState {
  final String message;
  const TuyaError(this.message);

  @override
  List<Object?> get props => [message];
}

// --- BLoC ---

/// Gerenciador de estado BLoC responsável pelo controle da integração da Tuya Cloud API.
class TuyaBloc extends Bloc<TuyaEvent, TuyaState> {
  final LocalDatabase _localDatabase;
  TuyaCloudRepository? _repository;

  TuyaBloc(this._localDatabase) : super(TuyaInitial()) {
    on<CheckTuyaConnection>(_onCheckConnection);
    on<ConnectTuya>(_onConnect);
    on<DisconnectTuya>(_onDisconnect);
    on<SyncDevices>(_onSyncDevices);
    on<ToggleTuyaDevice>(_onToggleDevice);
    on<SetTuyaDeviceProperty>(_onSetProperty);
  }

  /// Verifica se há credenciais pré-salvas no banco local e tenta conectar automaticamente.
  Future<void> _onCheckConnection(CheckTuyaConnection event, Emitter<TuyaState> emit) async {
    emit(TuyaConnecting());
    try {
      final creds = await _localDatabase.getTuyaCredentials();
      if (creds != null && creds['isConnected'] == true) {
        final clientId = creds['clientId'] as String;
        final clientSecret = creds['clientSecret'] as String;
        final region = creds['region'] as String;

        _repository = TuyaCloudRepository(
          clientId: clientId,
          clientSecret: clientSecret,
          region: region,
        );

        final devices = await _repository!.fetchDevices();
        emit(TuyaConnected(clientId: clientId, region: region, devices: devices));
      } else {
        emit(TuyaDisconnected());
      }
    } catch (e) {
      emit(TuyaError("Erro ao recuperar conexão anterior: ${e.toString()}"));
    }
  }

  /// Tenta validar as novas credenciais inseridas na tela de integração.
  /// 
  /// Se a nuvem autenticar com sucesso, grava na persistência local e atualiza o estado.
  Future<void> _onConnect(ConnectTuya event, Emitter<TuyaState> emit) async {
    emit(TuyaConnecting());
    try {
      // Instancia o repositório com as novas credenciais fornecidas
      print('=== TENTATIVA DE CONEXÃO TUYA BLoC ===');
      print('ID: ${event.clientId}');
      print('Secret (Tamanho): ${event.clientSecret.length} caracteres');
      print('Região: ${event.region}');

      final repo = TuyaCloudRepository(
        clientId: event.clientId,
        clientSecret: event.clientSecret,
        region: event.region,
      );

      // Valida efetuando a autenticação de token
      await repo.authenticate();
      print('Autenticação com a Tuya Cloud concluída com sucesso!');
      final devices = await repo.fetchDevices();
      print('Dispositivos sincronizados da Tuya Cloud: ${devices.length}');

      // Salva com sucesso na base JSON local
      await _localDatabase.saveTuyaCredentials(
        clientId: event.clientId,
        clientSecret: event.clientSecret,
        region: event.region,
        isConnected: true,
      );

      _repository = repo;
      emit(TuyaConnected(clientId: event.clientId, region: event.region, devices: devices));
    } catch (e, s) {
      print('Erro ao tentar conectar Tuya BLoC: $e');
      print('StackTrace: $s');
      // Falha ao conectar: limpa credenciais da tela de status e notifica
      await _localDatabase.clearTuyaCredentials();
      emit(TuyaError(e.toString()));
    }
  }

  /// Remove a integração limpando os arquivos do banco local.
  Future<void> _onDisconnect(DisconnectTuya event, Emitter<TuyaState> emit) async {
    emit(TuyaConnecting());
    await _localDatabase.clearTuyaCredentials();
    _repository = null;
    emit(TuyaDisconnected());
  }

  /// Sincroniza a lista atual de dispositivos obtidos via nuvem da Tuya.
  Future<void> _onSyncDevices(SyncDevices event, Emitter<TuyaState> emit) async {
    if (_repository == null) {
      emit(TuyaDisconnected());
      return;
    }
    emit(TuyaConnecting());
    try {
      final devices = await _repository!.fetchDevices();
      emit(TuyaConnected(
        clientId: _repository!.clientId,
        region: _repository!.region,
        devices: devices,
      ));
    } catch (e) {
      emit(TuyaError("Erro de Sincronização: ${e.toString()}"));
    }
  }

  /// Altera o estado On/Off de um dispositivo e atualiza a UI de forma otimizada.
  Future<void> _onToggleDevice(ToggleTuyaDevice event, Emitter<TuyaState> emit) async {
    final currentState = state;
    if (_repository != null && currentState is TuyaConnected) {
      try {
        await _repository!.toggleDevice(event.deviceId, event.value);
        
        // Atualiza a lista interna localmente de forma otimizada
        final updatedList = currentState.devices.map((device) {
          if (device.id == event.deviceId) {
            final newStatus = Map<String, dynamic>.from(device.status);
            newStatus['switch'] = event.value;
            return TuyaDeviceModel(
              id: device.id,
              name: device.name,
              category: device.category,
              isOnline: device.isOnline,
              status: newStatus,
            );
          }
          return device;
        }).toList();

        emit(TuyaConnected(
          clientId: currentState.clientId,
          region: currentState.region,
          devices: updatedList,
        ));
      } catch (_) {
        // Ignora erros na UI para evitar congelar controles
      }
    }
  }

  /// Altera uma propriedade do dispositivo na nuvem da Tuya e atualiza o estado local.
  Future<void> _onSetProperty(SetTuyaDeviceProperty event, Emitter<TuyaState> emit) async {
    final currentState = state;
    if (_repository != null && currentState is TuyaConnected) {
      try {
        await _repository!.setDeviceProperties(event.deviceId, event.code, event.value);

        final updatedList = currentState.devices.map((device) {
          if (device.id == event.deviceId) {
            final newStatus = Map<String, dynamic>.from(device.status);
            newStatus[event.code] = event.value;
            return TuyaDeviceModel(
              id: device.id,
              name: device.name,
              category: device.category,
              isOnline: device.isOnline,
              status: newStatus,
            );
          }
          return device;
        }).toList();

        emit(TuyaConnected(
          clientId: currentState.clientId,
          region: currentState.region,
          devices: updatedList,
        ));
      } catch (_) {
        // Ignora erros na UI
      }
    }
  }
}
