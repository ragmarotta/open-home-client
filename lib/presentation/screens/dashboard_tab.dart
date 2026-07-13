import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/theme/app_theme.dart';
import '../../core/localization/app_localizations.dart';
import '../blocs/device/device_bloc.dart';
import '../blocs/climate/climate_bloc.dart';
import '../blocs/tuya/tuya_bloc.dart';
import '../blocs/room/room_bloc.dart';
import '../../domain/entities/smart_device.dart';
import '../../data/repositories/tuya_cloud_repository.dart';
import '../../core/persistence/local_database.dart';
import 'room_control_screen.dart';
import 'settings_screen.dart';

/// Guia de Painel de Controle (Dashboard).
/// 
/// Apresenta o status térmico residencial puxando os dados reais dos sensores
/// de temperatura da Tuya (se conectado) ou dados locais simulados.
/// Organiza dinamicamente as salas e dispositivos de acordo com o andar selecionado.
class DashboardTab extends StatefulWidget {
  const DashboardTab({super.key});

  @override
  State<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab> {
  // Controle do andar ativo (1 para Térreo, 2 para Superior)
  int _selectedFloor = 1;

  @override
  void initState() {
    super.initState();
    // Inicia a verificação de credenciais Tuya salvas
    context.read<TuyaBloc>().add(CheckTuyaConnection());
    // Carrega dados locais simulados como fallback
    context.read<DeviceBloc>().add(LoadDevices(_selectedFloor));
    context.read<ClimateBloc>().add(LoadClimate());
  }

  /// Altera o andar ativo e recarrega os dados correspondentes.
  void _onFloorChanged(int floor) {
    setState(() {
      _selectedFloor = floor;
    });
    context.read<DeviceBloc>().add(LoadDevices(floor));

    // Recarrega cômodos relacionando com a nuvem se estiver conectada
    final tuyaState = context.read<TuyaBloc>().state;
    if (tuyaState is TuyaConnected) {
      context.read<RoomBloc>().add(LoadRoomsEvent(tuyaDevices: tuyaState.devices));
    }
  }

  @override
  Widget build(BuildContext context) {
    // Sincroniza a busca de cômodos assim que o Dashboard é aberto
    final tuyaState = context.watch<TuyaBloc>().state;
    final devicesList = tuyaState is TuyaConnected ? tuyaState.devices : const <TuyaDeviceModel>[];
    context.read<RoomBloc>().add(LoadRoomsEvent(tuyaDevices: devicesList));

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título do Painel com atalho para configurações
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

          // Cabeçalho térmico dinâmico (Tuya Real vs Mock Local)
          _buildDynamicThermalStatus(),
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

          // Renderização animada das salas e dispositivos do andar
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
                // Seção de Cômodos Customizados
                Text(
                  context.translate('rooms'),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                _buildDynamicRoomsList(),
                const SizedBox(height: 28),

                // Seção de Dispositivos Rápidos do Andar
                Text(
                  context.translate('active_devices'),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                _buildDynamicDevicesGrid(tuyaState),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  /// Constrói a leitura de temperatura puxando os dados reais da Tuya ou mock fallback.
  Widget _buildDynamicThermalStatus() {
    return BlocBuilder<TuyaBloc, TuyaState>(
      builder: (context, tuyaState) {
        double floor1Temp = 22.0;
        double floor2Temp = 27.0;
        bool isRealTuya = false;

        // Se estiver conectado à Tuya, tenta ler a temperatura real dos sensores Tuya
        if (tuyaState is TuyaConnected) {
          isRealTuya = true;
          // Tenta encontrar sensores de ar condicionado / clima
          final ac1 = tuyaState.devices.firstWhere(
            (d) => d.id == 'tuya_dev_ac1',
            orElse: () => TuyaDeviceModel(id: '', name: '', category: '', isOnline: false, status: {}),
          );
          final ac2 = tuyaState.devices.firstWhere(
            (d) => d.id == 'tuya_dev_ac2',
            orElse: () => TuyaDeviceModel(id: '', name: '', category: '', isOnline: false, status: {}),
          );

          if (ac1.id.isNotEmpty && ac1.status.containsKey('temp_current')) {
            floor1Temp = (ac1.status['temp_current'] as num).toDouble();
          }
          if (ac2.id.isNotEmpty && ac2.status.containsKey('temp_current')) {
            floor2Temp = (ac2.status['temp_current'] as num).toDouble();
          }
        }

        return BlocBuilder<ClimateBloc, ClimateState>(
          builder: (context, climateState) {
            // Se não for Tuya e o ClimateBloc estiver carregado, lê o mock
            if (!isRealTuya && climateState is ClimateLoaded) {
              floor1Temp = climateState.floorTemperatures[1] ?? 22.0;
              floor2Temp = climateState.floorTemperatures[2] ?? 27.0;
            }

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: BoxDecoration(
                color: AppTheme.darkSurface,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: Colors.white.withOpacity(0.05), width: 0.5),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Leitura Andar 1
                  Row(
                    children: [
                      Icon(Icons.thermostat, color: isRealTuya ? AppTheme.accentCyan : AppTheme.accentCyan.withOpacity(0.6), size: 20),
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
                  // Divisor vertical
                  Container(height: 16, width: 1, color: Colors.white10),
                  // Leitura Andar 2
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
      },
    );
  }

  /// Constrói a lista de cômodos de forma dinâmica a partir do banco de dados local.
  Widget _buildDynamicRoomsList() {
    return BlocBuilder<RoomBloc, RoomState>(
      builder: (context, state) {
        if (state is RoomLoaded) {
          // Filtra cômodos criados pelo usuário que pertencem ao andar selecionado
          final floorRooms = state.rooms.where((r) => r.floor == _selectedFloor).toList();

          if (floorRooms.isEmpty) {
            // Placeholder/Fallback padrão caso o usuário não tenha cadastrado cômodos customizados
            final defaultRooms = _selectedFloor == 1
                ? ['Living Room', 'Kitchen']
                : ['Master Bedroom', 'Office'];

            return SizedBox(
              height: 110,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: defaultRooms.length,
                separatorBuilder: (context, index) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final roomName = defaultRooms[index];
                  final displayName = roomName == 'Living Room'
                      ? context.translate('living_room')
                      : roomName == 'Kitchen'
                          ? context.translate('kitchen')
                          : roomName == 'Master Bedroom'
                              ? context.translate('bedroom')
                              : context.translate('office');

                  return _buildRoomTile(context, roomName, displayName);
                },
              ),
            );
          }

          return SizedBox(
            height: 110,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: floorRooms.length,
              separatorBuilder: (context, index) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final room = floorRooms[index];
                return _buildRoomTile(context, room.id, room.name);
              },
            ),
          );
        }
        return const SizedBox(height: 110);
      },
    );
  }

  /// Helper para desenhar o botão de cada cômodo.
  Widget _buildRoomTile(BuildContext context, String roomId, String displayName) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RoomControlScreen(roomName: roomId),
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
              displayName.toLowerCase().contains('sala') || displayName.toLowerCase().contains('living')
                  ? Icons.weekend_outlined
                  : displayName.toLowerCase().contains('cozinha') || displayName.toLowerCase().contains('kitchen')
                      ? Icons.soup_kitchen_outlined
                      : displayName.toLowerCase().contains('quarto') || displayName.toLowerCase().contains('bedroom')
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
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  /// Constrói o grid de dispositivos ativos puxando os dados da Tuya (se conectada) ou mock.
  Widget _buildDynamicDevicesGrid(TuyaState tuyaState) {
    // Se a Tuya estiver conectada, renderiza o grid com dispositivos reais/nuvem
    if (tuyaState is TuyaConnected) {
      final devices = tuyaState.devices;
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
          // Simula filtro de andar do dispositivo baseado no ID (AC1 = Floor 1, AC2 = Floor 2)
          final isFloor2Device = device.id == 'tuya_dev_ac2' || device.id == 'tuya_dev_curtain';
          final devFloor = isFloor2Device ? 2 : 1;

          if (devFloor != _selectedFloor) {
            return const SizedBox.shrink(); // Filtra dispositivos do outro andar
          }

          final bool isOn = device.status['switch'] == true;
          final String categoryDetails = device.category == 'kt'
              ? 'Ar Condicionado'
              : device.category == 'dj'
                  ? 'Iluminação'
                  : device.category == 'cl'
                      ? 'Cortina'
                      : 'Plugue Inteligente';

          final details = '$categoryDetails | Tuya';
          final icon = device.category == 'kt'
              ? Icons.ac_unit
              : device.category == 'dj'
                  ? Icons.tungsten_outlined
                  : device.category == 'cl'
                      ? Icons.blinds_outlined
                      : Icons.outlet_outlined;

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
                  context.read<TuyaBloc>().add(ToggleTuyaDevice(deviceId: device.id, value: !isOn));
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
                          Transform.scale(
                            scale: 0.9,
                            child: Switch(
                              value: isOn,
                              onChanged: (_) {
                                context.read<TuyaBloc>().add(ToggleTuyaDevice(deviceId: device.id, value: !isOn));
                              },
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Text(
                        device.name,
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: activeTextColor),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        details,
                        style: TextStyle(fontSize: 11, color: activeSubtitleColor),
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

    // Se estiver desconectado, renderiza o grid mock padrão local (DeviceBloc)
    return BlocBuilder<DeviceBloc, DeviceState>(
      builder: (context, state) {
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
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: activeTextColor),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            details,
                            style: TextStyle(fontSize: 11, color: activeSubtitleColor),
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
