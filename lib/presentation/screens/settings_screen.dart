import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/theme/app_theme.dart';
import '../../core/localization/app_localizations.dart';
import '../blocs/settings/settings_bloc.dart';
import '../blocs/tuya/tuya_bloc.dart';
import '../blocs/room/room_bloc.dart';
import 'tuya_integration_screen.dart';
import 'room_assignment_screen.dart';
import '../../data/repositories/tuya_cloud_repository.dart';

/// Tela de Configurações do Aplicativo.
/// 
/// Permite alterar o idioma do aplicativo entre Português e Inglês,
/// gerenciar o fuso horário padrão (timezone) e navegar para a integração Tuya Cloud
/// ou para a administração de cômodos (Gerenciador de Espaços).
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  /// Lista de fusos horários simulados para seleção.
  static const List<String> _timezones = [
    'GMT-3 (America/Sao_Paulo)',
    'GMT-5 (America/New_York)',
    'GMT+0 (Europe/London)',
    'GMT+1 (Europe/Paris)',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          context.translate('settings'),
          style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: -0.5),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: BlocBuilder<SettingsBloc, SettingsState>(
        builder: (context, state) {
          final currentLang = state.locale.languageCode;

          return ListView(
            padding: const EdgeInsets.all(16.0),
            physics: const BouncingScrollPhysics(),
            children: [
              // Seção de Integrações Online
              _buildSectionHeader(context, 'Integrações & Espaços'),
              const SizedBox(height: 12),
              Card(
                child: Column(
                  children: [
                    // Opção: Conectar à Tuya Cloud
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      leading: CircleAvatar(
                        backgroundColor: AppTheme.accentCyan.withOpacity(0.12),
                        child: const Icon(Icons.cloud_queue, color: AppTheme.accentCyan),
                      ),
                      title: Text(
                        context.translate('tuya_integration'),
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      subtitle: const Text('Configurar chaves de acesso da Tuya Cloud', style: TextStyle(fontSize: 12)),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.white30),
                      onTap: () {
                        // Navega para a tela de integração Tuya
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const TuyaIntegrationScreen()),
                        );
                      },
                    ),
                    const Divider(color: Colors.white10, height: 1),
                    // Opção: Gerenciador de Espaços (Cômodos)
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      leading: CircleAvatar(
                        backgroundColor: AppTheme.accentIndigo.withOpacity(0.12),
                        child: const Icon(Icons.room_preferences, color: AppTheme.accentIndigo),
                      ),
                      title: Text(
                        context.translate('space_manager'),
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      subtitle: const Text('Criar cômodos e atribuir dispositivos', style: TextStyle(fontSize: 12)),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.white30),
                      onTap: () {
                        // Certifica-se de que a lista de cômodos seja sincronizada com os dispositivos ativos
                        final tuyaState = context.read<TuyaBloc>().state;
                        final devicesList = tuyaState is TuyaConnected ? tuyaState.devices : const <TuyaDeviceModel>[];
                        context.read<RoomBloc>().add(LoadRoomsEvent(tuyaDevices: devicesList));

                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const RoomAssignmentScreen()),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Seção de Idiomas
              _buildSectionHeader(context, context.translate('language')),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Column(
                    children: [
                      // Opção Português
                      _buildRadioTile(
                        context: context,
                        title: context.translate('portuguese'),
                        value: 'pt',
                        groupValue: currentLang,
                        onChanged: (val) {
                          if (val != null) {
                            context.read<SettingsBloc>().add(ChangeLanguageEvent(val));
                          }
                        },
                      ),
                      const Divider(color: Colors.white10, height: 1),
                      // Opção Inglês
                      _buildRadioTile(
                        context: context,
                        title: context.translate('english'),
                        value: 'en',
                        groupValue: currentLang,
                        onChanged: (val) {
                          if (val != null) {
                            context.read<SettingsBloc>().add(ChangeLanguageEvent(val));
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Seção de Fuso Horário
              _buildSectionHeader(context, context.translate('timezone')),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.schedule_outlined, color: AppTheme.accentCyan),
                          SizedBox(width: 8),
                          Text(
                            'Timezone Selection',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Dropdown de Fusos Horários com clique otimizado
                      Container(
                        height: 52, // touch target >= 48dp
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: AppTheme.darkBg,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFF202638)),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: state.timezone,
                            isExpanded: true,
                            dropdownColor: AppTheme.darkSurface,
                            icon: const Icon(Icons.arrow_drop_down, color: AppTheme.accentCyan),
                            items: _timezones.map((tz) {
                              return DropdownMenuItem<String>(
                                value: tz,
                                child: Text(
                                  tz,
                                  style: const TextStyle(
                                    color: AppTheme.textPrimary,
                                    fontSize: 14,
                                  ),
                                ),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                context.read<SettingsBloc>().add(ChangeTimezoneEvent(val));
                              }
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Constrói um cabeçalho simples e elegante para as seções de configurações.
  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppTheme.textSecondary,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }

  /// Constrói um botão de rádio personalizado para selecionar opções de idioma.
  Widget _buildRadioTile({
    required BuildContext context,
    required String title,
    required String value,
    required String groupValue,
    required ValueChanged<String?> onChanged,
  }) {
    return InkWell(
      onTap: () => onChanged(value),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
            // Widget Radio com tamanho de toque de 48dp
            SizedBox(
              width: 48,
              height: 48,
              child: Radio<String>(
                value: value,
                groupValue: groupValue,
                activeColor: AppTheme.accentCyan,
                onChanged: onChanged,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
