import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/theme/app_theme.dart';
import '../../core/localization/app_localizations.dart';
import '../blocs/settings/settings_bloc.dart';

/// Tela de Configurações do Aplicativo.
/// 
/// Permite alterar o idioma do aplicativo entre Português e Inglês,
/// bem como visualizar e gerenciar o fuso horário padrão (timezone).
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
        title: Text(context.translate('settings')),
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
                      const Divider(color: Color(0xFF202638), height: 1),
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
              fontSize: 16,
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
