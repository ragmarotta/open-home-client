import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/theme/app_theme.dart';
import '../../core/localization/app_localizations.dart';
import '../blocs/monitoring/monitoring_bloc.dart';
import '../../domain/entities/monitoring_metrics.dart';

/// Guia de Monitoramento de Energia e Sensores de Presença (Security & Energy).
/// 
/// Apresenta o painel de consumo elétrico trifásico dinâmico (com dados reativos
/// recebidos via Stream do MonitoringBloc) e exibe os sensores de movimento
/// associados aos cômodos (indicando se estão ocupados ou vazios e o horário do último movimento).
class EnergyPresenceTab extends StatefulWidget {
  const EnergyPresenceTab({super.key});

  @override
  State<EnergyPresenceTab> createState() => _EnergyPresenceTabState();
}

class _EnergyPresenceTabState extends State<EnergyPresenceTab> {
  @override
  void initState() {
    super.initState();
    // Dispara o início do monitoramento/stream de energia e presença
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
              '${context.translate('error')}: ${state.message}',
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
                // Título da aba
                Text(
                  context.translate('security'),
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 16),

                // Seção de Consumo Elétrico
                _buildEnergyDashboardCard(context, energy),
                const SizedBox(height: 28),

                // Cabeçalho da Seção de Presença
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      context.translate('room_presence'),
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const Icon(Icons.motion_photos_on_outlined, color: AppTheme.accentCyan, size: 20),
                  ],
                ),
                const SizedBox(height: 12),

                // Lista de cômodos com sensores
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

  /// Constrói o card principal de energia com progresso das fases A, B e C e carga total ativa.
  Widget _buildEnergyDashboardCard(BuildContext context, EnergyMetrics energy) {
    // Escala máxima de carga de 3.0 kW por fase para cálculo percentual da barra
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
                Row(
                  children: [
                    const Icon(Icons.bolt, color: AppTheme.warningAmber),
                    const SizedBox(width: 8),
                    Text(
                      context.translate('energy_consumption'),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                // Pequeno ponto pulsante indicador de fluxo ativo (Live)
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

            // Exibição da carga total ativa geral
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
                  Text(
                    context.translate('active_load'),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Barra de Progresso da Fase A
            _buildPhaseProgressBar(
              phaseName: 'Phase A (Main Home)',
              valueKw: energy.phaseA,
              progressPct: pctA,
              barColor: AppTheme.accentIndigo,
            ),
            const SizedBox(height: 16),

            // Barra de Progresso da Fase B
            _buildPhaseProgressBar(
              phaseName: 'Phase B (Climate/AC)',
              valueKw: energy.phaseB,
              progressPct: pctB,
              barColor: AppTheme.accentCyan,
            ),
            const SizedBox(height: 16),

            // Barra de Progresso da Fase C
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

  /// Helper para desenhar a barra de progresso horizontal e métricas de cada fase elétrica.
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

  /// Constrói a lista dos sensores de movimento das salas com status de Ocupado/Vazio.
  Widget _buildPresenceList(BuildContext context, List<PresenceSensor> sensors) {
    return Column(
      children: sensors.map((sensor) {
        final timeString = _formatTimeAgo(sensor.lastMotionTime);
        // Traduz o nome da sala para o fuso local
        final roomDisplayName = sensor.roomName == 'Living Room'
            ? context.translate('living_room')
            : sensor.roomName == 'Kitchen'
                ? context.translate('kitchen')
                : sensor.roomName == 'Master Bedroom'
                    ? context.translate('bedroom')
                    : context.translate('office');

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: CircleAvatar(
              backgroundColor: sensor.isOccupied
                  ? Colors.green.withOpacity(0.15)
                  : Colors.transparent,
              child: Icon(
                sensor.isOccupied ? Icons.directions_run : Icons.nature_people_outlined,
                color: sensor.isOccupied ? Colors.greenAccent : AppTheme.textSecondary,
              ),
            ),
            title: Text(
              roomDisplayName,
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
                      sensor.isOccupied ? context.translate('occupied') : context.translate('empty'),
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
                  sensor.isOccupied ? context.translate('active_now') : '${context.translate('motion')}: $timeString',
                  style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  /// Calcula a representação textual amigável do tempo decorrido desde o último registro.
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
