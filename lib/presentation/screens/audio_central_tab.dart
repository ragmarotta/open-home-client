import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/theme/app_theme.dart';
import '../../core/localization/app_localizations.dart';
import '../blocs/audio/audio_bloc.dart';
import '../../domain/entities/audio_device.dart';

/// Guia Central de Áudio (Multiroom Cast Hub).
/// 
/// Apresenta o player de mídia de forma refinada, controles deslizantes de volume
/// empilhados com ícones dinâmicos que mudam de opacidade de acordo com a intensidade do volume,
/// e um botão de sincronização global com transições premium.
class AudioCentralTab extends StatefulWidget {
  const AudioCentralTab({super.key});

  @override
  State<AudioCentralTab> createState() => _AudioCentralTabState();
}

class _AudioCentralTabState extends State<AudioCentralTab> {
  @override
  void initState() {
    super.initState();
    // Carrega o estado de áudio inicial
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
              '${context.translate('error')}: ${state.message}',
              style: const TextStyle(color: AppTheme.warningAmber),
            ),
          );
        }

        if (state is AudioLoaded) {
          final playerState = state.playerState;
          final devices = state.audioDevices;

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Título da Central de Áudio
                Text(
                  'Multiroom Cast Hub',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 16),

                // Card do Tocando Agora com design elegante e compacto
                _buildAudioPlayerCard(context, playerState),
                const SizedBox(height: 24),

                // Card do Volume Master
                _buildMasterVolumeSection(context, playerState),
                const SizedBox(height: 24),

                // Cabeçalho das Zonas de Som
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      context.translate('speaker_zones'),
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    if (playerState.isSynced)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.accentCyan.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppTheme.accentCyan.withOpacity(0.3), width: 0.5),
                        ),
                        child: Text(
                          context.translate('synced'),
                          style: const TextStyle(
                            color: AppTheme.accentCyan,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),

                // Lista de Caixas de Som Empilhadas
                _buildSpeakerZonesList(context, devices, playerState.isSynced),
                const SizedBox(height: 28),

                // Botão Proeminente de Sincronização Geral
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

  /// Constrói o reprodutor de mídia simulado (exibe álbum, título, progresso e play/pause).
  Widget _buildAudioPlayerCard(BuildContext context, AudioPlayerState playerState) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: AppTheme.darkSurface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.04), width: 0.5),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Arte do Álbum simulada com gradiente e rotação sutil
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF8B5CF6), Color(0xFF6366F1)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x228B5CF6),
                      blurRadius: 8,
                      spreadRadius: 1,
                    )
                  ],
                ),
                child: const Icon(
                  Icons.music_note,
                  color: Colors.white,
                  size: 28,
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
                        letterSpacing: -0.2,
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
              // Botão Play/Pause animado implícito
              IconButton(
                padding: const EdgeInsets.all(12),
                iconSize: 36,
                icon: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    playerState.isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                    key: ValueKey<bool>(playerState.isPlaying),
                    color: AppTheme.accentCyan,
                  ),
                ),
                onPressed: () {
                  context.read<AudioBloc>().add(TogglePlayPauseEvent());
                },
              ),
            ],
          ),
          const SizedBox(height: 18),
          // Barra de progresso linear fina
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: const LinearProgressIndicator(
              value: 0.42,
              minHeight: 4,
              backgroundColor: Colors.white12,
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.accentCyan),
            ),
          ),
        ],
      ),
    );
  }

  /// Constrói a seção de Volume Master (estilo iOS/Apple HomeKit).
  Widget _buildMasterVolumeSection(BuildContext context, AudioPlayerState playerState) {
    // Opacidade dinâmica conforme o volume aumenta
    final double opacity = (playerState.masterVolume).clamp(0.2, 1.0);

    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: AppTheme.inactiveCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.04), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                context.translate('master_volume'),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: -0.2,
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
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.volume_down, color: Colors.white.withOpacity(0.4)),
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
              Icon(
                Icons.volume_up,
                color: AppTheme.accentCyan.withOpacity(opacity),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Constrói a lista com os alto-falantes (Chromecast, Google Nest) e seus respectivos volumes.
  Widget _buildSpeakerZonesList(BuildContext context, List<AudioDevice> devices, bool isSynced) {
    return Column(
      children: devices.map((device) {
        // Opacidade dinâmica do ícone de volume do alto-falante
        final double opacity = (device.volume).clamp(0.2, 1.0);

        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: device.isSelected ? const Color(0xFF161A26) : AppTheme.inactiveCard,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: device.isSelected ? AppTheme.accentCyan.withOpacity(0.25) : Colors.white.withOpacity(0.04),
              width: 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Row(
                  children: [
                    // Checkbox elegante com touch target otimizado
                    SizedBox(
                      width: 48,
                      height: 48,
                      child: Checkbox(
                        value: device.isSelected,
                        activeColor: AppTheme.accentCyan,
                        onChanged: isSynced
                            ? null // Não pode desselecionar se estiver sincronizado
                            : (val) {
                                context.read<AudioBloc>().add(
                                      ToggleZoneSelectionEvent(device.id),
                                    );
                              },
                      ),
                    ),
                    const SizedBox(width: 12),
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
                            style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                // Exibe slider de volume individual se o dispositivo estiver ligado
                if (device.isSelected) ...[
                  const Divider(color: Colors.white10, height: 20),
                  Row(
                    children: [
                      Icon(Icons.volume_mute, size: 18, color: Colors.white.withOpacity(0.4)),
                      Expanded(
                        child: SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            activeTrackColor: AppTheme.accentCyan,
                            thumbColor: Colors.white,
                          ),
                          child: Slider(
                            value: device.volume,
                            min: 0.0,
                            max: 1.0,
                            onChanged: isSynced
                                ? null // Volume travado ao Master se sincronizado
                                : (newVolume) {
                                    context.read<AudioBloc>().add(
                                          UpdateZoneVolumeEvent(device.id, newVolume),
                                        );
                                  },
                          ),
                        ),
                      ),
                      Icon(
                        Icons.volume_up,
                        size: 18,
                        color: AppTheme.accentCyan.withOpacity(opacity),
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

  /// Constrói o botão de sincronização global com design glow sutil se sincronizado.
  Widget _buildSyncButton(BuildContext context, AudioPlayerState playerState) {
    final synced = playerState.isSynced;
    final color = synced ? AppTheme.warningAmber : AppTheme.accentCyan;
    final label = synced ? context.translate('unsync_speakers') : context.translate('sync_speakers');
    final icon = synced ? Icons.phonelink_erase : Icons.sync;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: double.infinity,
      height: 52,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: synced
            ? [
                BoxShadow(
                  color: AppTheme.warningAmber.withOpacity(0.12),
                  blurRadius: 10,
                  spreadRadius: 1,
                )
              ]
            : [],
      ),
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: color.withOpacity(0.12),
          foregroundColor: color,
          elevation: 0,
          side: BorderSide(color: color.withOpacity(0.4), width: 1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        onPressed: () {
          context.read<AudioBloc>().add(SyncAudioAcrossFloorsEvent());
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                synced
                    ? context.translate('speakers_unsynced')
                    : context.translate('speakers_synced'),
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
