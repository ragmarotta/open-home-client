import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/theme/app_theme.dart';
import '../blocs/device/device_bloc.dart';
import '../blocs/climate/climate_bloc.dart';
import '../../domain/entities/smart_device.dart';
import 'room_control_screen.dart';

class DashboardTab extends StatefulWidget {
  const DashboardTab({super.key});

  @override
  State<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab> {
  int _selectedFloor = 1;

  @override
  void initState() {
    super.initState();
    // Load initial devices for the floor and climate details
    context.read<DeviceBloc>().add(LoadDevices(_selectedFloor));
    context.read<ClimateBloc>().add(LoadClimate());
  }

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
          // Header title
          Text(
            'Smart Dashboard',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 16),

          // Home Thermal Status Card (Floor 1 & Floor 2)
          _buildThermalStatusCard(),
          const SizedBox(height: 20),

          // Segmented Button to Toggle Floors
          Center(
            child: SizedBox(
              width: double.infinity,
              height: 48, // Min touch target height
              child: SegmentedButton<int>(
                segments: const <ButtonSegment<int>>[
                  ButtonSegment<int>(
                    value: 1,
                    label: Text('FLOOR 1 (Ground)'),
                    icon: Icon(Icons.home_outlined),
                  ),
                  ButtonSegment<int>(
                    value: 2,
                    label: Text('FLOOR 2 (Upper)'),
                    icon: Icon(Icons.apartment_outlined),
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

          // Section Title: Rooms
          Text(
            'Rooms',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),

          // Horizontal list of rooms on this floor
          _buildRoomsHorizontalList(),
          const SizedBox(height: 24),

          // Section Title: Active Devices
          Text(
            'Active Devices',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),

          // Device Grid
          _buildDevicesGrid(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

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
                      'Home Thermal Status',
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
                    // Floor 1 Status
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
                            const Text(
                              'Floor 1',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
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
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    'Comfortable',
                                    style: TextStyle(
                                      color: Colors.greenAccent,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
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
                    // Floor 2 Status
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
                            const Text(
                              'Floor 2',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
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
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppTheme.warningAmber.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Row(
                                    children: [
                                      Text(
                                        'Warm ⚠️',
                                        style: TextStyle(
                                          color: AppTheme.warningAmber,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
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
                    roomName,
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
              'Error: ${state.message}',
              style: const TextStyle(color: AppTheme.warningAmber),
            ),
          );
        }

        if (state is DeviceLoaded) {
          final devices = state.devices;
          if (devices.isEmpty) {
            return const Center(
              child: Text(
                'No devices on this floor.',
                style: TextStyle(color: AppTheme.textSecondary),
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
                details = "${(device.brightness * 100).toStringAsFixed(0)}% Dim | ${device.brand}";
                icon = Icons.tungsten;
              }

              final activeColor = isOn ? AppTheme.accentCyan : AppTheme.textSecondary;

              return Card(
                child: InkWell(
                  onTap: () {
                    // Quick Toggle
                    context.read<DeviceBloc>().add(ToggleDeviceEvent(device.id));
                  },
                  onLongPress: () {
                    // Navigate to Room details of this device
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
