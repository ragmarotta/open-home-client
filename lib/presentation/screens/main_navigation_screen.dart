import 'package:flutter/material.dart';
import '../../core/localization/app_localizations.dart';
import 'dashboard_tab.dart';
import 'audio_central_tab.dart';
import 'climate_tab.dart';
import 'energy_presence_tab.dart';

/// Widget de Navegação Principal do aplicativo (Base do Scaffold).
/// 
/// Gerencia a barra de navegação inferior (sticky) e renderiza as guias (tabs)
/// usando [IndexedStack] para preservar o estado de scroll e dados de cada aba.
class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  // Índice da aba atualmente selecionada.
  int _currentIndex = 0;

  // Lista estática com os widgets correspondentes a cada aba de conteúdo.
  final List<Widget> _tabs = const [
    DashboardTab(),
    AudioCentralTab(),
    ClimateTab(),
    EnergyPresenceTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: IndexedStack(
          index: _currentIndex,
          children: _tabs,
        ),
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(color: Color(0xFF202638), width: 1),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          items: [
            // Aba Cômodos / Rooms
            BottomNavigationBarItem(
              icon: const Icon(Icons.meeting_room_outlined),
              activeIcon: const Icon(Icons.meeting_room),
              label: context.translate('rooms'),
            ),
            // Aba Mídia / Media
            BottomNavigationBarItem(
              icon: const Icon(Icons.audiotrack_outlined),
              activeIcon: const Icon(Icons.audiotrack),
              label: context.translate('media'),
            ),
            // Aba Clima / Climate
            BottomNavigationBarItem(
              icon: const Icon(Icons.thermostat_outlined),
              activeIcon: const Icon(Icons.thermostat),
              label: context.translate('climate'),
            ),
            // Aba Segurança / Security
            BottomNavigationBarItem(
              icon: const Icon(Icons.security_outlined),
              activeIcon: const Icon(Icons.security),
              label: context.translate('security'),
            ),
          ],
        ),
      ),
    );
  }
}
