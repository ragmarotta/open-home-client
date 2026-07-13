import '../entities/monitoring_metrics.dart';

abstract class MonitoringRepository {
  Future<EnergyMetrics> getEnergyMetrics();
  Future<List<PresenceSensor>> getPresenceSensors();
  Stream<EnergyMetrics> streamEnergyMetrics(); // Continuous flow mock
}
