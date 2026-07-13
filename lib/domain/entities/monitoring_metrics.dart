import 'package:equatable/equatable.dart';

class EnergyMetrics extends Equatable {
  final double phaseA; // in kW
  final double phaseB; // in kW
  final double phaseC; // in kW

  const EnergyMetrics({
    required this.phaseA,
    required this.phaseB,
    required this.phaseC,
  });

  double get totalLoad => phaseA + phaseB + phaseC;

  @override
  List<Object?> get props => [phaseA, phaseB, phaseC];
}

class PresenceSensor extends Equatable {
  final String id;
  final String roomName;
  final int floor;
  final bool isOccupied;
  final DateTime lastMotionTime;

  const PresenceSensor({
    required this.id,
    required this.roomName,
    required this.floor,
    required this.isOccupied,
    required this.lastMotionTime,
  });

  PresenceSensor copyWith({
    bool? isOccupied,
    DateTime? lastMotionTime,
  }) {
    return PresenceSensor(
      id: id,
      roomName: roomName,
      floor: floor,
      isOccupied: isOccupied ?? this.isOccupied,
      lastMotionTime: lastMotionTime ?? this.lastMotionTime,
    );
  }

  @override
  List<Object?> get props => [id, roomName, floor, isOccupied, lastMotionTime];
}
