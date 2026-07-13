import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/theme/app_theme.dart';
import '../../core/localization/app_localizations.dart';
import '../blocs/device/device_bloc.dart';
import '../../domain/entities/smart_device.dart';

/// Tela de Controle de Cômodo Individual.
/// 
/// Apresenta e centraliza todos os controles específicos dos dispositivos de
/// uma determinada sala (ex: Living Room). Combina interruptores Tasmota,
/// plugs inteligentes Tuya e fitas LED NodeMCU sob uma interface unificada e premium.
class RoomControlScreen extends StatelessWidget {
  final String roomName;

  const RoomControlScreen({
    super.key,
    required this.roomName,
  });

  /// Lista de cores selecionadas para controle da fita LED.
  static const List<Map<String, dynamic>> _curatedColors = [
    {'name': 'Indigo', 'value': 0xFF6366F1},
    {'name': 'Cyan', 'value': 0xFF22D3EE},
    {'name': 'Amber', 'value': 0xFFFFB300},
    {'name': 'Sunset', 'value': 0xFFEF4444},
    {'name': 'Emerald', 'value': 0xFF10B981},
    {'name': 'Purple', 'value': 0xFF8B5CF6},
    {'name': 'Rose', 'value': 0xFFEC4899},
  ];

  @override
  Widget build(BuildContext context) {
    // Mapeia o nome do cômodo para a sua tradução localizada
    final displayName = roomName == 'Living Room'
        ? context.translate('living_room')
        : roomName == 'Kitchen'
            ? context.translate('kitchen')
            : roomName == 'Master Bedroom'
                ? context.translate('bedroom')
                : context.translate('office');

    return Scaffold(
      appBar: AppBar(
        title: Text(
          displayName,
          style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: -0.5),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: BlocBuilder<DeviceBloc, DeviceState>(
        builder: (context, state) {
          if (state is DeviceLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.accentCyan),
            );
          }

          if (state is DeviceError) {
            return Center(
              child: Text(
                '${context.translate('error')}: ${state.message}',
                style: const TextStyle(color: AppTheme.warningAmber),
              ),
            );
          }

          if (state is DeviceLoaded) {
            // Filtra os dispositivos da sala correspondente (ignora diferenças de maiúsculas)
            final roomDevices = state.devices
                .where((d) => d.room.toLowerCase() == roomName.toLowerCase())
                .toList();

            if (roomDevices.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.devices_other, size: 64, color: AppTheme.textSecondary),
                    const SizedBox(height: 16),
                    Text(
                      'No devices configured in $displayName.',
                      style: const TextStyle(color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              );
            }

            return Column(
              children: [
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
                    physics: const BouncingScrollPhysics(),
                    itemCount: roomDevices.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final device = roomDevices[index];
                      if (device is SmartLight) {
                        return _buildLightControlCard(context, device);
                      } else if (device is SmartSwitch) {
                        return _buildSwitchControlCard(context, device);
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ),
                // Rodapé de Ações Rápidas de Cena (Cenas Pré-definidas)
                _buildPresetScenesSection(context),
              ],
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  /// Constrói o card de controle para tomadas Tuya ou interruptores Tasmota usando AnimatedContainer.
  Widget _buildSwitchControlCard(BuildContext context, SmartSwitch device) {
    final isTasmota = device.brand.toLowerCase().contains("tasmota");
    final activeColor = device.isOn ? AppTheme.accentCyan : AppTheme.textSecondary;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      decoration: BoxDecoration(
        color: device.isOn ? const Color(0xFF171A26) : AppTheme.inactiveCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: device.isOn ? AppTheme.accentCyan.withOpacity(0.3) : Colors.white.withOpacity(0.04),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                // Ícone animado
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: device.isOn ? AppTheme.accentCyan.withOpacity(0.12) : Colors.white.withOpacity(0.03),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isTasmota ? Icons.light_outlined : Icons.outlet_outlined,
                    color: activeColor,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      device.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isTasmota
                          ? context.translate('tasmota_switch')
                          : context.translate('tuya_plug'),
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            Transform.scale(
              scale: 0.95,
              child: Switch(
                value: device.isOn,
                onChanged: (_) {
                  context.read<DeviceBloc>().add(ToggleDeviceEvent(device.id));
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Constrói o card de controle estendido para Fitas LED NodeMCU (controle de brilho e cores).
  Widget _buildLightControlCard(BuildContext context, SmartLight device) {
    final lightColor = Color(device.colorHex);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      decoration: BoxDecoration(
        color: device.isOn ? const Color(0xFF171720) : AppTheme.inactiveCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: device.isOn ? lightColor.withOpacity(0.3) : Colors.white.withOpacity(0.04),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: device.isOn ? lightColor.withOpacity(0.12) : Colors.white.withOpacity(0.03),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.tungsten_outlined,
                        color: device.isOn ? lightColor : AppTheme.textSecondary,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          device.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          context.translate('nodemcu_strip'),
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Transform.scale(
                  scale: 0.95,
                  child: Switch(
                    value: device.isOn,
                    onChanged: (_) {
                      context.read<DeviceBloc>().add(ToggleDeviceEvent(device.id));
                    },
                  ),
                ),
              ],
            ),

            // Controles de dimmer e cor ativos apenas se o dispositivo estiver ligado
            if (device.isOn) ...[
              const SizedBox(height: 20),
              Text(
                context.translate('dim'),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.light_mode_outlined, size: 20, color: AppTheme.textSecondary),
                  Expanded(
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: lightColor,
                        thumbColor: Colors.white,
                      ),
                      child: Slider(
                        value: device.brightness,
                        min: 0.0,
                        max: 1.0,
                        divisions: 10,
                        onChanged: (newBrightness) {
                          context.read<DeviceBloc>().add(
                                UpdateLightBrightnessEvent(device.id, newBrightness),
                              );
                        },
                      ),
                    ),
                  ),
                  Text(
                    '${(device.brightness * 100).toStringAsFixed(0)}%',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              Text(
                context.translate('color_palette'),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 52,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: _curatedColors.length,
                  separatorBuilder: (context, index) => const SizedBox(width: 10),
                  itemBuilder: (context, index) {
                    final colorMap = _curatedColors[index];
                    final int colorValue = colorMap['value'];
                    final bool isSelected = device.colorHex == colorValue;

                    return GestureDetector(
                      onTap: () {
                        context.read<DeviceBloc>().add(
                              UpdateLightColorEvent(device.id, colorValue),
                            );
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Color(colorValue),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected ? Colors.white : Colors.transparent,
                            width: 3,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: Color(colorValue).withOpacity(0.4),
                                    blurRadius: 10,
                                    spreadRadius: 2,
                                  )
                                ]
                              : [],
                        ),
                        child: isSelected
                            ? const Icon(
                                Icons.check,
                                color: Colors.black,
                                size: 24,
                              )
                            : null,
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Constrói o rodapé contendo os botões de ações rápidas de Cenas (Modo Filme / Leitura).
  Widget _buildPresetScenesSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
      decoration: BoxDecoration(
        color: AppTheme.darkSurface,
        border: Border(
          top: BorderSide(color: Colors.white.withOpacity(0.05), width: 0.5),
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            context.translate('quick_scenes'),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              // Botão Modo Filme
              Expanded(
                child: SizedBox(
                  height: 52,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accentIndigo.withOpacity(0.12),
                      foregroundColor: AppTheme.accentIndigo,
                      elevation: 0,
                      side: const BorderSide(color: Colors.white10, width: 0.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: () {
                      context.read<DeviceBloc>().add(const TriggerPresetSceneEvent("Movie Mode"));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(context.translate('applying_scene')),
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    },
                    icon: const Icon(Icons.movie_outlined),
                    label: Text(
                      context.translate('movie_mode'),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Botão Modo Leitura
              Expanded(
                child: SizedBox(
                  height: 52,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accentCyan.withOpacity(0.12),
                      foregroundColor: AppTheme.accentCyan,
                      elevation: 0,
                      side: const BorderSide(color: Colors.white10, width: 0.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: () {
                      context.read<DeviceBloc>().add(const TriggerPresetSceneEvent("Reading"));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(context.translate('applying_scene')),
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    },
                    icon: const Icon(Icons.menu_book_outlined),
                    label: Text(
                      context.translate('reading'),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
