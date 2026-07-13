import 'package:equatable/equatable.dart';

class ClimateDevice extends Equatable {
  final String id;
  final String name;
  final int floor;
  final bool isOn;
  final double currentTemperature;
  final double targetTemperature;
  final String mode; // "cool", "heat", "fan", "auto"
  final String brand; // e.g. "Tuya"

  const ClimateDevice({
    required this.id,
    required this.name,
    required this.floor,
    required this.isOn,
    required this.currentTemperature,
    required this.targetTemperature,
    required this.mode,
    required this.brand,
  });

  ClimateDevice copyWith({
    bool? isOn,
    double? currentTemperature,
    double? targetTemperature,
    String? mode,
  }) {
    return ClimateDevice(
      id: id,
      name: name,
      floor: floor,
      isOn: isOn ?? this.isOn,
      currentTemperature: currentTemperature ?? this.currentTemperature,
      targetTemperature: targetTemperature ?? this.targetTemperature,
      mode: mode ?? this.mode,
      brand: brand,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        floor,
        isOn,
        currentTemperature,
        targetTemperature,
        mode,
        brand,
      ];
}
