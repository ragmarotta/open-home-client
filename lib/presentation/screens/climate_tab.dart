import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/theme/app_theme.dart';
import '../blocs/climate/climate_bloc.dart';
import '../../domain/entities/climate_device.dart';

class ClimateTab extends StatefulWidget {
  const ClimateTab({super.key});

  @override
  State<ClimateTab> createState() => _ClimateTabState();
}

class _ClimateTabState extends State<ClimateTab> {
  @override
  void initState() {
    super.initState();
    context.read<ClimateBloc>().add(LoadClimate());
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ClimateBloc, ClimateState>(
      builder: (context, state) {
        if (state is ClimateLoading) {
          return const Center(
            child: CircularProgressIndicator(color: AppTheme.accentCyan),
          );
        }

        if (state is ClimateError) {
          return Center(
            child: Text(
              'Error: ${state.message}',
              style: const TextStyle(color: AppTheme.warningAmber),
            ),
          );
        }

        if (state is ClimateLoaded) {
          final climates = state.climates;

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(
                  'Climate Central',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 16),

                // Floor summary
                _buildThermostatsList(context, climates),
              ],
            ),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildThermostatsList(BuildContext context, List<ClimateDevice> climates) {
    return Column(
      children: climates.map((climate) {
        return Card(
          margin: const EdgeInsets.only(bottom: 20),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Info & On/Off
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          climate.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Zone: Floor ${climate.floor} | ${climate.brand}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(
                      height: 48,
                      width: 64,
                      child: Switch(
                        value: climate.isOn,
                        onChanged: (_) {
                          context.read<ClimateBloc>().add(
                                ToggleClimateEvent(climate.id),
                              );
                        },
                      ),
                    ),
                  ],
                ),
                const Divider(color: Color(0xFF202638), height: 32),

                if (climate.isOn) ...[
                  // Thermostat Controls
                  Center(
                    child: Column(
                      children: [
                        const Text(
                          'Target Temperature',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppTheme.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Minus button (>=48dp touch target)
                            _buildTempActionButton(
                              icon: Icons.remove,
                              onPressed: () {
                                context.read<ClimateBloc>().add(
                                      SetTargetTempEvent(
                                        climate.id,
                                        climate.targetTemperature - 0.5,
                                      ),
                                    );
                              },
                            ),
                            const SizedBox(width: 24),
                            // Current reading display
                            Column(
                              children: [
                                Text(
                                  '${climate.targetTemperature.toStringAsFixed(1)}°C',
                                  style: const TextStyle(
                                    fontSize: 36,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    letterSpacing: -1,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Current: ${climate.currentTemperature.toStringAsFixed(0)}°C',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 24),
                            // Plus button
                            _buildTempActionButton(
                              icon: Icons.add,
                              onPressed: () {
                                context.read<ClimateBloc>().add(
                                      SetTargetTempEvent(
                                        climate.id,
                                        climate.targetTemperature + 0.5,
                                      ),
                                    );
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Mode Segmented Control
                  const Text(
                    'System Mode',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: SegmentedButton<String>(
                      segments: const <ButtonSegment<String>>[
                        ButtonSegment<String>(
                          value: 'cool',
                          label: Text('COOL'),
                          icon: Icon(Icons.ac_unit, size: 16),
                        ),
                        ButtonSegment<String>(
                          value: 'heat',
                          label: Text('HEAT'),
                          icon: Icon(Icons.wb_sunny_outlined, size: 16),
                        ),
                        ButtonSegment<String>(
                          value: 'fan',
                          label: Text('FAN'),
                          icon: Icon(Icons.wind_power, size: 16),
                        ),
                      ],
                      selected: {climate.mode},
                      onSelectionChanged: (Set<String> newSelection) {
                        context.read<ClimateBloc>().add(
                              SetClimateModeEvent(
                                climate.id,
                                newSelection.first,
                              ),
                            );
                      },
                    ),
                  ),
                ] else ...[
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 24.0),
                      child: Text(
                        'Thermostat is turned off.',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ),
                ]
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTempActionButton({required IconData icon, required VoidCallback onPressed}) {
    return Material(
      color: const Color(0xFF202638),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: Container(
          width: 56, // >= 48dp
          height: 56,
          alignment: Alignment.center,
          child: Icon(icon, color: Colors.white, size: 24),
        ),
      ),
    );
  }
}
