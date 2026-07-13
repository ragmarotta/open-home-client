import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/theme/app_theme.dart';
import '../../core/localization/app_localizations.dart';
import '../blocs/climate/climate_bloc.dart';
import '../../domain/entities/climate_device.dart';

/// Guia Central de Clima (Climate Central).
/// 
/// Apresenta o estado dos aparelhos de ar-condicionado central ou bombas de
/// calor da residência, permitindo ligar/desligar, alterar a temperatura alvo
/// com botões incrementais táteis (+/-) e alternar os modos do sistema (Cool, Heat, Fan).
class ClimateTab extends StatefulWidget {
  const ClimateTab({super.key});

  @override
  State<ClimateTab> createState() => _ClimateTabState();
}

class _ClimateTabState extends State<ClimateTab> {
  @override
  void initState() {
    super.initState();
    // Carrega o estado inicial do Clima
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
              '${context.translate('error')}: ${state.message}',
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
                // Título
                Text(
                  context.translate('climate'),
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 16),

                // Lista de termostatos
                _buildThermostatsList(context, climates),
              ],
            ),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  /// Constrói a lista contendo as placas de controle de termostatos.
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
                // Linha superior: Nome e Botão Liga/Desliga
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

                // Exibe controles do termostato apenas se estiver ligado
                if (climate.isOn) ...[
                  Center(
                    child: Column(
                      children: [
                        Text(
                          context.translate('target_temp'),
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppTheme.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Botão Menos (-) com clique otimizado
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
                            // Exibição da temperatura
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
                                  '${context.translate('current_temp')}: ${climate.currentTemperature.toStringAsFixed(0)}°C',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 24),
                            // Botão Mais (+) com clique otimizado
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

                  // Seletor de Modo (COOL, HEAT, FAN)
                  Text(
                    context.translate('system_mode'),
                    style: const TextStyle(
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
                  // Exibição quando desligado
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24.0),
                      child: Text(
                        context.translate('thermostat_off'),
                        style: const TextStyle(
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

  /// Constrói botões circulares táteis de ajuste de temperatura (+/-).
  Widget _buildTempActionButton({required IconData icon, required VoidCallback onPressed}) {
    return Material(
      color: const Color(0xFF202638),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: Container(
          width: 56,
          height: 56,
          alignment: Alignment.center,
          child: Icon(icon, color: Colors.white, size: 24),
        ),
      ),
    );
  }
}
