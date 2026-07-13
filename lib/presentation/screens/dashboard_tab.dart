import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/theme/app_theme.dart';
import '../../core/localization/app_localizations.dart';
import '../blocs/device/device_bloc.dart';
import '../blocs/climate/climate_bloc.dart';
import '../../domain/entities/smart_device.dart';
import 'room_control_screen.dart';
import 'settings_screen.dart';

/// Guia de Painel de Controle (Dashboard).
/// 
/// Apresenta o status térmico geral da casa, controle de andares e um grid
/// contendo os dispositivos ativos e salas disponíveis no andar selecionado.
class DashboardTab extends StatefulWidget {
  const DashboardTab({super.key});

  @override
  State<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab> {
  // Controle de andar atualmente selecionado (1 para Térreo, 2 para Superior)
  int _selectedFloor = 1;

  @override
  void initState() {
    super.initState();
    // Dispara a carga de dispositivos e dados climáticos ao iniciar
    context.read<DeviceBloc>().add(LoadDevices(_selectedFloor));
    context.read<ClimateBloc>().add(LoadClimate());
  }

  /// Gerencia a troca de andar e recarrega os dispositivos correspondentes.
  void _onFloorChanged(int floor) {
    setState(() {
      _selectedFloor = floor;
    });
    context.read<DeviceBloc>().add(LoadDevices(floor));
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título do Painel com botão de configurações
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                context.translate('dashboard'),
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              // Botão de Configurações de Toque Grande (>=48dp)
              IconButton(
                padding: const EdgeInsets.all(12),
                iconSize: 26,
                icon: const Icon(Icons.settings_outlined, color: AppTheme.accentCyan),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SettingsScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Card de Status Térmico Geral da Casa
          _buildThermalStatusCard(),
          const SizedBox(height: 20),

          // Botões Segmentados para alternar entre os andares (Térreo / Superior)
          Center(
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: SegmentedButton<int>(
                segments: <ButtonSegment<int>>[
                  ButtonSegment<int>(
                    value: 1,
                    label: Text(context.translate('floor_1')),
                    icon: const Icon(Icons.home_outlined),
                  ),
                  ButtonSegment<int>(
                    value: 2,
                    label: Text(context.translate('floor_2')),
                    icon: const Icon(Icons.apartment_outlined),
                  ),
                ],
                selected: {_selectedFloor},
                onSelectionChanged: (Set<int> newSelection) {
                  _onFloorChanged(newSelection.first);
                },
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Seção de Cômodos do Andar Atual
          Text(
            context.translate('rooms'),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),

          // Carrossel Horizontal de Cômodos
          _buildRoomsHorizontalList(),
          const SizedBox(height: 24),

          // Seção de Dispositivos Rápidos do Andar
          Text(
            context.translate('active_devices'),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),

          // Grid de cards de dispositivos ativos
          _buildDevicesGrid(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  /// Constrói o painel térmico geral, recuperando as temperaturas via ClimateBloc.
  Widget _buildThermalStatusCard() {
    return BlocBuilder<ClimateBloc, ClimateState>(
      builder: (context, state) {
        double floor1Temp = 22.0;
        double floor2Temp = 27.0;
        bool isLoading = state is ClimateLoading;

        if (state is ClimateLoaded) {
          floor1Temp = state.floorTemperatures[1] ?? 22.0;
          floor2Temp = state.floorTemperatures[2] ?? 27.0;
        }

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.thermostat, color: AppTheme.accentCyan),
                    const SizedBox(width: 8),
                    Text(
                      context.translate('thermal_status'),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: AppTheme.textPrimary,
                          ),
                    ),
                    if (isLoading) ...[
                      const Spacer(),
                      const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppTheme.accentCyan,
                        ),
                      ),
                    ]
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    // Status Térmico do Andar 1
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.darkBg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF202638)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              context.translate('floor_1'),
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppTheme.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Text(
                                  '${floor1Temp.toStringAsFixed(0)}°C',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.green.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      context.translate('comfortable'),
                                      style: const TextStyle(
                                        color: Colors.greenAccent,
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      textAlign: TextAlign.center,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Status Térmico do Andar 2
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.darkBg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF202638)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              context.translate('floor_2'),
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppTheme.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Text(
                                  '${floor2Temp.toStringAsFixed(0)}°C',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppTheme.warningAmber.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      '${context.translate('warm')} ⚠️',
                                      style: const TextStyle(
                                        color: AppTheme.warningAmber,
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      textAlign: TextAlign.center,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Constrói o carrossel horizontal contendo as salas disponíveis no andar atual.
  Widget _buildRoomsHorizontalList() {
    final floorRooms = _selectedFloor == 1
        ? ['Living Room', 'Kitchen']
        : ['Master Bedroom', 'Office'];

    return SizedBox(
      height: 110,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: floorRooms.length,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final roomName = floorRooms[index];
          // Mapeia chaves de salas para suas respectivas traduções do arquivo de idioma
          final displayName = roomName == 'Living Room'
              ? context.translate('living_room')
              : roomName == 'Kitchen'
                  ? context.translate('kitchen')
                  : roomName == 'Master Bedroom'
                      ? context.translate('bedroom')
                      : context.translate('office');

          return InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => RoomControlScreen(roomName: roomName),
                ),
              );
            },
            borderRadius: BorderRadius.circular(16),
            child: Ink(
              width: 150,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppTheme.darkSurface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF202638)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(
                    roomName == 'Living Room'
                        ? Icons.weekend_outlined
                        : roomName == 'Kitchen'
                            ? Icons.soup_kitchen_outlined
                            : roomName == 'Master Bedroom'
                                ? Icons.bed_outlined
                                : Icons.work_outline,
                    color: AppTheme.accentIndigo,
                    size: 28,
                  ),
                  Text(
                    displayName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// Constrói o grid contendo todos os dispositivos ativos cadastrados no andar.
  Widget _buildDevicesGrid() {
    return BlocBuilder<DeviceBloc, DeviceState>(
      builder: (context, state) {
        if (state is DeviceLoading) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: CircularProgressIndicator(color: AppTheme.accentCyan),
            ),
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
          final devices = state.devices;
          if (devices.isEmpty) {
            return Center(
              child: Text(
                context.translate('no_devices'),
                style: const TextStyle(color: AppTheme.textSecondary),
              ),
            );
          }

          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: devices.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1.3,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemBuilder: (context, index) {
              final device = devices[index];
              bool isOn = false;
              String details = "";
              IconData icon = Icons.power_settings_new;

              if (device is SmartSwitch) {
                isOn = device.isOn;
                details = device.brand;
                icon = device.id.contains('plug')
                    ? Icons.outlet_outlined
                    : Icons.light_outlined;
              } else if (device is SmartLight) {
                isOn = device.isOn;
                details = "${(device.brightness * 100).toStringAsFixed(0)}% ${context.translate('dim')} | ${device.brand}";
                icon = Icons.tungsten;
              }

              final activeColor = isOn ? AppTheme.accentCyan : AppTheme.textSecondary;

              return Card(
                child: InkWell(
                  onTap: () {
                    // Alternação rápida de On/Off de um dispositivo
                    context.read<DeviceBloc>().add(ToggleDeviceEvent(device.id));
                  },
                  onLongPress: () {
                    // Ao segurar, navega para a tela de controle detalhado do cômodo correspondente
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => RoomControlScreen(roomName: device.room),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Icon(icon, color: activeColor, size: 28),
                            Switch(
                              value: isOn,
                              onChanged: (_) {
                                context.read<DeviceBloc>().add(ToggleDeviceEvent(device.id));
                              },
                            ),
                          ],
                        ),
                        const Spacer(),
                        Text(
                          device.name,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          details,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppTheme.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        }

        return const SizedBox.shrink();
      },
    );
  }
}
