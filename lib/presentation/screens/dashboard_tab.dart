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
/// Apresenta o status térmico geral da casa (em formato cápsula elegante),
/// alternador de andares animado e o grid de dispositivos ativos com transição suave.
class DashboardTab extends StatefulWidget {
  const DashboardTab({super.key});

  @override
  State<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab> {
  // Controle de andar selecionado (1 para Térreo, 2 para Superior)
  int _selectedFloor = 1;

  @override
  void initState() {
    super.initState();
    // Dispara a busca inicial de dados
    context.read<DeviceBloc>().add(LoadDevices(_selectedFloor));
    context.read<ClimateBloc>().add(LoadClimate());
  }

  /// Altera o andar selecionado e recarrega os dispositivos correspondentes.
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
          // Título do Painel com botão de configurações premium
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                context.translate('dashboard'),
                style: Theme.of(context).textTheme.headlineMedium,
              ),
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

          // Cabeçalho térmico no formato cápsula elegante
          _buildThermalStatusCard(),
          const SizedBox(height: 24),

          // Alternador de andares segmentado
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

          // Transição de troca de andar usando AnimatedSwitcher (Deslize + Fade)
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 350),
            transitionBuilder: (Widget child, Animation<double> animation) {
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0.04, 0),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(parent: animation, curve: Curves.easeInOut)),
                  child: child,
                ),
              );
            },
            child: Column(
              key: ValueKey<int>(_selectedFloor),
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Seção de Cômodos
                Text(
                  context.translate('rooms'),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                _buildRoomsHorizontalList(),
                const SizedBox(height: 28),

                // Seção de Dispositivos
                Text(
                  context.translate('active_devices'),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                _buildDevicesGrid(),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  /// Constrói o cabeçalho térmico no formato de uma cápsula elegante.
  Widget _buildThermalStatusCard() {
    return BlocBuilder<ClimateBloc, ClimateState>(
      builder: (context, state) {
        double floor1Temp = 22.0;
        double floor2Temp = 27.0;

        if (state is ClimateLoaded) {
          floor1Temp = state.floorTemperatures[1] ?? 22.0;
          floor2Temp = state.floorTemperatures[2] ?? 27.0;
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(
            color: AppTheme.darkSurface,
            borderRadius: BorderRadius.circular(30), // Formato cápsula
            border: Border.all(color: Colors.white.withOpacity(0.05), width: 0.5),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Resumo Andar 1
              Row(
                children: [
                  const Icon(Icons.thermostat, color: AppTheme.accentCyan, size: 20),
                  const SizedBox(width: 6),
                  Text(
                    '${context.translate('floor_1').split(' ').first}: ',
                    style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                  ),
                  Text(
                    '${floor1Temp.toStringAsFixed(0)}°C',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      context.translate('comfortable'),
                      style: const TextStyle(color: Colors.greenAccent, fontSize: 8, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              // Divisor vertical elegante
              Container(
                height: 16,
                width: 1,
                color: Colors.white10,
              ),
              // Resumo Andar 2
              Row(
                children: [
                  Text(
                    '${context.translate('floor_2').split(' ').first}: ',
                    style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                  ),
                  Text(
                    '${floor2Temp.toStringAsFixed(0)}°C',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.warningAmber.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${context.translate('warm')} ⚠️',
                      style: const TextStyle(color: AppTheme.warningAmber, fontSize: 8, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ],
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
            borderRadius: BorderRadius.circular(20),
            child: Ink(
              width: 150,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: AppTheme.darkSurface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.05), width: 0.5),
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
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                      fontSize: 14,
                      letterSpacing: -0.2,
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

  /// Constrói o grid de dispositivos ativos com AnimatedContainers.
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
              childAspectRatio: 1.25,
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
                icon = Icons.tungsten_outlined;
              }

              // Cores e decorações dinâmicas para a micro-interação
              final activeTextColor = isOn ? Colors.white : AppTheme.textPrimary;
              final activeSubtitleColor = isOn ? Colors.white70 : AppTheme.textMuted;
              final activeIconColor = isOn ? Colors.white : AppTheme.textSecondary;

              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                decoration: isOn
                    ? const BoxDecoration(
                        gradient: AppTheme.activeGradient,
                        borderRadius: BorderRadius.all(Radius.circular(24)),
                        boxShadow: [
                          BoxShadow(
                            color: Color(0x2B6366F1),
                            blurRadius: 12,
                            spreadRadius: 2,
                            offset: Offset(0, 4),
                          )
                        ],
                      )
                    : BoxDecoration(
                        color: AppTheme.inactiveCard,
                        borderRadius: const BorderRadius.all(Radius.circular(24)),
                        border: Border.all(color: Colors.white.withOpacity(0.04), width: 0.5),
                      ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      context.read<DeviceBloc>().add(ToggleDeviceEvent(device.id));
                    },
                    onLongPress: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => RoomControlScreen(roomName: device.room),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(24),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Icon(icon, color: activeIconColor, size: 28),
                              // Switch com padding de clique otimizado
                              Transform.scale(
                                scale: 0.9,
                                child: Switch(
                                  value: isOn,
                                  onChanged: (_) {
                                    context.read<DeviceBloc>().add(ToggleDeviceEvent(device.id));
                                  },
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          Text(
                            device.name,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: activeTextColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            details,
                            style: TextStyle(
                              fontSize: 11,
                              color: activeSubtitleColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
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
