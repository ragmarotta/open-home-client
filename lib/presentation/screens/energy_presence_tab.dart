import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/theme/app_theme.dart';
import '../blocs/monitoring/monitoring_bloc.dart';
import '../../domain/entities/monitoring_metrics.dart';

class EnergyPresenceTab extends StatefulWidget {
  const EnergyPresenceTab({super.key});

  @override
  State<EnergyPresenceTab> createState() => _EnergyPresenceTabState();
}

class _EnergyPresenceTabState extends State<EnergyPresenceTab> {
  @override
  void initState() {
    super.initState();
    context.read<MonitoringBloc>().add(LoadMonitoring());
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MonitoringBloc, MonitoringState>(
      builder: (context, state) {
        if (state is MonitoringLoading) {
          return const Center(
            child: CircularProgressIndicator(color: AppTheme.accentCyan),
          );
        }

        if (state is MonitoringError) {
          return Center(
            child: Text(
              'Error: ${state.message}',
              style: const TextStyle(color: AppTheme.warningAmber),
            ),
          );
        }

        if (state is MonitoringLoaded) {
          final energy = state.energyMetrics;
          final presence = state.presenceSensors;

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(
                  'Security & Energy',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 16),

                // Energy Section
                _buildEnergyDashboardCard(context, energy),
                const SizedBox(height: 28),

                // Presence Section Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Room Presence',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const Icon(Icons.motion_photos_on_outlined, color: AppTheme.accentCyan, size: 20),
                  ],
                ),
                const SizedBox(height: 12),

                // Presence list
                _buildPresenceList(context, presence),
                const SizedBox(height: 20),
              ],
            ),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildEnergyDashboardCard(BuildContext context, EnergyMetrics energy) {
    // Let's assume a max load scale of 3.0 kW per phase to scale progress bars
    const maxPhaseLoad = 3.0;
    final double pctA = (energy.phaseA / maxPhaseLoad).clamp(0.0, 1.0);
    final double pctB = (energy.phaseB / maxPhaseLoad).clamp(0.0, 1.0);
    final double pctC = (energy.phaseC / maxPhaseLoad).clamp(0.0, 1.0);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.bolt, color: AppTheme.warningAmber),
                    SizedBox(width: 8),
                    Text(
                      '3-Phase Energy Consumption',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                // Live blink badge
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.redAccent,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Big Total Indicator
            Center(
              child: Column(
                children: [
                  Text(
                    '${energy.totalLoad.toStringAsFixed(2)} kW/h',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.accentCyan,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const Text(
                    'Active Load Total',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Phase A bar
            _buildPhaseProgressBar(
              phaseName: 'Phase A (Main Home)',
              valueKw: energy.phaseA,
              progressPct: pctA,
              barColor: AppTheme.accentIndigo,
            ),
            const SizedBox(height: 16),

            // Phase B bar
            _buildPhaseProgressBar(
              phaseName: 'Phase B (Climate/AC)',
              valueKw: energy.phaseB,
              progressPct: pctB,
              barColor: AppTheme.accentCyan,
            ),
            const SizedBox(height: 16),

            // Phase C bar
            _buildPhaseProgressBar(
              phaseName: 'Phase C (Kitchen/Laundry)',
              valueKw: energy.phaseC,
              progressPct: pctC,
              barColor: AppTheme.warningAmber,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhaseProgressBar({
    required String phaseName,
    required double valueKw,
    required double progressPct,
    required Color barColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              phaseName,
              style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary),
            ),
            Text(
              '${valueKw.toStringAsFixed(2)} kW',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progressPct,
            minHeight: 8,
            backgroundColor: const Color(0xFF202638),
            valueColor: AlwaysStoppedAnimation<Color>(barColor),
          ),
        ),
      ],
    );
  }

  Widget _buildPresenceList(BuildContext context, List<PresenceSensor> sensors) {
    return Column(
      children: sensors.map((sensor) {
        final timeString = _formatTimeAgo(sensor.lastMotionTime);
        final statusColor = sensor.isOccupied ? Colors.emerald : AppTheme.textSecondary;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: CircleAvatar(
              backgroundColor: sensor.isOccupied
                  ? Colors.emerald.withOpacity(0.15)
                  : Colors.transparent,
              child: Icon(
                sensor.isOccupied ? Icons.directions_run : Icons.nature_people_outlined,
                color: sensor.isOccupied ? Colors.greenAccent : AppTheme.textSecondary,
              ),
            ),
            title: Text(
              sensor.roomName,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            subtitle: Text(
              'Floor ${sensor.floor}',
              style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: sensor.isOccupied ? Colors.greenAccent : Colors.grey,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      sensor.isOccupied ? 'Occupied' : 'Empty',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: sensor.isOccupied ? Colors.greenAccent : AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  sensor.isOccupied ? 'Active now' : 'Motion: $timeString',
                  style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  String _formatTimeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) {
      return "just now";
    } else if (diff.inMinutes < 60) {
      return "${diff.inMinutes}m ago";
    } else if (diff.inHours < 24) {
      return "${diff.inHours}h ago";
    } else {
      return "${diff.inDays}d ago";
    }
  }
}
