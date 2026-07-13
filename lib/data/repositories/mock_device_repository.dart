import 'dart:async';
import '../../domain/entities/smart_device.dart';
import '../../domain/repositories/device_repository.dart';

class MockDeviceRepository implements DeviceRepository {
  // In-memory state to simulate device persistence
  final List<SmartDevice> _devices = [
    // Floor 1 (Ground)
    const SmartSwitch(
      id: 'sw_tasmota_living',
      name: 'Main Ceiling Light',
      room: 'Living Room',
      floor: 1,
      isOn: false,
      brand: 'Tasmota',
    ),
    const SmartLight(
      id: 'light_nodemcu_living',
      name: 'Accent RGB LED Strip',
      room: 'Living Room',
      floor: 1,
      isOn: true,
      brightness: 0.7,
      colorHex: 0xFF6200EE, // Indigo
      brand: 'NodeMCU',
    ),
    const SmartSwitch(
      id: 'plug_tuya_living',
      name: 'Media Center Outlet',
      room: 'Living Room',
      floor: 1,
      isOn: true,
      brand: 'Tuya Zigbee',
    ),
    const SmartSwitch(
      id: 'sw_tasmota_kitchen',
      name: 'Kitchen Undercabinet',
      room: 'Kitchen',
      floor: 1,
      isOn: false,
      brand: 'Tasmota',
    ),
    // Floor 2 (Upper)
    const SmartSwitch(
      id: 'sw_tasmota_bedroom',
      name: 'Bedside Lamp',
      room: 'Master Bedroom',
      floor: 2,
      isOn: true,
      brand: 'Tasmota',
    ),
    const SmartLight(
      id: 'light_nodemcu_bedroom',
      name: 'Headboard RGB Accent',
      room: 'Master Bedroom',
      floor: 2,
      isOn: false,
      brightness: 0.5,
      colorHex: 0xFF00E5FF, // Cyan
      brand: 'NodeMCU',
    ),
    const SmartSwitch(
      id: 'plug_tuya_office',
      name: 'Workstation Charger',
      room: 'Office',
      floor: 2,
      isOn: false,
      brand: 'Tuya Zigbee',
    ),
  ];

  @override
  Future<List<SmartDevice>> getDevicesByFloor(int floor) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 600));
    return _devices.where((device) => device.floor == floor).toList();
  }

  @override
  Future<SmartDevice> toggleDevice(String id) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final index = _devices.indexWhere((d) => d.id == id);
    if (index == -1) throw Exception("Device not found");

    final device = _devices[index];
    SmartDevice updatedDevice;

    if (device is SmartSwitch) {
      updatedDevice = device.copyWith(isOn: !device.isOn);
    } else if (device is SmartLight) {
      updatedDevice = device.copyWith(isOn: !device.isOn);
    } else {
      throw Exception("Unknown device type");
    }

    _devices[index] = updatedDevice;
    return updatedDevice;
  }

  @override
  Future<SmartLight> updateLightBrightness(String id, double brightness) async {
    await Future.delayed(const Duration(milliseconds: 200)); // Slower dimming updates should feel slightly snappier
    final index = _devices.indexWhere((d) => d.id == id);
    if (index == -1) throw Exception("Device not found");

    final device = _devices[index];
    if (device is! SmartLight) throw Exception("Device is not a light");

    final updatedLight = device.copyWith(brightness: brightness);
    _devices[index] = updatedLight;
    return updatedLight;
  }

  @override
  Future<SmartLight> updateLightColor(String id, int colorHex) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final index = _devices.indexWhere((d) => d.id == id);
    if (index == -1) throw Exception("Device not found");

    final device = _devices[index];
    if (device is! SmartLight) throw Exception("Device is not a light");

    final updatedLight = device.copyWith(colorHex: colorHex);
    _devices[index] = updatedLight;
    return updatedLight;
  }
}
