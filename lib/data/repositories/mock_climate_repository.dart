import 'dart:async';
import '../../domain/entities/climate_device.dart';
import '../../domain/repositories/climate_repository.dart';

class MockClimateRepository implements ClimateRepository {
  // In-memory climate state
  final List<ClimateDevice> _climates = [
    const ClimateDevice(
      id: 'climate_floor1',
      name: 'Floor 1 Central AC',
      floor: 1,
      isOn: true,
      currentTemperature: 22.0,
      targetTemperature: 21.0,
      mode: 'cool',
      brand: 'Tuya Cloud',
    ),
    const ClimateDevice(
      id: 'climate_floor2',
      name: 'Floor 2 Heat Pump',
      floor: 2,
      isOn: true,
      currentTemperature: 27.0,
      targetTemperature: 24.0,
      mode: 'cool',
      brand: 'Tuya Cloud',
    ),
  ];

  @override
  Future<List<ClimateDevice>> getClimateDevices() async {
    await Future.delayed(const Duration(milliseconds: 700));
    return List.from(_climates);
  }

  @override
  Future<ClimateDevice> toggleClimate(String id) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final index = _climates.indexWhere((c) => c.id == id);
    if (index == -1) throw Exception("Climate device not found");

    final device = _climates[index];
    final updated = device.copyWith(isOn: !device.isOn);
    _climates[index] = updated;
    return updated;
  }

  @override
  Future<ClimateDevice> setTargetTemperature(String id, double temperature) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final index = _climates.indexWhere((c) => c.id == id);
    if (index == -1) throw Exception("Climate device not found");

    final device = _climates[index];
    final updated = device.copyWith(targetTemperature: temperature);
    _climates[index] = updated;
    return updated;
  }

  @override
  Future<ClimateDevice> setClimateMode(String id, String mode) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final index = _climates.indexWhere((c) => c.id == id);
    if (index == -1) throw Exception("Climate device not found");

    final device = _climates[index];
    final updated = device.copyWith(mode: mode);
    _climates[index] = updated;
    return updated;
  }

  @override
  Future<Map<int, double>> getFloorTemperatures() async {
    await Future.delayed(const Duration(milliseconds: 500));
    // Simulates returning current temperature of each floor
    return {
      1: _climates.firstWhere((c) => c.floor == 1).currentTemperature,
      2: _climates.firstWhere((c) => c.floor == 2).currentTemperature,
    };
  }
}
