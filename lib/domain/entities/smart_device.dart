import 'package:equatable/equatable.dart';

abstract class SmartDevice extends Equatable {
  final String id;
  final String name;
  final String room;
  final int floor;
  final bool isOnline;

  const SmartDevice({
    required this.id,
    required this.name,
    required this.room,
    required this.floor,
    this.isOnline = true,
  });

  @override
  List<Object?> get props => [id, name, room, floor, isOnline];
}

class SmartSwitch extends SmartDevice {
  final bool isOn;
  final String brand; // e.g., "Tasmota", "Tuya"

  const SmartSwitch({
    required super.id,
    required super.name,
    required super.room,
    required super.floor,
    required this.isOn,
    required this.brand,
    super.isOnline,
  });

  SmartSwitch copyWith({
    bool? isOn,
    bool? isOnline,
  }) {
    return SmartSwitch(
      id: id,
      name: name,
      room: room,
      floor: floor,
      isOn: isOn ?? this.isOn,
      brand: brand,
      isOnline: isOnline ?? this.isOnline,
    );
  }

  @override
  List<Object?> get props => [...super.props, isOn, brand];
}

class SmartLight extends SmartDevice {
  final bool isOn;
  final double brightness; // 0.0 to 1.0
  final int colorHex; // RGB color representation
  final String brand; // e.g., "NodeMCU"

  const SmartLight({
    required super.id,
    required super.name,
    required super.room,
    required super.floor,
    required this.isOn,
    required this.brightness,
    required this.colorHex,
    required this.brand,
    super.isOnline,
  });

  SmartLight copyWith({
    bool? isOn,
    double? brightness,
    int? colorHex,
    bool? isOnline,
  }) {
    return SmartLight(
      id: id,
      name: name,
      room: room,
      floor: floor,
      isOn: isOn ?? this.isOn,
      brightness: brightness ?? this.brightness,
      colorHex: colorHex ?? this.colorHex,
      brand: brand,
      isOnline: isOnline ?? this.isOnline,
    );
  }

  @override
  List<Object?> get props => [...super.props, isOn, brightness, colorHex, brand];
}
