import 'package:flutter/material.dart';

/// Classe de localização customizada para prover suporte a multi-idiomas (i18n).
/// 
/// Mapeia chaves de tradução para textos em Português (pt) e Inglês (en).
class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  /// Recupera a instância mais próxima de [AppLocalizations] no contexto.
  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  /// Dicionário estático contendo todas as traduções do aplicativo.
  static const Map<String, Map<String, String>> _localizedValues = {
    'pt': {
      'app_title': 'Open Home',
      'dashboard': 'Painel Inteligente',
      'rooms': 'Cômodos',
      'media': 'Mídia',
      'climate': 'Clima',
      'security': 'Segurança',
      'thermal_status': 'Status Térmico Residencial',
      'floor_1': 'Andar 1 (Térreo)',
      'floor_2': 'Andar 2 (Superior)',
      'comfortable': 'Confortável',
      'warm': 'Quente',
      'active_devices': 'Dispositivos Ativos',
      'dim': 'Brilho',
      'no_devices': 'Nenhum dispositivo encontrado neste andar.',
      'error': 'Erro',
      'quick_scenes': 'Ações Rápidas de Cenas',
      'movie_mode': 'Modo Filme',
      'reading': 'Leitura',
      'applying_scene': 'Aplicando cena...',
      'scene_applied': 'Cena aplicada!',
      'now_playing': 'Tocando Agora',
      'master_volume': 'Volume Master de Cast',
      'speaker_zones': 'Zonas de Caixas de Som',
      'synced': 'SINCRONIZADO',
      'sync_speakers': 'Sincronizar Áudio entre Andares',
      'unsync_speakers': 'Desfazer Sincronização de Áudio',
      'speakers_synced': 'Caixas de som sincronizadas!',
      'speakers_unsynced': 'Sincronização de caixas desfeita.',
      'energy_consumption': 'Consumo Elétrico Trifásico',
      'active_load': 'Carga Ativa Total',
      'room_presence': 'Presença nos Cômodos',
      'occupied': 'Ocupado',
      'empty': 'Vazio',
      'active_now': 'Ativo agora',
      'motion': 'Movimento',
      'settings': 'Configurações',
      'language': 'Idioma',
      'timezone': 'Fuso Horário',
      'portuguese': 'Português',
      'english': 'Inglês',
      'save': 'Salvar',
      'thermostat_off': 'O termostato está desligado.',
      'system_mode': 'Modo do Sistema',
      'target_temp': 'Temperatura Alvo',
      'current_temp': 'Atual',
      'living_room': 'Sala de Estar',
      'kitchen': 'Cozinha',
      'bedroom': 'Quarto Principal',
      'office': 'Escritório',
      'tasmota_switch': 'Interruptor Inteligente Tasmota',
      'tuya_plug': 'Plugue Inteligente Tuya Zigbee',
      'nodemcu_strip': 'Fita LED RGB NodeMCU',
      'color_palette': 'Paleta de Cores',
    },
    'en': {
      'app_title': 'Open Home',
      'dashboard': 'Smart Dashboard',
      'rooms': 'Rooms',
      'media': 'Media',
      'climate': 'Climate',
      'security': 'Security',
      'thermal_status': 'Home Thermal Status',
      'floor_1': 'Floor 1 (Ground)',
      'floor_2': 'Floor 2 (Upper)',
      'comfortable': 'Comfortable',
      'warm': 'Warm',
      'active_devices': 'Active Devices',
      'dim': 'Dim',
      'no_devices': 'No devices on this floor.',
      'error': 'Error',
      'quick_scenes': 'Preset Scenes Quick Actions',
      'movie_mode': 'Movie Mode',
      'reading': 'Reading',
      'applying_scene': 'Applying scene...',
      'scene_applied': 'Scene applied!',
      'now_playing': 'Now Playing',
      'master_volume': 'Master Cast Volume',
      'speaker_zones': 'Cast Speakers Zones',
      'synced': 'SYNCED',
      'sync_speakers': 'Synchronize Audio Across Floors',
      'unsync_speakers': 'Unsynchronize Audio Zones',
      'speakers_synced': 'Audio synchronized across floors!',
      'speakers_unsynced': 'Audio zones unlinked.',
      'energy_consumption': '3-Phase Energy Consumption',
      'active_load': 'Active Load Total',
      'room_presence': 'Room Presence',
      'occupied': 'Occupied',
      'empty': 'Empty',
      'active_now': 'Active now',
      'motion': 'Motion',
      'settings': 'Settings',
      'language': 'Language',
      'timezone': 'Timezone',
      'portuguese': 'Portuguese',
      'english': 'English',
      'save': 'Save',
      'thermostat_off': 'Thermostat is turned off.',
      'system_mode': 'System Mode',
      'target_temp': 'Target Temperature',
      'current_temp': 'Current',
      'living_room': 'Living Room',
      'kitchen': 'Kitchen',
      'bedroom': 'Master Bedroom',
      'office': 'Office',
      'tasmota_switch': 'Tasmota Smart Switch',
      'tuya_plug': 'Tuya Zigbee Smart Plug',
      'nodemcu_strip': 'NodeMCU RGB LED Strip',
      'color_palette': 'Color Palette',
    },
  };

  /// Retorna o valor traduzido para a [key] fornecida.
  /// 
  /// Caso a chave não exista, retorna a própria chave para depuração.
  String translate(String key) {
    return _localizedValues[locale.languageCode]?[key] ?? key;
  }
}

/// Delegate obrigatório do Flutter para registrar a classe de localização.
class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['pt', 'en'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(AppLocalizationsDelegate old) => false;
}

/// Extensão helper para chamar a tradução diretamente do BuildContext.
/// 
/// Exemplo: `context.translate('app_title')`
extension LocalizationExtension on BuildContext {
  String translate(String key) {
    return AppLocalizations.of(this)?.translate(key) ?? key;
  }
}
