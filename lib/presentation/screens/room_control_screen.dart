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
/// plugs inteligentes Tuya e fitas LED NodeMCU sob uma interface unificada.
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
        title: Text(displayName),
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
                    padding: const EdgeInsets.all(16.0),
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

  /// Constrói o card de controle para tomadas Tuya ou interruptores Tasmota.
  Widget _buildSwitchControlCard(BuildContext context, SmartSwitch device) {
    final isTasmota = device.brand.toLowerCase().contains("tasmota");
    final activeColor = device.isOn ? AppTheme.accentCyan : AppTheme.textSecondary;

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: device.isOn ? AppTheme.accentCyan.withOpacity(0.1) : Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isTasmota ? Icons.light_outlined : Icons.outlet_outlined,
                    color: activeColor,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      device.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
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
            SizedBox(
              width: 64,
              height: 48,
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: device.isOn ? Color(device.colorHex).withOpacity(0.1) : Colors.transparent,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.tungsten,
                        color: device.isOn ? Color(device.colorHex) : AppTheme.textSecondary,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          device.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
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
                SizedBox(
                  width: 64,
                  height: 48,
                  child: Switch(
                    value: device.isOn,
                    onChanged: (_) {
                      context.read<DeviceBloc>().add(ToggleDeviceEvent(device.id));
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Controles de dimmer e cor ativos apenas se o dispositivo estiver ligado
            if (device.isOn) ...[
              Text(
                context.translate('dim'),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.light_mode_outlined, size: 20, color: AppTheme.textSecondary),
                  Expanded(
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
              const SizedBox(height: 16),

              Text(
                context.translate('color_palette'),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 52,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: _curatedColors.length,
                  separatorBuilder: (context, index) => const SizedBox(width: 8),
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
                      child: Container(
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
                                    color: Color(colorValue).withOpacity(0.5),
                                    blurRadius: 8,
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
      padding: const EdgeInsets.all(16.0),
      decoration: const BoxDecoration(
        color: AppTheme.darkSurface,
        border: Border(
          top: BorderSide(color: Color(0xFF202638), width: 1),
        ),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
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
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              // Botão Modo Filme
              Expanded(
                child: SizedBox(
                  height: 52,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accentIndigo.withOpacity(0.15),
                      foregroundColor: AppTheme.accentIndigo,
                      elevation: 0,
                      side: const BorderSide(color: AppTheme.accentIndigo, width: 1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
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
                      backgroundColor: AppTheme.accentCyan.withOpacity(0.15),
                      foregroundColor: AppTheme.accentCyan,
                      elevation: 0,
                      side: const BorderSide(color: AppTheme.accentCyan, width: 1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
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
