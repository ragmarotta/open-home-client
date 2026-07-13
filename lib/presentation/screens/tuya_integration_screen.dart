import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_theme.dart';
import '../../core/localization/app_localizations.dart';
import '../blocs/tuya/tuya_bloc.dart';
import '../blocs/room/room_bloc.dart';
import 'room_assignment_screen.dart';

/// Tela de Integração com a Tuya Cloud.
/// 
/// Permite ao usuário inserir suas credenciais de desenvolvedor (Access ID/Secret)
/// e selecionar o datacenter de conexão regional. Ao conectar com sucesso,
/// sincroniza os dispositivos e redireciona o usuário para a tela de gerenciamento de espaços.
/// Inclui também um guia passo a passo interativo e atalho para o portal Tuya IoT.
class TuyaIntegrationScreen extends StatefulWidget {
  const TuyaIntegrationScreen({super.key});

  @override
  State<TuyaIntegrationScreen> createState() => _TuyaIntegrationScreenState();
}

class _TuyaIntegrationScreenState extends State<TuyaIntegrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _clientIdController = TextEditingController();
  final _clientSecretController = TextEditingController();
  String _selectedRegion = 'Western America';

  static const List<String> _regions = [
    'Western America',
    'Europe',
    'China',
  ];

  @override
  void dispose() {
    _clientIdController.dispose();
    _clientSecretController.dispose();
    super.dispose();
  }

  /// Executa o fluxo de conexão ao disparar o evento [ConnectTuya].
  void _onConnectPressed() {
    if (_formKey.currentState!.validate()) {
      context.read<TuyaBloc>().add(ConnectTuya(
            clientId: _clientIdController.text.trim(),
            clientSecret: _clientSecretController.text.trim(),
            region: _selectedRegion,
          ));
    }
  }

  /// Abre o portal Tuya IoT no navegador do dispositivo de forma segura.
  Future<void> _launchTuyaIotPortal() async {
    final Uri url = Uri.parse('https://iot.tuya.com/');
    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        throw Exception('Could not launch $url');
      }
    } catch (e) {
      debugPrint('Error launching URL: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Não foi possível abrir o navegador. Visite https://iot.tuya.com/'),
            backgroundColor: AppTheme.warningAmber,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.translate('tuya_integration')),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: BlocConsumer<TuyaBloc, TuyaState>(
        listener: (context, state) {
          if (state is TuyaConnected) {
            // Em caso de sucesso, notifica e redireciona para a tela de atribuição de cômodos
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(context.translate('speakers_synced'))),
            );
            
            // Dispara carga inicial dos cômodos usando os dispositivos sincronizados
            context.read<RoomBloc>().add(LoadRoomsEvent(tuyaDevices: state.devices));

            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const RoomAssignmentScreen()),
            );
          } else if (state is TuyaError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: Colors.redAccent),
            );
          }
        },
        builder: (context, state) {
          final isConnecting = state is TuyaConnecting;
          final isConnected = state is TuyaConnected;

          // Se já estiver conectado, preenche os campos com os dados ativos
          if (isConnected && _clientIdController.text.isEmpty) {
            _clientIdController.text = state.clientId;
            _clientSecretController.text = '••••••••••••••••';
            _selectedRegion = state.region;
          }

          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(20.0),
              physics: const BouncingScrollPhysics(),
              children: [
                // Indicador visual de status de nuvem (Glow reativo)
                _buildStatusIndicator(isConnected, isConnecting),
                const SizedBox(height: 32),

                // Card de Credenciais da Nuvem
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.translate('tuya_creds'),
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 16),

                        // Input Access ID
                        TextFormField(
                          controller: _clientIdController,
                          enabled: !isConnecting && !isConnected,
                          decoration: InputDecoration(
                            labelText: context.translate('client_id'),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            prefixIcon: const Icon(Icons.vpn_key_outlined),
                          ),
                          validator: (val) => val == null || val.isEmpty ? context.translate('required_field') : null,
                        ),
                        const SizedBox(height: 16),

                        // Input Access Secret
                        TextFormField(
                          controller: _clientSecretController,
                          enabled: !isConnecting && !isConnected,
                          obscureText: true,
                          decoration: InputDecoration(
                            labelText: context.translate('client_secret'),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            prefixIcon: const Icon(Icons.lock_outline),
                          ),
                          validator: (val) => val == null || val.isEmpty ? context.translate('required_field') : null,
                        ),
                        const SizedBox(height: 16),

                        // Seletor de Região
                        DropdownButtonFormField<String>(
                          value: _selectedRegion,
                          decoration: InputDecoration(
                            labelText: context.translate('region'),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            prefixIcon: const Icon(Icons.public),
                          ),
                          dropdownColor: AppTheme.darkSurface,
                          items: _regions.map((regionName) {
                            return DropdownMenuItem(
                              value: regionName,
                              child: Text(regionName),
                            );
                          }).toList(),
                          onChanged: (isConnecting || isConnected)
                              ? null
                              : (val) {
                                  if (val != null) {
                                    setState(() {
                                      _selectedRegion = val;
                                    });
                                  }
                                },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Botão Primário: Salvar / Conectar ou Desconectar
                if (isConnected)
                  SizedBox(
                    height: 52,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent.withOpacity(0.12),
                        foregroundColor: Colors.redAccent,
                        elevation: 0,
                        side: const BorderSide(color: Colors.redAccent, width: 0.5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: () {
                        context.read<TuyaBloc>().add(DisconnectTuya());
                        _clientIdController.clear();
                        _clientSecretController.clear();
                      },
                      icon: const Icon(Icons.link_off),
                      label: Text(
                        context.translate('disconnect'),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  )
                else
                  SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.accentCyan,
                        foregroundColor: Colors.black,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: isConnecting ? null : _onConnectPressed,
                      child: isConnecting
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2),
                            )
                          : Text(
                              context.translate('save_sync'),
                              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
                            ),
                    ),
                  ),
                const SizedBox(height: 24),

                // Botão "Não possui as chaves? Siga o guia rápido"
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.accentCyan,
                    side: const BorderSide(color: Colors.white10, width: 0.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  icon: const Icon(Icons.help_outline, size: 18),
                  label: const Text(
                    'Não possui as chaves? Siga o guia rápido',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  onPressed: _launchTuyaIotPortal,
                ),
                const SizedBox(height: 24),

                // Componente Passo a Passo (Stepper sutil e minimalista)
                _buildInstructionGuide(),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Constrói o indicador visual de status no topo (Glow / Brilho Reativo).
  Widget _buildStatusIndicator(bool isConnected, bool isConnecting) {
    final statusColor = isConnected
        ? Colors.greenAccent
        : isConnecting
            ? AppTheme.warningAmber
            : Colors.grey;

    final statusText = isConnected
        ? context.translate('connected')
        : isConnecting
            ? 'Sincronizando...'
            : context.translate('disconnected');

    return Center(
      child: Column(
        children: [
          // Círculo com efeito de glow
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.15),
              shape: BoxShape.circle,
              border: Border.all(color: statusColor, width: 2),
              boxShadow: isConnected
                  ? [
                      BoxShadow(
                        color: Colors.greenAccent.withOpacity(0.3),
                        blurRadius: 16,
                        spreadRadius: 2,
                      )
                    ]
                  : [],
            ),
            child: Icon(
              isConnected
                  ? Icons.cloud_done_outlined
                  : isConnecting
                      ? Icons.cloud_sync_outlined
                      : Icons.cloud_off_outlined,
              color: statusColor,
              size: 36,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            statusText,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: statusColor,
            ),
          ),
        ],
      ),
    );
  }

  /// Constrói o painel sutil e minimalista com as instruções passo a passo.
  Widget _buildInstructionGuide() {
    return Container(
      padding: const EdgeInsets.all(18.0),
      decoration: BoxDecoration(
        color: AppTheme.darkSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.04), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.info_outline, color: AppTheme.accentCyan, size: 20),
              const SizedBox(width: 8),
              Text(
                'Como Obter as Chaves da Tuya',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Colors.white,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _buildInstructionStep('1', 'Crie uma conta no portal Tuya IoT.'),
          const Divider(color: Colors.white10, height: 20, indent: 32),
          _buildInstructionStep('2', 'Vá em Cloud > Development e crie um projeto Smart Home.'),
          const Divider(color: Colors.white10, height: 20, indent: 32),
          _buildInstructionStep('3', 'Copie o \'Access ID\' e o \'Access Secret\' e cole nos campos acima.'),
          const Divider(color: Colors.white10, height: 20, indent: 32),
          _buildInstructionStep('4', 'Vincule seu aplicativo Smart Life na aba \'Devices > Link Tuya App Account\'.'),
        ],
      ),
    );
  }

  /// Helper para construir uma linha individual do guia passo a passo.
  Widget _buildInstructionStep(String number, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: AppTheme.accentCyan.withOpacity(0.12),
            shape: BoxShape.circle,
            border: Border.all(color: AppTheme.accentCyan, width: 1.5),
          ),
          alignment: Alignment.center,
          child: Text(
            number,
            style: const TextStyle(
              color: AppTheme.accentCyan,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 13,
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }
}
