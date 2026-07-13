import 'dart:async';
import 'dart:math';
import '../../domain/entities/monitoring_metrics.dart';
import '../../domain/repositories/monitoring_repository.dart';

class MockMonitoringRepository implements MonitoringRepository {
  final Random _random = Random();

  final List<PresenceSensor> _presenceSensors = [
    PresenceSensor(
      id: 'presence_living',
      roomName: 'Living Room',
      floor: 1,
      isOccupied: true,
      lastMotionTime: DateTime.now().subtract(const Duration(minutes: 2)),
    ),
    PresenceSensor(
      id: 'presence_kitchen',
      roomName: 'Kitchen',
      floor: 1,
      isOccupied: false,
      lastMotionTime: DateTime.now().subtract(const Duration(minutes: 45)),
    ),
    PresenceSensor(
      id: 'presence_bedroom',
      roomName: 'Master Bedroom',
      floor: 2,
      isOccupied: false,
      lastMotionTime: DateTime.now().subtract(const Duration(hours: 3)),
    ),
    PresenceSensor(
      id: 'presence_office',
      roomName: 'Office',
      floor: 2,
      isOccupied: true,
      lastMotionTime: DateTime.now().subtract(const Duration(minutes: 5)),
    ),
  ];

  @override
  Future<EnergyMetrics> getEnergyMetrics() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _generateMockMetrics();
  }

  @override
  Future<List<PresenceSensor>> getPresenceSensors() async {
    await Future.delayed(const Duration(milliseconds: 400));
    return List.from(_presenceSensors);
  }

  @override
  Stream<EnergyMetrics> streamEnergyMetrics() {
    return Stream.periodic(const Duration(seconds: 4), (_) {
      return _generateMockMetrics();
    });
  }

  EnergyMetrics _generateMockMetrics() {
    // Generate values around: Phase A ~ 1.5 kW, Phase B ~ 1.3 kW, Phase C ~ 1.4 kW
    final phaseA = 1.2 + _random.nextDouble() * 0.6;
    final phaseB = 1.0 + _random.nextDouble() * 0.5;
    final phaseC = 1.1 + _random.nextDouble() * 0.7;
    return EnergyMetrics(
      phaseA: double.parse(phaseA.toStringAsFixed(2)),
      phaseB: double.parse(phaseB.toStringAsFixed(2)),
      phaseC: double.parse(phaseC.toStringAsFixed(2)),
    );
  }
}
