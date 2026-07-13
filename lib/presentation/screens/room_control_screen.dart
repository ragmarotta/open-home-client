import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/theme/app_theme.dart';
import '../../core/localization/app_localizations.dart';
import '../blocs/device/device_bloc.dart';
import '../blocs/tuya/tuya_bloc.dart';
import '../blocs/room/room_bloc.dart';
import '../../domain/entities/smart_device.dart';
import '../../data/repositories/tuya_cloud_repository.dart';
import '../../core/persistence/local_database.dart';

/// Tela de Controle de Cômodo Individual.
/// 
/// Apresenta os controles específicos dos dispositivos de uma sala selecionada,
/// suportando tanto dispositivos reais integrados na Tuya Cloud quanto dados locais simulados.
class RoomControlScreen extends StatelessWidget {
  final String roomName; // Pode ser o ID do cômodo ("room_123") ou nome amigável ("Living Room")

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
    final tuyaState = context.watch<TuyaBloc>().state;
    final roomState = context.watch<RoomBloc>().state;

    // Tenta resolver o nome amigável de exibição da sala
    String displayName = roomName;
    if (roomState is RoomLoaded) {
      final room = roomState.rooms.firstWhere((r) => r.id == roomName, orElse: () => roomState.rooms.firstWhere((r) => r.name.toLowerCase() == roomName.toLowerCase(), orElse: () => CustomRoom(id: '', name: roomName, floor: 1, deviceIds: [])));
      displayName = room.name;
    }
    
    // Mapeia traduções padrões se coincidir com termos conhecidos
    if (displayName.toLowerCase() == 'living room') displayName = context.translate('living_room');
    if (displayName.toLowerCase() == 'kitchen') displayName = context.translate('kitchen');
    if (displayName.toLowerCase() == 'master bedroom') displayName = context.translate('bedroom');
    if (displayName.toLowerCase() == 'office') displayName = context.translate('office');

    // Se estiver conectado à Tuya, carrega os dispositivos da Nuvem
    if (tuyaState is TuyaConnected && roomState is RoomLoaded) {
      final room = roomState.rooms.firstWhere(
        (r) => r.id == roomName || r.name.toLowerCase() == roomName.toLowerCase(),
        orElse: () => CustomRoom(id: '', name: roomName, floor: 1, deviceIds: []),
      );

      final roomDevices = tuyaState.devices
          .where((dev) => room.deviceIds.contains(dev.id))
          .toList();

      return Scaffold(
        appBar: AppBar(
          title: Text(displayName, style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: -0.5)),
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
        ),
        body: roomDevices.isEmpty
            ? _buildNoDevicesPlaceholder(context, displayName)
            : ListView.separated(
                padding: const EdgeInsets.all(16.0),
                physics: const BouncingScrollPhysics(),
                itemCount: roomDevices.length,
                separatorBuilder: (context, index) => const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  final dev = roomDevices[index];
                  // Obtém o nome amigável renomeado ou o original
                  final devName = roomState.deviceNames[dev.id] ?? dev.name;
                  
                  if (dev.category == 'kt') {
                    return _buildTuyaClimateCard(context, dev, devName);
                  } else if (dev.category == 'dj') {
                    return _buildTuyaLightCard(context, dev, devName);
                  } else if (dev.category == 'cl') {
                    return _buildTuyaCurtainCard(context, dev, devName);
                  } else {
                    return _buildTuyaSwitchCard(context, dev, devName);
                  }
                },
              ),
      );
    }

    // Se estiver desconectado, reverte para o fallback mockado (DeviceBloc)
    return Scaffold(
      appBar: AppBar(
        title: Text(displayName, style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: -0.5)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: BlocBuilder<DeviceBloc, DeviceState>(
        builder: (context, state) {
          if (state is DeviceLoaded) {
            final roomDevices = state.devices
                .where((d) => d.room.toLowerCase() == roomName.toLowerCase() || d.room.toLowerCase() == displayName.toLowerCase())
                .toList();

            if (roomDevices.isEmpty) {
              return _buildNoDevicesPlaceholder(context, displayName);
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
                _buildPresetScenesSection(context),
              ],
            );
          }
          return const Center(child: CircularProgressIndicator(color: AppTheme.accentCyan));
        },
      ),
    );
  }

  /// Constrói widget placeholder para salas sem dispositivos.
  Widget _buildNoDevicesPlaceholder(BuildContext context, String roomTitle) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.devices_other, size: 64, color: AppTheme.textSecondary),
          const SizedBox(height: 16),
          Text(
            'Nenhum dispositivo configurado em $roomTitle.',
            style: const TextStyle(color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  // ==================== WIDGETS CONTROLE TUYA REAL ====================

  /// Constrói card de controle de interruptor/tomada Tuya Cloud.
  Widget _buildTuyaSwitchCard(BuildContext context, TuyaDeviceModel dev, String displayName) {
    final bool isOn = dev.status['switch'] == true;
    final activeColor = isOn ? AppTheme.accentCyan : AppTheme.textSecondary;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      decoration: BoxDecoration(
        color: isOn ? const Color(0xFF171A26) : AppTheme.inactiveCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isOn ? AppTheme.accentCyan.withOpacity(0.3) : Colors.white.withOpacity(0.04),
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
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isOn ? AppTheme.accentCyan.withOpacity(0.12) : Colors.white.withOpacity(0.03),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.outlet_outlined, color: activeColor, size: 26),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const Text('Tuya Smart Plug', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                  ],
                ),
              ],
            ),
            Transform.scale(
              scale: 0.95,
              child: Switch(
                value: isOn,
                onChanged: (val) {
                  context.read<TuyaBloc>().add(ToggleTuyaDevice(deviceId: dev.id, value: val));
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Constrói card de controle de lâmpadas dimerizáveis Tuya.
  Widget _buildTuyaLightCard(BuildContext context, TuyaDeviceModel dev, String displayName) {
    final bool isOn = dev.status['switch'] == true;
    // O brilho da Tuya costuma variar de 10 a 1000. Normalizamos para 0.0 a 1.0.
    final int rawBright = (dev.status['bright_value'] as num? ?? 10).toInt();
    final double brightness = (rawBright / 1000).clamp(0.0, 1.0);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      decoration: BoxDecoration(
        color: isOn ? const Color(0xFF171720) : AppTheme.inactiveCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isOn ? AppTheme.accentCyan.withOpacity(0.3) : Colors.white.withOpacity(0.04),
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
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: isOn ? AppTheme.accentCyan.withOpacity(0.12) : Colors.white.withOpacity(0.03),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.tungsten_outlined, color: isOn ? AppTheme.accentCyan : AppTheme.textSecondary, size: 26),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayName,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        const Text('Tuya Dimmer Light', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                      ],
                    ),
                  ],
                ),
                Transform.scale(
                  scale: 0.95,
                  child: Switch(
                    value: isOn,
                    onChanged: (val) {
                      context.read<TuyaBloc>().add(ToggleTuyaDevice(deviceId: dev.id, value: val));
                    },
                  ),
                ),
              ],
            ),
            if (isOn) ...[
              const SizedBox(height: 20),
              Text(context.translate('dim'), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.light_mode_outlined, size: 20, color: AppTheme.textSecondary),
                  Expanded(
                    child: Slider(
                      value: brightness,
                      min: 0.0,
                      max: 1.0,
                      onChanged: (newVal) {
                        final int newRaw = (newVal * 1000).round().clamp(10, 1000);
                        context.read<TuyaBloc>().add(SetTuyaDeviceProperty(
                              deviceId: dev.id,
                              code: 'bright_value',
                              value: newRaw,
                            ));
                      },
                    ),
                  ),
                  Text('${(brightness * 100).toStringAsFixed(0)}%', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Constrói card de controle de cortinas Tuya (porcentagem de abertura).
  Widget _buildTuyaCurtainCard(BuildContext context, TuyaDeviceModel dev, String displayName) {
    // Porcentagem de abertura padrão (0 a 100)
    final int percent = (dev.status['percent_control'] as num? ?? 100).toInt();
    final double percentD = percent / 100.0;

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
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.white.withOpacity(0.03),
                    child: const Icon(Icons.blinds_outlined, color: AppTheme.accentCyan),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      const Text('Tuya Smart Curtains', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                    ],
                  ),
                ],
              ),
              Text(
                '${(percentD * 100).toStringAsFixed(0)}% Aberta',
                style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.accentCyan, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              const Icon(Icons.blur_linear_outlined, size: 20, color: AppTheme.textSecondary),
              Expanded(
                child: Slider(
                  value: percentD,
                  min: 0.0,
                  max: 1.0,
                  onChanged: (newVal) {
                    final int newPct = (newVal * 100).round();
                    context.read<TuyaBloc>().add(SetTuyaDeviceProperty(
                          deviceId: dev.id,
                          code: 'percent_control',
                          value: newPct,
                        ));
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Constrói card de controle de ar condicionado/termostatos Tuya.
  Widget _buildTuyaClimateCard(BuildContext context, TuyaDeviceModel dev, String displayName) {
    final bool isOn = dev.status['switch'] == true;
    final double target = (dev.status['temp_set'] as num? ?? 22.0).toDouble();
    final double current = (dev.status['temp_current'] as num? ?? 22.0).toDouble();
    final String mode = (dev.status['mode'] as String?) ?? 'cool';

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      decoration: BoxDecoration(
        color: isOn ? const Color(0xFF161A26) : AppTheme.inactiveCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isOn ? AppTheme.accentCyan.withOpacity(0.25) : Colors.white.withOpacity(0.04),
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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: -0.2),
                    ),
                    const Text('Tuya Smart Climate', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                  ],
                ),
                Transform.scale(
                  scale: 0.95,
                  child: Switch(
                    value: isOn,
                    onChanged: (val) {
                      context.read<TuyaBloc>().add(ToggleTuyaDevice(deviceId: dev.id, value: val));
                    },
                  ),
                ),
              ],
            ),
            const Divider(color: Colors.white10, height: 32),
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 250),
              crossFadeState: isOn ? CrossFadeState.showFirst : CrossFadeState.showSecond,
              firstChild: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Botão Menos (-)
                      Material(
                        color: Colors.white.withOpacity(0.04),
                        shape: const CircleBorder(),
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: () {
                            context.read<TuyaBloc>().add(SetTuyaDeviceProperty(
                                  deviceId: dev.id,
                                  code: 'temp_set',
                                  value: target - 0.5,
                                ));
                          },
                          child: Container(width: 48, height: 48, alignment: Alignment.center, child: const Icon(Icons.remove, color: Colors.white)),
                        ),
                      ),
                      const SizedBox(width: 24),
                      Column(
                        children: [
                          Text('${target.toStringAsFixed(1)}°C', style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w900, color: Colors.white)),
                          Text('Atual: ${current.toStringAsFixed(0)}°C', style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                        ],
                      ),
                      const SizedBox(width: 24),
                      // Botão Mais (+)
                      Material(
                        color: Colors.white.withOpacity(0.04),
                        shape: const CircleBorder(),
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: () {
                            context.read<TuyaBloc>().add(SetTuyaDeviceProperty(
                                  deviceId: dev.id,
                                  code: 'temp_set',
                                  value: target + 0.5,
                                ));
                          },
                          child: Container(width: 48, height: 48, alignment: Alignment.center, child: const Icon(Icons.add, color: Colors.white)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(value: 'cool', label: Text('COOL'), icon: Icon(Icons.ac_unit, size: 16)),
                        ButtonSegment(value: 'heat', label: Text('HEAT'), icon: Icon(Icons.wb_sunny_outlined, size: 16)),
                        ButtonSegment(value: 'fan', label: Text('FAN'), icon: Icon(Icons.wind_power, size: 16)),
                      ],
                      selected: {mode},
                      onSelectionChanged: (newSelection) {
                        context.read<TuyaBloc>().add(SetTuyaDeviceProperty(
                              deviceId: dev.id,
                              code: 'mode',
                              value: newSelection.first,
                            ));
                      },
                    ),
                  ),
                ],
              ),
              secondChild: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: Text(context.translate('thermostat_off'), style: const TextStyle(color: AppTheme.textMuted, fontStyle: FontStyle.italic)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== WIDGETS CONTROLE LOCAL FALLBACK MOCK ====================

  /// Constrói o card de controle para tomadas ou interruptores Mock.
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

  /// Constrói o card de controle estendido para Fitas LED NodeMCU (controle de brilho e cores) Mock.
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

  /// Constrói o rodapé de Cenas pré-definidas para controle Mock.
  Widget _buildPresetScenesSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
      decoration: BoxDecoration(
        color: AppTheme.darkSurface,
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.05), width: 0.5)),
        borderRadius: const BorderRadius.only(topLeft: Radius.circular(28), topRight: Radius.circular(28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            context.translate('quick_scenes'),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary, letterSpacing: -0.2),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 52,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accentIndigo.withOpacity(0.12),
                      foregroundColor: AppTheme.accentIndigo,
                      elevation: 0,
                      side: const BorderSide(color: Colors.white10, width: 0.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: () {
                      context.read<DeviceBloc>().add(const TriggerPresetSceneEvent("Movie Mode"));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(context.translate('applying_scene')), duration: const Duration(seconds: 1)),
                      );
                    },
                    icon: const Icon(Icons.movie_outlined),
                    label: Text(context.translate('movie_mode'), style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 52,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accentCyan.withOpacity(0.12),
                      foregroundColor: AppTheme.accentCyan,
                      elevation: 0,
                      side: const BorderSide(color: Colors.white10, width: 0.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: () {
                      context.read<DeviceBloc>().add(const TriggerPresetSceneEvent("Reading"));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(context.translate('applying_scene')), duration: const Duration(seconds: 1)),
                      );
                    },
                    icon: const Icon(Icons.menu_book_outlined),
                    label: Text(context.translate('reading'), style: const TextStyle(fontWeight: FontWeight.bold)),
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
