import 'dart:convert';
import 'dart:io';

/// Modelo de dados representando um Cômodo Customizado na base de dados.
class CustomRoom {
  final String id;
  final String name;
  final int floor;
  final List<String> deviceIds;

  CustomRoom({
    required this.id,
    required this.name,
    required this.floor,
    required this.deviceIds,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'floor': floor,
        'deviceIds': deviceIds,
      };

  factory CustomRoom.fromJson(Map<String, dynamic> json) {
    return CustomRoom(
      id: json['id'] as String,
      name: json['name'] as String,
      floor: json['floor'] as int,
      deviceIds: List<String>.from(json['deviceIds'] as List? ?? []),
    );
  }

  CustomRoom copyWith({
    String? name,
    int? floor,
    List<String>? deviceIds,
  }) {
    return CustomRoom(
      id: id,
      name: name ?? this.name,
      floor: floor ?? this.floor,
      deviceIds: deviceIds ?? this.deviceIds,
    );
  }
}

/// Banco de dados local leve em formato JSON puro para persistência.
/// 
/// Armazena credenciais da Tuya, configurações de salas e renomeações
/// de dispositivos de forma portável, rápida e totalmente imune a erros nativos de compilador.
class LocalDatabase {
  final File _file = File('open_home_database.json');

  /// Salva as credenciais da Tuya Cloud de forma persistente.
  Future<void> saveTuyaCredentials({
    required String clientId,
    required String clientSecret,
    required String region,
    required bool isConnected,
  }) async {
    final data = await _readJson();
    data['tuya_credentials'] = {
      'clientId': clientId,
      'clientSecret': clientSecret,
      'region': region,
      'isConnected': isConnected,
    };
    await _writeJson(data);
  }

  /// Recupera as credenciais da Tuya Cloud atualmente salvas.
  Future<Map<String, dynamic>?> getTuyaCredentials() async {
    final data = await _readJson();
    return data['tuya_credentials'] as Map<String, dynamic>?;
  }

  /// Limpa as credenciais da Tuya salvas.
  Future<void> clearTuyaCredentials() async {
    final data = await _readJson();
    data.remove('tuya_credentials');
    await _writeJson(data);
  }

  /// Retorna a lista de cômodos customizados persistidos.
  Future<List<CustomRoom>> getRooms() async {
    final data = await _readJson();
    final roomsList = data['rooms'] as List? ?? [];
    return roomsList
        .map((r) => CustomRoom.fromJson(Map<String, dynamic>.from(r as Map)))
        .toList();
  }

  /// Salva ou atualiza a lista completa de cômodos customizados.
  Future<void> saveRooms(List<CustomRoom> rooms) async {
    final data = await _readJson();
    data['rooms'] = rooms.map((r) => r.toJson()).toList();
    await _writeJson(data);
  }

  /// Salva um apelido personalizado para um dispositivo específico.
  Future<void> saveDeviceName(String deviceId, String customName) async {
    final data = await _readJson();
    final names = Map<String, String>.from(data['device_names'] as Map? ?? {});
    names[deviceId] = customName;
    data['device_names'] = names;
    await _writeJson(data);
  }

  /// Retorna o dicionário de apelidos de dispositivos cadastrados.
  Future<Map<String, String>> getDeviceNames() async {
    final data = await _readJson();
    return Map<String, String>.from(data['device_names'] as Map? ?? {});
  }

  /// Helper privado para ler o JSON da base local.
  Future<Map<String, dynamic>> _readJson() async {
    try {
      if (await _file.exists()) {
        final contents = await _file.readAsString();
        if (contents.isNotEmpty) {
          return jsonDecode(contents) as Map<String, dynamic>;
        }
      }
    } catch (_) {
      // Ignora falhas de leitura
    }
    return {};
  }

  /// Helper privado para gravar no JSON da base local de forma atômica.
  Future<void> _writeJson(Map<String, dynamic> data) async {
    try {
      await _file.writeAsString(jsonEncode(data));
    } catch (_) {
      // Ignora falhas de escrita
    }
  }
}
