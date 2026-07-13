import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/theme/app_theme.dart';
import '../blocs/audio/audio_bloc.dart';
import '../../domain/entities/audio_device.dart';

class AudioCentralTab extends StatefulWidget {
  const AudioCentralTab({super.key});

  @override
  State<AudioCentralTab> createState() => _AudioCentralTabState();
}

class _AudioCentralTabState extends State<AudioCentralTab> {
  @override
  void initState() {
    super.initState();
    context.read<AudioBloc>().add(LoadAudio());
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AudioBloc, AudioState>(
      builder: (context, state) {
        if (state is AudioLoading) {
          return const Center(
            child: CircularProgressIndicator(color: AppTheme.accentCyan),
          );
        }

        if (state is AudioError) {
          return Center(
            child: Text(
              'Error: ${state.message}',
              style: const TextStyle(color: AppTheme.warningAmber),
            ),
          );
        }

        if (state is AudioLoaded) {
          final playerState = state.playerState;
          final devices = state.audioDevices;

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(
                  'Multiroom Cast Hub',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 16),

                // Now Playing Audio Player
                _buildAudioPlayerCard(context, playerState),
                const SizedBox(height: 24),

                // Master Volume Section
                _buildMasterVolumeSection(context, playerState),
                const SizedBox(height: 24),

                // Multiroom Selection Checkboxes & Volumes
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Cast Speakers Zones',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    if (playerState.isSynced)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.accentCyan.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: AppTheme.accentCyan, width: 0.5),
                        ),
                        child: const Text(
                          'SYNCED',
                          style: TextStyle(
                            color: AppTheme.accentCyan,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildSpeakerZonesList(context, devices, playerState.isSynced),
                const SizedBox(height: 28),

                // Synchronize Audio Prominent Button
                _buildSyncButton(context, playerState),
                const SizedBox(height: 20),
              ],
            ),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildAudioPlayerCard(BuildContext context, AudioPlayerState playerState) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                // album art mock
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppTheme.accentIndigo.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.accentIndigo, width: 1.5),
                  ),
                  child: const Icon(
                    Icons.music_note,
                    color: AppTheme.accentIndigo,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        playerState.nowPlayingTitle,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        playerState.nowPlayingArtist,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                // Play / Pause Icon
                IconButton(
                  padding: const EdgeInsets.all(12), // Max touch target padding
                  iconSize: 32,
                  icon: Icon(
                    playerState.isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                    color: AppTheme.accentCyan,
                  ),
                  onPressed: () {
                    context.read<AudioBloc>().add(TogglePlayPauseEvent());
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Linear Progress Bar Indicator
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: const LinearProgressIndicator(
                value: 0.42,
                minHeight: 4,
                backgroundColor: Color(0xFF202638),
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.accentCyan),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMasterVolumeSection(BuildContext context, AudioPlayerState playerState) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: AppTheme.darkSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF202638)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Master Cast Volume',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                '${(playerState.masterVolume * 100).toStringAsFixed(0)}%',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.accentCyan,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.volume_down, color: AppTheme.textSecondary),
              Expanded(
                child: Slider(
                  value: playerState.masterVolume,
                  min: 0.0,
                  max: 1.0,
                  onChanged: (newVolume) {
                    context.read<AudioBloc>().add(UpdateMasterVolumeEvent(newVolume));
                  },
                ),
              ),
              const Icon(Icons.volume_up, color: AppTheme.accentCyan),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSpeakerZonesList(BuildContext context, List<AudioDevice> devices, bool isSynced) {
    return Column(
      children: devices.map((device) {
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              children: [
                Row(
                  children: [
                    // Checkbox with minimum 48dp touch target size
                    SizedBox(
                      width: 48,
                      height: 48,
                      child: Checkbox(
                        value: device.isSelected,
                        activeColor: AppTheme.accentCyan,
                        onChanged: isSynced
                            ? null // Cannot toggle selection independently if synced
                            : (val) {
                                context.read<AudioBloc>().add(
                                      ToggleZoneSelectionEvent(device.id),
                                    );
                              },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            device.name,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: device.isSelected ? Colors.white : AppTheme.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Zone: Floor ${device.floor} | ${device.brand}',
                            style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (device.isSelected) ...[
                  const Divider(color: Color(0xFF202638), height: 16),
                  Row(
                    children: [
                      const Icon(Icons.volume_mute, size: 16, color: AppTheme.textSecondary),
                      Expanded(
                        child: Slider(
                          value: device.volume,
                          min: 0.0,
                          max: 1.0,
                          onChanged: isSynced
                              ? null // Volume bound to Master Volume if synced
                              : (newVolume) {
                                  context.read<AudioBloc>().add(
                                        UpdateZoneVolumeEvent(device.id, newVolume),
                                      );
                                },
                        ),
                      ),
                      Text(
                        '${(device.volume * 100).toStringAsFixed(0)}%',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSyncButton(BuildContext context, AudioPlayerState playerState) {
    final synced = playerState.isSynced;
    final color = synced ? AppTheme.warningAmber : AppTheme.accentCyan;
    final label = synced ? 'Unsynchronize Audio Zones' : 'Synchronize Audio Across Floors';
    final icon = synced ? Icons.phonelink_erase : Icons.sync;

    return SizedBox(
      width: double.infinity,
      height: 52, // touch target >= 48
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: color.withOpacity(0.12),
          foregroundColor: color,
          elevation: 0,
          side: BorderSide(color: color, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: () {
          context.read<AudioBloc>().add(SyncAudioAcrossFloorsEvent());
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                synced
                    ? "Audio zones unlinked."
                    : "Audio synchronized across Floors 1 and 2!",
              ),
              duration: const Duration(seconds: 2),
            ),
          );
        },
        icon: Icon(icon),
        label: Text(
          label,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.2,
          ),
        ),
      ),
    );
  }
}
