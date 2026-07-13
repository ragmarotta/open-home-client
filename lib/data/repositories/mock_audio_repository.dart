import 'dart:async';
import '../../domain/entities/audio_device.dart';
import '../../domain/repositories/audio_repository.dart';

class MockAudioRepository implements AudioRepository {
  AudioPlayerState _playerState = const AudioPlayerState(
    nowPlayingTitle: "Relax Mix",
    nowPlayingArtist: "Spotify Playlist",
    isPlaying: true,
    progress: 0.35,
    masterVolume: 0.6,
    isSynced: false,
  );

  final List<AudioDevice> _audioDevices = [
    const AudioDevice(
      id: 'chromecast_f1',
      name: 'Chromecast Audio (Floor 1)',
      floor: 1,
      isSelected: true,
      volume: 0.5,
      brand: 'Chromecast',
    ),
    const AudioDevice(
      id: 'nest_f2',
      name: 'Google Nest Mini (Floor 2)',
      floor: 2,
      isSelected: false,
      volume: 0.7,
      brand: 'Nest',
    ),
  ];

  @override
  Future<AudioPlayerState> getPlayerState() async {
    await Future.delayed(const Duration(milliseconds: 400));
    return _playerState;
  }

  @override
  Future<List<AudioDevice>> getAudioDevices() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return List.from(_audioDevices);
  }

  @override
  Future<AudioDevice> toggleDeviceSelection(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final index = _audioDevices.indexWhere((ad) => ad.id == id);
    if (index == -1) throw Exception("Audio device not found");

    final device = _audioDevices[index];
    final updated = device.copyWith(isSelected: !device.isSelected);
    _audioDevices[index] = updated;
    return updated;
  }

  @override
  Future<AudioDevice> updateDeviceVolume(String id, double volume) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final index = _audioDevices.indexWhere((ad) => ad.id == id);
    if (index == -1) throw Exception("Audio device not found");

    final device = _audioDevices[index];
    final updated = device.copyWith(volume: volume);
    _audioDevices[index] = updated;

    // Recalculate average as master if synced
    if (_playerState.isSynced) {
      double total = 0;
      for (var d in _audioDevices) {
        total += d.volume;
      }
      _playerState = _playerState.copyWith(masterVolume: total / _audioDevices.length);
    }

    return updated;
  }

  @override
  Future<AudioPlayerState> updateMasterVolume(double volume) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _playerState = _playerState.copyWith(masterVolume: volume);

    // If audio is synchronized, updating master volume updates all zones
    if (_playerState.isSynced) {
      for (int i = 0; i < _audioDevices.length; i++) {
        _audioDevices[i] = _audioDevices[i].copyWith(volume: volume);
      }
    }

    return _playerState;
  }

  @override
  Future<AudioPlayerState> togglePlayPause() async {
    await Future.delayed(const Duration(milliseconds: 300));
    _playerState = _playerState.copyWith(isPlaying: !_playerState.isPlaying);
    return _playerState;
  }

  @override
  Future<AudioPlayerState> syncAudioAcrossFloors() async {
    await Future.delayed(const Duration(milliseconds: 800));
    final newSyncState = !_playerState.isSynced;
    
    _playerState = _playerState.copyWith(isSynced: newSyncState);

    if (newSyncState) {
      // Sync configurations: make all zones selected and match volume to master
      for (int i = 0; i < _audioDevices.length; i++) {
        _audioDevices[i] = _audioDevices[i].copyWith(
          isSelected: true,
          volume: _playerState.masterVolume,
        );
      }
    }

    return _playerState;
  }
}
