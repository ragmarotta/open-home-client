import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../domain/entities/monitoring_metrics.dart';
import '../../../domain/repositories/monitoring_repository.dart';

// --- Events ---
abstract class MonitoringEvent extends Equatable {
  const MonitoringEvent();

  @override
  List<Object?> get props => [];
}

class LoadMonitoring extends MonitoringEvent {}

class UpdateEnergyMetricsEvent extends MonitoringEvent {
  final EnergyMetrics metrics;
  const UpdateEnergyMetricsEvent(this.metrics);

  @override
  List<Object?> get props => [metrics];
}

// --- States ---
abstract class MonitoringState extends Equatable {
  const MonitoringState();

  @override
  List<Object?> get props => [];
}

class MonitoringInitial extends MonitoringState {}

class MonitoringLoading extends MonitoringState {}

class MonitoringLoaded extends MonitoringState {
  final EnergyMetrics energyMetrics;
  final List<PresenceSensor> presenceSensors;

  const MonitoringLoaded({
    required this.energyMetrics,
    required this.presenceSensors,
  });

  @override
  List<Object?> get props => [energyMetrics, presenceSensors];
}

class MonitoringError extends MonitoringState {
  final String message;
  const MonitoringError(this.message);

  @override
  List<Object?> get props => [message];
}

// --- BLoC ---
class MonitoringBloc extends Bloc<MonitoringEvent, MonitoringState> {
  final MonitoringRepository _monitoringRepository;
  StreamSubscription<EnergyMetrics>? _energySubscription;

  MonitoringBloc(this._monitoringRepository) : super(MonitoringInitial()) {
    on<LoadMonitoring>(_onLoadMonitoring);
    on<UpdateEnergyMetricsEvent>(_onUpdateEnergyMetrics);
  }

  Future<void> _onLoadMonitoring(LoadMonitoring event, Emitter<MonitoringState> emit) async {
    emit(MonitoringLoading());
    try {
      final energy = await _monitoringRepository.getEnergyMetrics();
      final presence = await _monitoringRepository.getPresenceSensors();
      
      // Cancel previous stream subscription if any
      await _energySubscription?.cancel();
      
      // Start listening to the continuous flow of energy metrics
      _energySubscription = _monitoringRepository.streamEnergyMetrics().listen(
        (metrics) {
          add(UpdateEnergyMetricsEvent(metrics));
        },
      );

      emit(MonitoringLoaded(energyMetrics: energy, presenceSensors: presence));
    } catch (e) {
      emit(MonitoringError(e.toString()));
    }
  }

  void _onUpdateEnergyMetrics(UpdateEnergyMetricsEvent event, Emitter<MonitoringState> emit) {
    final currentState = state;
    if (currentState is MonitoringLoaded) {
      emit(MonitoringLoaded(
        energyMetrics: event.metrics,
        presenceSensors: currentState.presenceSensors,
      ));
    }
  }

  @override
  Future<void> close() {
    _energySubscription?.cancel();
    return super.close();
  }
}
