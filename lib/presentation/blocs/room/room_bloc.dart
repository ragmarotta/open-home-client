import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../core/persistence/local_database.dart';
import '../../../data/repositories/tuya_cloud_repository.dart';

// --- Events ---

/// Classe base abstrata para os eventos do Gerenciador de Cômodos/Espaços.
abstract class RoomEvent extends Equatable {
  const RoomEvent();

  @override
  List<Object?> get props => [];
}

/// Carrega todos os cômodos e compara com a lista atual de dispositivos obtidos da Tuya.
class LoadRoomsEvent extends RoomEvent {
  final List<TuyaDeviceModel> tuyaDevices;

  const LoadRoomsEvent({required this.tuyaDevices});

  @override
  List<Object?> get props => [tuyaDevices];
}

/// Cria um novo cômodo associando-o a um andar.
class CreateRoomEvent extends RoomEvent {
  final String name;
  final int floor;

  const CreateRoomEvent({required this.name, required this.floor});

  @override
  List<Object?> get props => [name, floor];
}

/// Atribui um dispositivo Tuya a um cômodo específico.
class AssignDeviceToRoomEvent extends RoomEvent {
  final String deviceId;
  final String roomId; // Caso vazio, define o dispositivo como não atribuído.

  const AssignDeviceToRoomEvent({required this.deviceId, required this.roomId});

  @override
  List<Object?> get props => [deviceId, roomId];
}

/// Renomeia um dispositivo com um apelido customizado local.
class RenameDeviceEvent extends RoomEvent {
  final String deviceId;
  final String customName;

  const RenameDeviceEvent({required this.deviceId, required this.customName});

  @override
  List<Object?> get props => [deviceId, customName];
}

// --- States ---

/// Classe base abstrata para os estados do Gerenciador de Cômodos.
abstract class RoomState extends Equatable {
  const RoomState();

  @override
  List<Object?> get props => [];
}

/// Estado inicial.
class RoomInitial extends RoomState {}

/// Estado de carregamento do banco de dados local.
class RoomLoading extends RoomState {}

/// Estado contendo os cômodos cadastrados, apelidos e lista de produtos sem sala.
class RoomLoaded extends RoomState {
  final List<CustomRoom> rooms;
  final Map<String, String> deviceNames;
  final List<TuyaDeviceModel> unassignedDevices;

  const RoomLoaded({
    required this.rooms,
    required this.deviceNames,
    required this.unassignedDevices,
  });

  @override
  List<Object?> get props => [rooms, deviceNames, unassignedDevices];
}

/// Estado de erro no gerenciamento de salas.
class RoomError extends RoomState {
  final String message;
  const RoomError(this.message);

  @override
  List<Object?> get props => [message];
}

// --- BLoC ---

/// Gerenciador de estado BLoC responsável pela criação e organização dos cômodos e seus dispositivos.
class RoomBloc extends Bloc<RoomEvent, RoomState> {
  final LocalDatabase _localDatabase;
  List<TuyaDeviceModel> _cachedTuyaDevices = [];

  RoomBloc(this._localDatabase) : super(RoomInitial()) {
    on<LoadRoomsEvent>(_onLoadRooms);
    on<CreateRoomEvent>(_onCreateRoom);
    on<AssignDeviceToRoomEvent>(_onAssignDevice);
    on<RenameDeviceEvent>(_onRenameDevice);
  }

  /// Carrega os cômodos do banco local e separa os dispositivos Tuya não atribuídos.
  Future<void> _onLoadRooms(LoadRoomsEvent event, Emitter<RoomState> emit) async {
    _cachedTuyaDevices = event.tuyaDevices;
    emit(RoomLoading());
    try {
      final rooms = await _localDatabase.getRooms();
      final names = await _localDatabase.getDeviceNames();

      // Mapeia todos os IDs atribuídos a algum cômodo
      final assignedIds = <String>{};
      for (var r in rooms) {
        assignedIds.addAll(r.deviceIds);
      }

      // Filtra os dispositivos da Tuya que não estão em nenhuma sala
      final unassigned = event.tuyaDevices
          .where((dev) => !assignedIds.contains(dev.id))
          .toList();

      emit(RoomLoaded(
        rooms: rooms,
        deviceNames: names,
        unassignedDevices: unassigned,
      ));
    } catch (e) {
      emit(RoomError(e.toString()));
    }
  }

  /// Cria um novo cômodo customizado no banco JSON e recarrega.
  Future<void> _onCreateRoom(CreateRoomEvent event, Emitter<RoomState> emit) async {
    try {
      final rooms = await _localDatabase.getRooms();
      final newRoom = CustomRoom(
        id: 'room_${DateTime.now().millisecondsSinceEpoch}',
        name: event.name,
        floor: event.floor,
        deviceIds: const [],
      );
      rooms.add(newRoom);
      await _localDatabase.saveRooms(rooms);

      // Dispara recarga
      add(LoadRoomsEvent(tuyaDevices: _cachedTuyaDevices));
    } catch (e) {
      emit(RoomError("Erro ao criar cômodo: ${e.toString()}"));
    }
  }

  /// Transfere um dispositivo de seu cômodo atual (ou não atribuído) para uma nova sala.
  Future<void> _onAssignDevice(AssignDeviceToRoomEvent event, Emitter<RoomState> emit) async {
    try {
      final rooms = await _localDatabase.getRooms();

      // Remove de qualquer cômodo onde já estivesse atribuído
      final updatedRooms = rooms.map((r) {
        final list = List<String>.from(r.deviceIds)..remove(event.deviceId);
        
        // Adiciona à sala alvo se o ID coincidir
        if (r.id == event.roomId) {
          list.add(event.deviceId);
        }
        return r.copyWith(deviceIds: list);
      }).toList();

      await _localDatabase.saveRooms(updatedRooms);

      // Dispara recarga
      add(LoadRoomsEvent(tuyaDevices: _cachedTuyaDevices));
    } catch (e) {
      emit(RoomError("Erro ao vincular dispositivo: ${e.toString()}"));
    }
  }

  /// Grava o apelido de um dispositivo na base persistente e atualiza.
  Future<void> _onRenameDevice(RenameDeviceEvent event, Emitter<RoomState> emit) async {
    try {
      await _localDatabase.saveDeviceName(event.deviceId, event.customName);

      // Dispara recarga
      add(LoadRoomsEvent(tuyaDevices: _cachedTuyaDevices));
    } catch (e) {
      emit(RoomError("Erro ao renomear dispositivo: ${e.toString()}"));
    }
  }
}
