import '../entities/smart_device.dart';

abstract class DeviceRepository {
  Future<List<SmartDevice>> getDevicesByFloor(int floor);
  Future<SmartDevice> toggleDevice(String id);
  Future<SmartLight> updateLightColor(String id, int colorHex);
  Future<SmartLight> updateLightBrightness(String id, double brightness);
}
