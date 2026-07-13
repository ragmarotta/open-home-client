import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../domain/entities/audio_device.dart';
import '../../../domain/repositories/audio_repository.dart';

// --- Events ---
abstract class AudioEvent extends Equatable {
  const AudioEvent();

  @override
  List<Object?> get props => [];
}

class LoadAudio extends AudioEvent {}

class TogglePlayPauseEvent extends AudioEvent {}

class ToggleZoneSelectionEvent extends AudioEvent {
  final String id;
  const ToggleZoneSelectionEvent(this.id);

  @override
  List<Object?> get props => [id];
}

class UpdateZoneVolumeEvent extends AudioEvent {
  final String id;
  final double volume;
  const UpdateZoneVolumeEvent(this.id, this.volume);

  @override
  List<Object?> get props => [id, volume];
}

class UpdateMasterVolumeEvent extends AudioEvent {
  final double volume;
  const UpdateMasterVolumeEvent(this.volume);

  @override
  List<Object?> get props => [volume];
}

class SyncAudioAcrossFloorsEvent extends AudioEvent {}

// --- States ---
abstract class AudioState extends Equatable {
  const AudioState();

  @override
  List<Object?> get props => [];
}

class AudioInitial extends AudioState {}

class AudioLoading extends AudioState {}

class AudioLoaded extends AudioState {
  final AudioPlayerState playerState;
  final List<AudioDevice> audioDevices;

  const AudioLoaded({
    required this.playerState,
    required this.audioDevices,
  });

  @override
  List<Object?> get props => [playerState, audioDevices];
}

class AudioError extends AudioState {
  final String message;
  const AudioError(this.message);

  @override
  List<Object?> get props => [message];
}

// --- BLoC ---
class AudioBloc extends Bloc<AudioEvent, AudioState> {
  final AudioRepository _audioRepository;

  AudioBloc(this._audioRepository) : super(AudioInitial()) {
    on<LoadAudio>(_onLoadAudio);
    on<TogglePlayPauseEvent>(_onTogglePlayPause);
    on<ToggleZoneSelectionEvent>(_onToggleZoneSelection);
    on<UpdateZoneVolumeEvent>(_onUpdateZoneVolume);
    on<UpdateMasterVolumeEvent>(_onUpdateMasterVolume);
    on<SyncAudioAcrossFloorsEvent>(_onSyncAudioAcrossFloors);
  }

  Future<void> _onLoadAudio(LoadAudio event, Emitter<AudioState> emit) async {
    emit(AudioLoading());
    try {
      final playerState = await _audioRepository.getPlayerState();
      final devices = await _audioRepository.getAudioDevices();
      emit(AudioLoaded(playerState: playerState, audioDevices: devices));
    } catch (e) {
      emit(AudioError(e.toString()));
    }
  }

  Future<void> _onTogglePlayPause(TogglePlayPauseEvent event, Emitter<AudioState> emit) async {
    final currentState = state;
    if (currentState is AudioLoaded) {
      try {
        final updatedState = await _audioRepository.togglePlayPause();
        emit(AudioLoaded(playerState: updatedState, audioDevices: currentState.audioDevices));
      } catch (e) {
        emit(AudioError("Playback control failed: $e"));
      }
    }
  }

  Future<void> _onToggleZoneSelection(ToggleZoneSelectionEvent event, Emitter<AudioState> emit) async {
    final currentState = state;
    if (currentState is AudioLoaded) {
      try {
        final updatedDevice = await _audioRepository.toggleDeviceSelection(event.id);
        final updatedDevices = currentState.audioDevices.map((d) {
          return d.id == event.id ? updatedDevice : d;
        }).toList();

        emit(AudioLoaded(playerState: currentState.playerState, audioDevices: updatedDevices));
      } catch (e) {
        emit(AudioError("Zone selection failed: $e"));
      }
    }
  }

  Future<void> _onUpdateZoneVolume(UpdateZoneVolumeEvent event, Emitter<AudioState> emit) async {
    final currentState = state;
    if (currentState is AudioLoaded) {
      try {
        final updatedDevice = await _audioRepository.updateDeviceVolume(event.id, event.volume);
        final updatedDevices = currentState.audioDevices.map((d) {
          return d.id == event.id ? updatedDevice : d;
        }).toList();

        // Also fetch updated master volume in case it was synced
        final refreshedPlayer = await _audioRepository.getPlayerState();

        emit(AudioLoaded(playerState: refreshedPlayer, audioDevices: updatedDevices));
      } catch (e) {
        emit(AudioError("Failed to update volume: $e"));
      }
    }
  }

  Future<void> _onUpdateMasterVolume(UpdateMasterVolumeEvent event, Emitter<AudioState> emit) async {
    final currentState = state;
    if (currentState is AudioLoaded) {
      try {
        final updatedPlayer = await _audioRepository.updateMasterVolume(event.volume);
        final refreshedDevices = await _audioRepository.getAudioDevices();

        emit(AudioLoaded(playerState: updatedPlayer, audioDevices: refreshedDevices));
      } catch (e) {
        emit(AudioError("Failed to update master volume: $e"));
      }
    }
  }

  Future<void> _onSyncAudioAcrossFloors(SyncAudioAcrossFloorsEvent event, Emitter<AudioState> emit) async {
    final currentState = state;
    if (currentState is AudioLoaded) {
      emit(AudioLoading());
      try {
        final updatedPlayer = await _audioRepository.syncAudioAcrossFloors();
        final refreshedDevices = await _audioRepository.getAudioDevices();

        emit(AudioLoaded(playerState: updatedPlayer, audioDevices: refreshedDevices));
      } catch (e) {
        emit(AudioError("Synchronization failed: $e"));
      }
    }
  }
}
