import 'package:flutter/material.dart';
import 'dashboard_tab.dart';
import 'audio_central_tab.dart';
import 'climate_tab.dart';
import 'energy_presence_tab.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

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
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.meeting_room_outlined),
              activeIcon: Icon(Icons.meeting_room),
              label: 'Rooms',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.audiotrack_outlined),
              activeIcon: Icon(Icons.audiotrack),
              label: 'Media',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.thermostat_outlined),
              activeIcon: Icon(Icons.thermostat),
              label: 'Climate',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.security_outlined),
              activeIcon: Icon(Icons.security),
              label: 'Security',
            ),
          ],
        ),
      ),
    );
  }
}
