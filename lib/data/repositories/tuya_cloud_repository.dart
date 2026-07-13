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
  final String iconUrl;
  final String model;
  final String productName;

  TuyaDeviceModel({
    required this.id,
    required this.name,
    required this.category,
    required this.isOnline,
    required this.status,
    required this.iconUrl,
    required this.model,
    required this.productName,
  });

  factory TuyaDeviceModel.fromJson(Map<String, dynamic> json) {
    // 1. Extração inteligente do nome amigável (prioriza customName e depois name)
    final rawCustomName = json['customName'] as String?;
    final rawName = json['name'] as String?;
    final resolvedName = (rawCustomName != null && rawCustomName.trim().isNotEmpty)
        ? rawCustomName.trim()
        : (rawName != null && rawName.trim().isNotEmpty)
            ? rawName.trim()
            : 'Tuya Device';

    // 2. Extração de metadados inteligentes
    final resolvedIcon = (json['icon'] as String?) ?? (json['iconUrl'] as String?) ?? '';
    final resolvedModel = (json['model'] as String?) ?? '';
    final resolvedProduct = (json['productName'] as String?) ?? (json['product_name'] as String?) ?? '';

    // 3. Classificação inteligente da categoria
    final rawCategory = (json['category'] as String?) ?? '';
    final resolvedCategory = _resolveDeviceCategory(resolvedName, resolvedProduct, resolvedModel, rawCategory);

    return TuyaDeviceModel(
      id: json['id'] as String,
      name: resolvedName,
      category: resolvedCategory,
      isOnline: (json['isOnline'] as bool?) ?? (json['online'] as bool?) ?? true,
      status: Map<String, dynamic>.from(json['status'] as Map? ?? {}),
      iconUrl: resolvedIcon,
      model: resolvedModel,
      productName: resolvedProduct,
    );
  }

  /// Classifica o dispositivo em categorias amigáveis do sistema (ex: dj, kt, cl, kg, vacuum, security, sensor)
  static String _resolveDeviceCategory(String name, String productName, String model, String rawCategory) {
    final lowerName = name.toLowerCase();
    final lowerProduct = productName.toLowerCase();
    final lowerModel = model.toLowerCase();
    final cat = rawCategory.toLowerCase();

    // 1. Robô Aspirador (Ex: ABIR-X9, aspirador, robot vacuum, vacuum)
    if (lowerName.contains('aspirador') || 
        lowerName.contains('vacuum') || 
        lowerName.contains('abir') ||
        lowerProduct.contains('aspirador') ||
        lowerProduct.contains('vacuum') ||
        lowerProduct.contains('abir') ||
        cat == 'sd' ||
        cat == 'cnrs') {
      return 'vacuum';
    }

    // 2. Cortina (Curtain / Roller Motor)
    if (cat == 'cl' || 
        lowerName.contains('cortina') || 
        lowerName.contains('curtain') || 
        lowerName.contains('roller motor') ||
        lowerProduct.contains('cortina') ||
        lowerProduct.contains('curtain')) {
      return 'cl'; // cl = Cortina
    }

    // 3. Fechadura / Lock / Portas (Ex: IFR 7000, Fechadura, Porta, jtmspro)
    if (cat == 'jtmspro' || 
        cat == 'ms' || 
        lowerName.contains('porta') || 
        lowerName.contains('fechadura') || 
        lowerName.contains('lock') ||
        lowerName.contains('ifr') ||
        lowerProduct.contains('fechadura') ||
        lowerProduct.contains('lock') ||
        lowerProduct.contains('ifr')) {
      return 'security';
    }

    // 4. Clima / Ar Condicionado (kt, termostato, ac, ar condicionado)
    if (cat == 'kt' || 
        lowerName.contains('ar condicionado') || 
        lowerName.contains('ac') || 
        lowerName.contains('clima') || 
        lowerName.contains('termostato') ||
        lowerProduct.contains('ar condicionado') ||
        lowerProduct.contains('air conditioner')) {
      return 'kt'; // kt = Clima
    }

    // 5. Sensor de Temperatura / Humidade / Presença
    if (cat == 'wsdcg' || 
        cat == 'cg' || 
        lowerName.contains('sensor') || 
        lowerProduct.contains('sensor')) {
      return 'sensor';
    }

    // 6. Lâmpadas / Luzes / Iluminação (Interruptores de luz mapeiam para lâmpada!)
    if (cat == 'dj' || 
        lowerName.contains('luz') || 
        lowerName.contains('lampada') || 
        lowerName.contains('lâmpada') || 
        lowerName.contains('iluminacao') || 
        lowerName.contains('iluminação') || 
        lowerName.contains('spot') || 
        lowerName.contains('lustre') || 
        lowerName.contains('plafon') || 
        lowerName.contains('cabeceira') || 
        lowerName.contains('cama') ||
        lowerProduct.contains('luz') || 
        lowerProduct.contains('lampada') || 
        lowerProduct.contains('lâmpada')) {
      return 'dj'; // dj = Luz
    }

    // 7. Tomadas e Plugs
    if (cat == 'cz' || 
        lowerName.contains('tomada') || 
        lowerName.contains('plug') || 
        lowerProduct.contains('tomada') || 
        lowerProduct.contains('plug')) {
      return 'cz'; // cz = Tomada
    }

    // 8. Interruptor genérico (kg)
    if (cat == 'kg' || 
        lowerName.contains('interruptor') || 
        lowerProduct.contains('interruptor') || 
        lowerName.contains('switch') || 
        lowerProduct.contains('switch')) {
      return 'kg'; // kg = Switch
    }

    return rawCategory;
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
  String? _uid;
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
      _uid = body['result']['uid'] as String?;
      return _accessToken!;
    } else {
      throw Exception('Autenticação falhou: ${body['msg']} (Código: ${body['code']})');
    }
  }

  /// Baixa a lista completa de dispositivos da conta da Tuya.
  Future<List<TuyaDeviceModel>> fetchDevices() async {
    if (isMock) {
      await Future.delayed(const Duration(milliseconds: 800));
      return getMockDevicesFallback();
    }

    if (_accessToken == null) {
      await authenticate();
    }

    final allDevicesList = <TuyaDeviceModel>[];
    final seenIds = <String>{};
    int pageNo = 1;
    bool hasMore = true;
    const maxPages = 10; // Limite de segurança para evitar loops infinitos

    while (hasMore && pageNo <= maxPages) {
      final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final path = '/v2.0/cloud/thing/device?page_no=$pageNo&page_size=20';
      
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
        final resultData = body['result'];
        List list = [];
        if (resultData is List) {
          list = resultData;
        } else if (resultData is Map) {
          list = resultData['list'] as List? ?? [];
        }
        
        if (list.isEmpty) {
          hasMore = false;
          break;
        }
        
        final pageDevices = list.map((item) => TuyaDeviceModel.fromJson(Map<String, dynamic>.from(item as Map))).toList();
        
        // Verifica se há novos itens nesta página
        bool hasNewItems = false;
        for (var device in pageDevices) {
          if (!seenIds.contains(device.id)) {
            seenIds.add(device.id);
            allDevicesList.add(device);
            hasNewItems = true;
          }
        }

        // Se a página retornou menos registros que o limite de 20
        // ou se não há nenhum item inédito (evita loop se o servidor ignorar a paginação)
        if (pageDevices.length < 20 || !hasNewItems) {
          hasMore = false;
        } else {
          pageNo++;
        }
      } else {
        // Se falhar devido a token expirado (ex: erro 1010 ou 1024), tenta renovar o token
        if (body['code'] == 1010 || body['code'] == 1024) {
          await authenticate();
          continue; // Tenta novamente com o token renovado
        }
        
        // Se o erro for de falta de permissão (1106), orienta de forma clara
        if (body['code'] == 1106) {
          throw Exception('Sem permissão (Código 1106). No portal Tuya Cloud, certifique-se de que ativou a API "Smart Home Basic Service" (ou IoT Core) e vinculou sua conta Smart Life.');
        }
        
        throw Exception('Falha ao obter dispositivos: ${body['msg']} (Código: ${body['code']})');
      }
    }

    return allDevicesList;
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

  /// Retorna dispositivos simulados padrão caso esteja operando em modo Mock ou fallback.
  List<TuyaDeviceModel> getMockDevicesFallback() {
    return [
      TuyaDeviceModel(
        id: 'tuya_dev_ac1',
        name: 'Tuya Central AC Floor 1',
        category: 'kt', // kt = ar condicionado (climate)
        isOnline: true,
        status: {'switch': true, 'temp_set': 22.0, 'mode': 'cool', 'temp_current': 22.0},
        iconUrl: '',
        model: 'AC-Cool-100',
        productName: 'Tuya Smart Thermostat',
      ),
      TuyaDeviceModel(
        id: 'tuya_dev_ac2',
        name: 'Tuya Heat Pump Floor 2',
        category: 'kt',
        isOnline: true,
        status: {'switch': true, 'temp_set': 24.0, 'mode': 'cool', 'temp_current': 27.0},
        iconUrl: '',
        model: 'AC-Cool-200',
        productName: 'Tuya Smart Thermostat v2',
      ),
      TuyaDeviceModel(
        id: 'tuya_dev_plug1',
        name: 'Tuya Smart Plug Washer',
        category: 'kg', // kg = plugue/switch
        isOnline: true,
        status: {'switch': false},
        iconUrl: '',
        model: 'ZTS-Plug',
        productName: 'Tuya Smart Plug v3',
      ),
      TuyaDeviceModel(
        id: 'tuya_dev_light1',
        name: 'Tuya Dimmer Ceiling',
        category: 'dj', // dj = lâmpada/light
        isOnline: true,
        status: {'switch': true, 'bright_value': 800, 'temp_value': 500},
        iconUrl: '',
        model: 'ZTS-Light-Dimmer',
        productName: 'Tuya Smart Dimmer',
      ),
      TuyaDeviceModel(
        id: 'tuya_dev_curtain',
        name: 'Tuya Curtains Bedroom',
        category: 'cl', // cl = cortinas (curtains)
        isOnline: true,
        status: {'percent_control': 100}, // 100% aberta
        iconUrl: '',
        model: 'Zemi-Curtain-Roller',
        productName: 'Zemismart Roller Curtain Motor',
      ),
      TuyaDeviceModel(
        id: 'tuya_dev_vacuum',
        name: 'Robô Aspirador ABIR-X9',
        category: 'vacuum',
        isOnline: true,
        status: {'switch': false},
        iconUrl: '',
        model: 'ABIR-X9',
        productName: 'ABIR Robot Vacuum Cleaner',
      ),
      TuyaDeviceModel(
        id: 'tuya_dev_lock',
        name: 'Porta de Entrada IFR 7000',
        category: 'security',
        isOnline: true,
        status: {'switch': true}, // true = trancada
        iconUrl: '',
        model: 'IFR 7000',
        productName: 'Intelbras IFR 7000 Smart Lock',
      ),
      TuyaDeviceModel(
        id: 'tuya_dev_sensor',
        name: 'Sensor Gourmet',
        category: 'sensor',
        isOnline: true,
        status: {'temp_current': 23.5, 'humidity': 62.0},
        iconUrl: '',
        model: 'STU-ZBD',
        productName: 'Zigbee Temperature Humidity Sensor',
      ),
    ];
  }
}
