import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../domain/entities/smart_device.dart';
import '../../../domain/repositories/device_repository.dart';

// --- Events ---
abstract class DeviceEvent extends Equatable {
  const DeviceEvent();

  @override
  List<Object?> get props => [];
}

class LoadDevices extends DeviceEvent {
  final int floor;
  const LoadDevices(this.floor);

  @override
  List<Object?> get props => [floor];
}

class ToggleDeviceEvent extends DeviceEvent {
  final String id;
  const ToggleDeviceEvent(this.id);

  @override
  List<Object?> get props => [id];
}

class UpdateLightBrightnessEvent extends DeviceEvent {
  final String id;
  final double brightness;
  const UpdateLightBrightnessEvent(this.id, this.brightness);

  @override
  List<Object?> get props => [id, brightness];
}

class UpdateLightColorEvent extends DeviceEvent {
  final String id;
  final int colorHex;
  const UpdateLightColorEvent(this.id, this.colorHex);

  @override
  List<Object?> get props => [id, colorHex];
}

class TriggerPresetSceneEvent extends DeviceEvent {
  final String sceneName;
  const TriggerPresetSceneEvent(this.sceneName);

  @override
  List<Object?> get props => [sceneName];
}

// --- States ---
abstract class DeviceState extends Equatable {
  const DeviceState();

  @override
  List<Object?> get props => [];
}

class DeviceInitial extends DeviceState {}

class DeviceLoading extends DeviceState {}

class DeviceLoaded extends DeviceState {
  final List<SmartDevice> devices;
  final int floor;

  const DeviceLoaded({required this.devices, required this.floor});

  @override
  List<Object?> get props => [devices, floor];
}

class DeviceError extends DeviceState {
  final String message;
  const DeviceError(this.message);

  @override
  List<Object?> get props => [message];
}

// --- BLoC ---
class DeviceBloc extends Bloc<DeviceEvent, DeviceState> {
  final DeviceRepository _deviceRepository;

  DeviceBloc(this._deviceRepository) : super(DeviceInitial()) {
    on<LoadDevices>(_onLoadDevices);
    on<ToggleDeviceEvent>(_onToggleDevice);
    on<UpdateLightBrightnessEvent>(_onUpdateLightBrightness);
    on<UpdateLightColorEvent>(_onUpdateLightColor);
    on<TriggerPresetSceneEvent>(_onTriggerPresetScene);
  }

  Future<void> _onLoadDevices(LoadDevices event, Emitter<DeviceState> emit) async {
    emit(DeviceLoading());
    try {
      final devices = await _deviceRepository.getDevicesByFloor(event.floor);
      emit(DeviceLoaded(devices: devices, floor: event.floor));
    } catch (e) {
      emit(DeviceError(e.toString()));
    }
  }

  Future<void> _onToggleDevice(ToggleDeviceEvent event, Emitter<DeviceState> emit) async {
    final currentState = state;
    if (currentState is DeviceLoaded) {
      try {
        // Optimistic UI updates could be done, but we'll await mock delay
        final updated = await _deviceRepository.toggleDevice(event.id);
        
        final updatedList = currentState.devices.map((device) {
          return device.id == event.id ? updated : device;
        }).toList();
        
        emit(DeviceLoaded(devices: updatedList, floor: currentState.floor));
      } catch (e) {
        emit(DeviceError("Failed to toggle device: $e"));
      }
    }
  }

  Future<void> _onUpdateLightBrightness(UpdateLightBrightnessEvent event, Emitter<DeviceState> emit) async {
    final currentState = state;
    if (currentState is DeviceLoaded) {
      try {
        final updated = await _deviceRepository.updateLightBrightness(event.id, event.brightness);
        
        final updatedList = currentState.devices.map((device) {
          return device.id == event.id ? updated : device;
        }).toList();
        
        emit(DeviceLoaded(devices: updatedList, floor: currentState.floor));
      } catch (e) {
        emit(DeviceError("Failed to update brightness: $e"));
      }
    }
  }

  Future<void> _onUpdateLightColor(UpdateLightColorEvent event, Emitter<DeviceState> emit) async {
    final currentState = state;
    if (currentState is DeviceLoaded) {
      try {
        final updated = await _deviceRepository.updateLightColor(event.id, event.colorHex);
        
        final updatedList = currentState.devices.map((device) {
          return device.id == event.id ? updated : device;
        }).toList();
        
        emit(DeviceLoaded(devices: updatedList, floor: currentState.floor));
      } catch (e) {
        emit(DeviceError("Failed to update color: $e"));
      }
    }
  }

  Future<void> _onTriggerPresetScene(TriggerPresetSceneEvent event, Emitter<DeviceState> emit) async {
    final currentState = state;
    if (currentState is DeviceLoaded) {
      emit(DeviceLoading());
      try {
        // Simulate local latency of scene orchestration
        await Future.delayed(const Duration(milliseconds: 700));

        List<SmartDevice> updatedDevices = List.from(currentState.devices);

        if (event.sceneName.toLowerCase() == "movie mode") {
          // Movie Mode logic:
          // 1. Tasmota ceiling light: OFF
          // 2. NodeMCU RGB LED Strip: ON, Brightness 0.2, Color Dark Blue (0xFF0000FF)
          // 3. Tuya smart plug (media center): ON
          updatedDevices = currentState.devices.map((device) {
            if (device.id == 'sw_tasmota_living' && device is SmartSwitch) {
              return device.copyWith(isOn: false);
            } else if (device.id == 'light_nodemcu_living' && device is SmartLight) {
              return device.copyWith(isOn: true, brightness: 0.2, colorHex: 0xFF0A1931);
            } else if (device.id == 'plug_tuya_living' && device is SmartSwitch) {
              return device.copyWith(isOn: true);
            }
            return device;
          }).toList();
        } else if (event.sceneName.toLowerCase() == "reading") {
          // Reading Scene logic:
          // 1. Tasmota ceiling light: ON
          // 2. NodeMCU RGB LED Strip: ON, Brightness 0.9, Color Warm Amber (0xFFFFB300)
          // 3. Tuya smart plug: OFF
          updatedDevices = currentState.devices.map((device) {
            if (device.id == 'sw_tasmota_living' && device is SmartSwitch) {
              return device.copyWith(isOn: true);
            } else if (device.id == 'light_nodemcu_living' && device is SmartLight) {
              return device.copyWith(isOn: true, brightness: 0.9, colorHex: 0xFFFFB300);
            } else if (device.id == 'plug_tuya_living' && device is SmartSwitch) {
              return device.copyWith(isOn: false);
            }
            return device;
          }).toList();
        }

        emit(DeviceLoaded(devices: updatedDevices, floor: currentState.floor));
      } catch (e) {
        emit(DeviceError("Failed to trigger scene: $e"));
      }
    }
  }
}
