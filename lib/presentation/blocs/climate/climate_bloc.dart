import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../domain/entities/climate_device.dart';
import '../../../domain/repositories/climate_repository.dart';

// --- Events ---
abstract class ClimateEvent extends Equatable {
  const ClimateEvent();

  @override
  List<Object?> get props => [];
}

class LoadClimate extends ClimateEvent {}

class ToggleClimateEvent extends ClimateEvent {
  final String id;
  const ToggleClimateEvent(this.id);

  @override
  List<Object?> get props => [id];
}

class SetTargetTempEvent extends ClimateEvent {
  final String id;
  final double temperature;
  const SetTargetTempEvent(this.id, this.temperature);

  @override
  List<Object?> get props => [id, temperature];
}

class SetClimateModeEvent extends ClimateEvent {
  final String id;
  final String mode;
  const SetClimateModeEvent(this.id, this.mode);

  @override
  List<Object?> get props => [id, mode];
}

// --- States ---
abstract class ClimateState extends Equatable {
  const ClimateState();

  @override
  List<Object?> get props => [];
}

class ClimateInitial extends ClimateState {}

class ClimateLoading extends ClimateState {}

class ClimateLoaded extends ClimateState {
  final List<ClimateDevice> climates;
  final Map<int, double> floorTemperatures;

  const ClimateLoaded({
    required this.climates,
    required this.floorTemperatures,
  });

  @override
  List<Object?> get props => [climates, floorTemperatures];
}

class ClimateError extends ClimateState {
  final String message;
  const ClimateError(this.message);

  @override
  List<Object?> get props => [message];
}

// --- BLoC ---
class ClimateBloc extends Bloc<ClimateEvent, ClimateState> {
  final ClimateRepository _climateRepository;

  ClimateBloc(this._climateRepository) : super(ClimateInitial()) {
    on<LoadClimate>(_onLoadClimate);
    on<ToggleClimateEvent>(_onToggleClimate);
    on<SetTargetTempEvent>(_onSetTargetTemp);
    on<SetClimateModeEvent>(_onSetClimateMode);
  }

  Future<void> _onLoadClimate(LoadClimate event, Emitter<ClimateState> emit) async {
    emit(ClimateLoading());
    try {
      final climates = await _climateRepository.getClimateDevices();
      final floorTemps = await _climateRepository.getFloorTemperatures();
      emit(ClimateLoaded(climates: climates, floorTemperatures: floorTemps));
    } catch (e) {
      emit(ClimateError(e.toString()));
    }
  }

  Future<void> _onToggleClimate(ToggleClimateEvent event, Emitter<ClimateState> emit) async {
    final currentState = state;
    if (currentState is ClimateLoaded) {
      try {
        final updated = await _climateRepository.toggleClimate(event.id);
        
        final updatedList = currentState.climates.map((c) {
          return c.id == event.id ? updated : c;
        }).toList();

        // Also update floor temperatures accordingly if needed
        final updatedFloorTemps = Map<int, double>.from(currentState.floorTemperatures);
        updatedFloorTemps[updated.floor] = updated.currentTemperature;

        emit(ClimateLoaded(climates: updatedList, floorTemperatures: updatedFloorTemps));
      } catch (e) {
        emit(ClimateError("Failed to toggle climate: $e"));
      }
    }
  }

  Future<void> _onSetTargetTemp(SetTargetTempEvent event, Emitter<ClimateState> emit) async {
    final currentState = state;
    if (currentState is ClimateLoaded) {
      try {
        final updated = await _climateRepository.setTargetTemperature(event.id, event.temperature);
        
        final updatedList = currentState.climates.map((c) {
          return c.id == event.id ? updated : c;
        }).toList();

        emit(ClimateLoaded(climates: updatedList, floorTemperatures: currentState.floorTemperatures));
      } catch (e) {
        emit(ClimateError("Failed to set temperature: $e"));
      }
    }
  }

  Future<void> _onSetClimateMode(SetClimateModeEvent event, Emitter<ClimateState> emit) async {
    final currentState = state;
    if (currentState is ClimateLoaded) {
      try {
        final updated = await _climateRepository.setClimateMode(event.id, event.mode);
        
        final updatedList = currentState.climates.map((c) {
          return c.id == event.id ? updated : c;
        }).toList();

        emit(ClimateLoaded(climates: updatedList, floorTemperatures: currentState.floorTemperatures));
      } catch (e) {
        emit(ClimateError("Failed to set climate mode: $e"));
      }
    }
  }
}
