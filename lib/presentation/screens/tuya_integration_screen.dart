import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
                const SizedBox(height: 32),

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
}
