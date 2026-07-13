import 'package:equatable/equatable.dart';

class AudioDevice extends Equatable {
  final String id;
  final String name;
  final int floor;
  final bool isSelected;
  final double volume; // 0.0 to 1.0
  final String brand; // e.g. "Chromecast", "Nest"

  const AudioDevice({
    required this.id,
    required this.name,
    required this.floor,
    required this.isSelected,
    required this.volume,
    required this.brand,
  });

  AudioDevice copyWith({
    bool? isSelected,
    double? volume,
  }) {
    return AudioDevice(
      id: id,
      name: name,
      floor: floor,
      isSelected: isSelected ?? this.isSelected,
      volume: volume ?? this.volume,
      brand: brand,
    );
  }

  @override
  List<Object?> get props => [id, name, floor, isSelected, volume, brand];
}

class AudioPlayerState extends Equatable {
  final String nowPlayingTitle;
  final String nowPlayingArtist;
  final bool isPlaying;
  final double progress; // 0.0 to 1.0
  final double masterVolume; // 0.0 to 1.0
  final bool isSynced;

  const AudioPlayerState({
    required this.nowPlayingTitle,
    required this.nowPlayingArtist,
    required this.isPlaying,
    required this.progress,
    required this.masterVolume,
    required this.isSynced,
  });

  AudioPlayerState copyWith({
    String? nowPlayingTitle,
    String? nowPlayingArtist,
    bool? isPlaying,
    double? progress,
    double? masterVolume,
    bool? isSynced,
  }) {
    return AudioPlayerState(
      nowPlayingTitle: nowPlayingTitle ?? this.nowPlayingTitle,
      nowPlayingArtist: nowPlayingArtist ?? this.nowPlayingArtist,
      isPlaying: isPlaying ?? this.isPlaying,
      progress: progress ?? this.progress,
      masterVolume: masterVolume ?? this.masterVolume,
      isSynced: isSynced ?? this.isSynced,
    );
  }

  @override
  List<Object?> get props => [
        nowPlayingTitle,
        nowPlayingArtist,
        isPlaying,
        progress,
        masterVolume,
        isSynced,
      ];
}
