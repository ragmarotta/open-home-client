import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/theme/app_theme.dart';
import '../../core/localization/app_localizations.dart';
import '../blocs/room/room_bloc.dart';
import '../../core/persistence/local_database.dart';
import '../../data/repositories/tuya_cloud_repository.dart';

/// Tela do Gerenciador de Espaços (Personalização).
/// 
/// Permite ao usuário criar novos cômodos personalizados, associá-los ao
/// Andar 1 ou Andar 2, renomear dispositivos e atribuir/vincular dispositivos
/// importados da Tuya Cloud aos cômodos correspondentes.
class RoomAssignmentScreen extends StatelessWidget {
  const RoomAssignmentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          context.translate('space_manager'),
          style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: -0.5),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        actions: [
          // Botão no AppBar para criar cômodo com clique mínimo de 48dp
          IconButton(
            padding: const EdgeInsets.all(12),
            icon: const Icon(Icons.add_home_work_outlined, color: AppTheme.accentCyan),
            onPressed: () => _showCreateRoomDialog(context),
          ),
        ],
      ),
      body: BlocBuilder<RoomBloc, RoomState>(
        builder: (context, state) {
          if (state is RoomLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.accentCyan),
            );
          }

          if (state is RoomError) {
            return Center(
              child: Text(
                '${context.translate('error')}: ${state.message}',
                style: const TextStyle(color: AppTheme.warningAmber),
              ),
            );
          }

          if (state is RoomLoaded) {
            final rooms = state.rooms;
            final unassigned = state.unassignedDevices;
            final names = state.deviceNames;

            return ListView(
              padding: const EdgeInsets.all(16.0),
              physics: const BouncingScrollPhysics(),
              children: [
                // Seção: Cômodos Criados
                Text(
                  context.translate('rooms'),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                if (rooms.isEmpty)
                  _buildEmptyStateCard(context, Icons.home_outlined, 'Nenhum cômodo criado ainda. Clique no "+" no topo para criar.')
                else
                  ...rooms.map((room) => _buildRoomAssignmentCard(context, room, names, rooms)),
                
                const SizedBox(height: 32),

                // Seção: Dispositivos Não Atribuídos
                Text(
                  context.translate('unassigned_devices'),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                if (unassigned.isEmpty)
                  _buildEmptyStateCard(context, Icons.cloud_done_outlined, 'Todos os dispositivos foram atribuídos a cômodos!')
                else
                  ...unassigned.map((device) => _buildUnassignedDeviceCard(context, device, names, rooms)),
              ],
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  /// Constrói o card contendo as informações e dispositivos de um cômodo específico.
  Widget _buildRoomAssignmentCard(
    BuildContext context,
    CustomRoom room,
    Map<String, String> deviceNames,
    List<CustomRoom> allRooms,
  ) {
    // Carrega dispositivos associados a esta sala
    final roomBloc = context.read<RoomBloc>();
    // Obtém o nome localizado do andar
    final floorName = room.floor == 1
        ? context.translate('floor_1')
        : context.translate('floor_2');

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabeçalho do Cômodo
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      room.name,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      floorName,
                      style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                    ),
                  ],
                ),
                const Icon(Icons.meeting_room, color: AppTheme.accentIndigo),
              ],
            ),
            const Divider(color: Colors.white10, height: 24),

            // Dispositivos atribuídos a esta sala
            if (room.deviceIds.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  'Nenhum dispositivo neste cômodo.',
                  style: TextStyle(fontStyle: FontStyle.italic, color: AppTheme.textMuted, fontSize: 13),
                ),
              )
            else
              Column(
                children: room.deviceIds.map((deviceId) {
                  final customName = deviceNames[deviceId] ?? deviceId;
                  
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.darkBg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      title: Text(
                        customName,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      subtitle: Text(
                        'ID: $deviceId',
                        style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Botão Renomear
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, size: 20, color: AppTheme.textSecondary),
                            onPressed: () => _showRenameDeviceDialog(context, deviceId, customName),
                          ),
                          // Botão de Opções / Menu popup
                          PopupMenuButton<String>(
                            icon: const Icon(Icons.more_vert, size: 20, color: AppTheme.textSecondary),
                            color: AppTheme.darkSurface,
                            onSelected: (action) {
                              if (action == 'unassign') {
                                roomBloc.add(AssignDeviceToRoomEvent(deviceId: deviceId, roomId: ''));
                              } else {
                                // Mover para outro cômodo
                                roomBloc.add(AssignDeviceToRoomEvent(deviceId: deviceId, roomId: action));
                              }
                            },
                            itemBuilder: (context) => [
                              ...allRooms.where((r) => r.id != room.id).map((r) {
                                return PopupMenuItem(
                                  value: r.id,
                                  child: Text('Mover para ${r.name}'),
                                );
                              }),
                              PopupMenuItem(
                                value: 'unassign',
                                child: Text(
                                  'Desvincular',
                                  style: TextStyle(color: Colors.redAccent.withOpacity(0.8)),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  /// Constrói o card para um dispositivo Tuya importado que ainda não possui cômodo associado.
  Widget _buildUnassignedDeviceCard(
    BuildContext context,
    TuyaDeviceModel device,
    Map<String, String> deviceNames,
    List<CustomRoom> rooms,
  ) {
    final customName = deviceNames[device.id] ?? device.name;
    final roomBloc = context.read<RoomBloc>();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: Colors.white.withOpacity(0.02),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: Colors.white.withOpacity(0.04),
          child: const Icon(Icons.cloud_download_outlined, color: AppTheme.accentCyan),
        ),
        title: Text(
          customName,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
        ),
        subtitle: Text(
          'Cat: ${device.category} | ID: ${device.id}',
          style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Botão Renomear
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 20, color: AppTheme.textSecondary),
              onPressed: () => _showRenameDeviceDialog(context, device.id, customName),
            ),
            // Menu PopUp para Vincular dispositivo ao cômodo
            PopupMenuButton<String>(
              icon: const Icon(Icons.add_circle_outline, size: 22, color: AppTheme.accentCyan),
              color: AppTheme.darkSurface,
              onSelected: (roomId) {
                roomBloc.add(AssignDeviceToRoomEvent(deviceId: device.id, roomId: roomId));
              },
              itemBuilder: (context) {
                return rooms.map((room) {
                  return PopupMenuItem(
                    value: room.id,
                    child: Text('Vincular a ${room.name}'),
                  );
                }).toList();
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Constrói um indicador elegante de seção vazia (Empty State).
  Widget _buildEmptyStateCard(BuildContext context, IconData icon, String message) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.inactiveCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.04), width: 0.5),
      ),
      child: Column(
        children: [
          Icon(icon, size: 40, color: AppTheme.textMuted),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  /// Abre diálogo modal para cadastrar novo cômodo personalizado.
  void _showCreateRoomDialog(BuildContext context) {
    final nameController = TextEditingController();
    int selectedFloor = 1;
    final roomBloc = context.read<RoomBloc>();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: AppTheme.darkSurface,
              title: const Text('Criar Novo Cômodo', style: TextStyle(fontWeight: FontWeight.bold)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: 'Nome do Cômodo',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<int>(
                    value: selectedFloor,
                    decoration: InputDecoration(
                      labelText: 'Andar',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    dropdownColor: AppTheme.darkSurface,
                    items: const [
                      DropdownMenuItem(value: 1, child: Text('Andar 1 (Térreo)')),
                      DropdownMenuItem(value: 2, child: Text('Andar 2 (Superior)')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          selectedFloor = val;
                        });
                      }
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar', style: TextStyle(color: AppTheme.textSecondary)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentCyan, foregroundColor: Colors.black),
                  onPressed: () {
                    if (nameController.text.trim().isNotEmpty) {
                      roomBloc.add(CreateRoomEvent(
                        name: nameController.text.trim(),
                        floor: selectedFloor,
                      ));
                      Navigator.pop(context);
                    }
                  },
                  child: const Text('Criar', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// Abre diálogo modal para renomear dispositivo Tuya localmente.
  void _showRenameDeviceDialog(BuildContext context, String deviceId, String currentName) {
    final nameController = TextEditingController(text: currentName);
    final roomBloc = context.read<RoomBloc>();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppTheme.darkSurface,
          title: const Text('Renomear Dispositivo', style: TextStyle(fontWeight: FontWeight.bold)),
          content: TextField(
            controller: nameController,
            decoration: InputDecoration(
              labelText: 'Novo Apelido',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar', style: TextStyle(color: AppTheme.textSecondary)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentCyan, foregroundColor: Colors.black),
              onPressed: () {
                if (nameController.text.trim().isNotEmpty) {
                  roomBloc.add(RenameDeviceEvent(
                    deviceId: deviceId,
                    customName: nameController.text.trim(),
                  ));
                  Navigator.pop(context);
                }
              },
              child: const Text('Renomear', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }
}
