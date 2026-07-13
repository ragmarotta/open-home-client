import 'dart:convert';
import 'dart:io';

/// Interface abstrata para armazenamento persistente das credenciais da Tuya.
abstract class CredentialsStorage {
  Future<void> saveCredentials(String clientId, String clientSecret, String region);
  Future<Map<String, String>?> getCredentials();
  Future<void> clearCredentials();
  Future<void> setConnectionStatus(bool isConnected);
  Future<bool> getConnectionStatus();
}

/// Implementação persistente baseada em arquivo JSON local.
/// 
/// Garante portabilidade total e segurança no ambiente WSL2/Linux/Desktop
/// sem depender de pacotes nativos adicionais que possam falhar em tempo de build.
class LocalFileCredentialsStorage implements CredentialsStorage {
  final File _file = File('tuya_credentials.json');

  @override
  Future<void> saveCredentials(String clientId, String clientSecret, String region) async {
    final data = await _readJson();
    data['clientId'] = clientId;
    data['clientSecret'] = clientSecret;
    data['region'] = region;
    await _writeJson(data);
  }

  @override
  Future<Map<String, String>?> getCredentials() async {
    final data = await _readJson();
    if (data.containsKey('clientId') && data.containsKey('clientSecret')) {
      return {
        'clientId': data['clientId'] as String,
        'clientSecret': data['clientSecret'] as String,
        'region': (data['region'] as String?) ?? 'Western America',
      };
    }
    return null;
  }

  @override
  Future<void> clearCredentials() async {
    final data = await _readJson();
    data.remove('clientId');
    data.remove('clientSecret');
    data.remove('region');
    data['isConnected'] = false;
    await _writeJson(data);
  }

  @override
  Future<void> setConnectionStatus(bool isConnected) async {
    final data = await _readJson();
    data['isConnected'] = isConnected;
    await _writeJson(data);
  }

  @override
  Future<bool> getConnectionStatus() async {
    final data = await _readJson();
    return (data['isConnected'] as bool?) ?? false;
  }

  /// Helper privado para ler o arquivo JSON e retornar um mapa.
  Future<Map<String, dynamic>> _readJson() async {
    try {
      if (await _file.exists()) {
        final contents = await _file.readAsString();
        if (contents.isNotEmpty) {
          return jsonDecode(contents) as Map<String, dynamic>;
        }
      }
    } catch (_) {
      // Ignora falhas e retorna mapa vazio
    }
    return {};
  }

  /// Helper privado para gravar o mapa no arquivo JSON de forma segura.
  Future<void> _writeJson(Map<String, dynamic> data) async {
    try {
      await _file.writeAsString(jsonEncode(data));
    } catch (_) {
      // Ignora falhas de escrita
    }
  }
}
