import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;

/// Classe contendo os dados brutos de um dispositivo retornado pela Tuya Cloud.
class TuyaDeviceModel {
  final String id;
  final String name;
  final String category; // e.g. "kg" (switch), "dj" (light), "ws" (sensor)
  final bool isOnline;
  final Map<String, dynamic> status;

  TuyaDeviceModel({
    required this.id,
    required this.name,
    required this.category,
    required this.isOnline,
    required this.status,
  });

  factory TuyaDeviceModel.fromJson(Map<String, dynamic> json) {
    return TuyaDeviceModel(
      id: json['id'] as String,
      name: json['name'] as String,
      category: (json['category'] as String?) ?? '',
      isOnline: (json['online'] as bool?) ?? true,
      status: Map<String, dynamic>.from(json['status'] as Map? ?? {}),
    );
  }
}

/// Repositório de integração online real com a API Tuya Cloud.
/// 
/// Realiza a autenticação via assinatura HMAC-SHA256 (Padrão Tuya Signature v2),
/// busca a lista de dispositivos na nuvem e envia comandos de controle.
/// Caso chaves mockadas sejam fornecidas, entra em modo híbrido de simulação inteligente.
class TuyaCloudRepository {
  final String clientId;
  final String clientSecret;
  final String region;

  TuyaCloudRepository({
    required this.clientId,
    required this.clientSecret,
    required this.region,
  });

  /// Define o endpoint base com base na região selecionada.
  String get baseUrl {
    switch (region.toLowerCase()) {
      case 'europe':
        return 'https://openapi.tuyaeu.com';
      case 'china':
        return 'https://openapi.tuyacn.com';
      default:
        return 'https://openapi.tuyaus.com';
    }
  }

  String? _accessToken;
  bool get isMock => clientId.startsWith('mock') || clientSecret.startsWith('mock');

  /// Gera um hash SHA256 em formato Hex.
  String _sha256Hex(String content) {
    return sha256.convert(utf8.encode(content)).toString();
  }

  /// Gera assinatura HMAC-SHA256 requerida pela API da Tuya.
  String _hmacSha256(String message, String key) {
    final hmac = Hmac(sha256, utf8.encode(key));
    final digest = hmac.convert(utf8.encode(message));
    return digest.toString().toUpperCase();
  }

  /// Autentica na Tuya Cloud e obtém o Access Token ativo.
  Future<String> authenticate() async {
    if (isMock) {
      await Future.delayed(const Duration(seconds: 1));
      _accessToken = 'mock_access_token_12345';
      return _accessToken!;
    }

    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    const path = '/v1.0/token?grant_type=1';
    
    // Assinatura Tuya v2 para Token
    final stringToSign = 'GET\ne3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855\n\n$path';
    final signString = clientId + timestamp + stringToSign;
    final sign = _hmacSha256(signString, clientSecret);

    final url = Uri.parse('$baseUrl$path');
    final response = await http.get(url, headers: {
      'client_id': clientId,
      'sign': sign,
      't': timestamp,
      'sign_method': 'HMAC-SHA256',
    }).timeout(const Duration(seconds: 10));

    final body = jsonDecode(response.body);
    if (body['success'] == true) {
      _accessToken = body['result']['access_token'] as String;
      return _accessToken!;
    } else {
      throw Exception('Autenticação falhou: ${body['msg']} (Código: ${body['code']})');
    }
  }

  /// Baixa a lista completa de dispositivos da conta da Tuya.
  Future<List<TuyaDeviceModel>> fetchDevices() async {
    if (isMock) {
      await Future.delayed(const Duration(milliseconds: 800));
      return _getMockDevices();
    }

    if (_accessToken == null) {
      await authenticate();
    }

    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    const path = '/v1.0/devices'; // Lista todos os dispositivos vinculados à conta desenvolvedora
    
    final stringToSign = 'GET\ne3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855\n\n$path';
    final signString = clientId + _accessToken! + timestamp + stringToSign;
    final sign = _hmacSha256(signString, clientSecret);

    final url = Uri.parse('$baseUrl$path');
    final response = await http.get(url, headers: {
      'client_id': clientId,
      'access_token': _accessToken!,
      'sign': sign,
      't': timestamp,
      'sign_method': 'HMAC-SHA256',
    }).timeout(const Duration(seconds: 10));

    final body = jsonDecode(response.body);
    if (body['success'] == true) {
      final list = body['result'] as List? ?? [];
      return list.map((item) => TuyaDeviceModel.fromJson(Map<String, dynamic>.from(item as Map))).toList();
    } else {
      // Se falhar devido a token expirado (ex: erro 1010 ou 1024), tenta renovar o token
      if (body['code'] == 1010 || body['code'] == 1024) {
        await authenticate();
        return fetchDevices(); // Tenta novamente de forma recursiva
      }
      throw Exception('Falha ao obter dispositivos: ${body['msg']}');
    }
  }

  /// Envia comando de ligar/desligar para um dispositivo específico da Tuya.
  Future<bool> toggleDevice(String deviceId, bool value) async {
    if (isMock) {
      await Future.delayed(const Duration(milliseconds: 500));
      return true;
    }

    if (_accessToken == null) {
      await authenticate();
    }

    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final path = '/v1.0/devices/$deviceId/commands';
    
    // Comando padrão da Tuya para ligar/desligar
    final bodyData = {
      'commands': [
        {'code': 'switch', 'value': value}
      ]
    };
    final bodyStr = jsonEncode(bodyData);
    final bodyHash = _sha256Hex(bodyStr);

    final stringToSign = 'POST\n$bodyHash\n\n$path';
    final signString = clientId + _accessToken! + timestamp + stringToSign;
    final sign = _hmacSha256(signString, clientSecret);

    final url = Uri.parse('$baseUrl$path');
    final response = await http.post(url, 
      headers: {
        'client_id': clientId,
        'access_token': _accessToken!,
        'sign': sign,
        't': timestamp,
        'sign_method': 'HMAC-SHA256',
        'Content-Type': 'application/json',
      },
      body: bodyStr,
    ).timeout(const Duration(seconds: 10));

    final body = jsonDecode(response.body);
    if (body['success'] == true) {
      return true;
    } else {
      throw Exception('Falha ao enviar comando para o dispositivo: ${body['msg']}');
    }
  }

  /// Envia propriedades específicas (ex: abrir/fechar cortinas, ajustar brilho).
  Future<bool> setDeviceProperties(String deviceId, String code, dynamic value) async {
    if (isMock) {
      await Future.delayed(const Duration(milliseconds: 400));
      return true;
    }

    if (_accessToken == null) {
      await authenticate();
    }

    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final path = '/v1.0/devices/$deviceId/commands';

    final bodyData = {
      'commands': [
        {'code': code, 'value': value}
      ]
    };
    final bodyStr = jsonEncode(bodyData);
    final bodyHash = _sha256Hex(bodyStr);

    final stringToSign = 'POST\n$bodyHash\n\n$path';
    final signString = clientId + _accessToken! + timestamp + stringToSign;
    final sign = _hmacSha256(signString, clientSecret);

    final url = Uri.parse('$baseUrl$path');
    final response = await http.post(url, 
      headers: {
        'client_id': clientId,
        'access_token': _accessToken!,
        'sign': sign,
        't': timestamp,
        'sign_method': 'HMAC-SHA256',
        'Content-Type': 'application/json',
      },
      body: bodyStr,
    ).timeout(const Duration(seconds: 10));

    final body = jsonDecode(response.body);
    return body['success'] == true;
  }

  /// Retorna dispositivos simulados padrão caso esteja operando em modo Mock.
  List<TuyaDeviceModel> _getMockDevices() {
    return [
      TuyaDeviceModel(
        id: 'tuya_dev_ac1',
        name: 'Tuya Central AC Floor 1',
        category: 'kt', // kt = ar condicionado (climate)
        isOnline: true,
        status: {'switch': true, 'temp_set': 22.0, 'mode': 'cool', 'temp_current': 22.0},
      ),
      TuyaDeviceModel(
        id: 'tuya_dev_ac2',
        name: 'Tuya Heat Pump Floor 2',
        category: 'kt',
        isOnline: true,
        status: {'switch': true, 'temp_set': 24.0, 'mode': 'cool', 'temp_current': 27.0},
      ),
      TuyaDeviceModel(
        id: 'tuya_dev_plug1',
        name: 'Tuya Smart Plug Washer',
        category: 'kg', // kg = plugue/switch
        isOnline: true,
        status: {'switch': false},
      ),
      TuyaDeviceModel(
        id: 'tuya_dev_light1',
        name: 'Tuya Dimmer Ceiling',
        category: 'dj', // dj = lâmpada/light
        isOnline: true,
        status: {'switch': true, 'bright_value': 800, 'temp_value': 500},
      ),
      TuyaDeviceModel(
        id: 'tuya_dev_curtain',
        name: 'Tuya Curtains Bedroom',
        category: 'cl', // cl = cortinas (curtains)
        isOnline: true,
        status: {'percent_control': 100}, // 100% aberta
      ),
    ];
  }
}
