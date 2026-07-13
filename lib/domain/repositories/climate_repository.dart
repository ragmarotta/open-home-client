import '../entities/climate_device.dart';

abstract class ClimateRepository {
  Future<List<ClimateDevice>> getClimateDevices();
  Future<ClimateDevice> toggleClimate(String id);
  Future<ClimateDevice> setTargetTemperature(String id, double temperature);
  Future<ClimateDevice> setClimateMode(String id, String mode);
  Future<Map<int, double>> getFloorTemperatures(); // floor -> temp
}
