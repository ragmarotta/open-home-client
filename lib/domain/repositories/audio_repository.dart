import '../entities/audio_device.dart';

abstract class AudioRepository {
  Future<AudioPlayerState> getPlayerState();
  Future<List<AudioDevice>> getAudioDevices();
  Future<AudioDevice> toggleDeviceSelection(String id);
  Future<AudioDevice> updateDeviceVolume(String id, double volume);
  Future<AudioPlayerState> updateMasterVolume(double volume);
  Future<AudioPlayerState> togglePlayPause();
  Future<AudioPlayerState> syncAudioAcrossFloors();
}
