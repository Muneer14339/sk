import 'package:equatable/equatable.dart';

class AngleReading extends Equatable {
  final double cant;
  final double tilt;
  final double pan;
  final DateTime timestamp;

  const AngleReading({
    required this.cant,
    required this.tilt,
    required this.pan,
    required this.timestamp,
  });

  // Factory constructor for creating with current timestamp
  factory AngleReading.now({
    required double cant,
    required double tilt,
    required double pan,
  }) {
    return AngleReading(
      cant: cant,
      tilt: tilt,
      pan: pan,
      timestamp: DateTime.now(),
    );
  }

  // Factory constructor for zero reading
  factory AngleReading.zero() {
    return AngleReading(
      cant: 0.0,
      tilt: 0.0,
      pan: 0.0,
      timestamp: DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [cant, tilt, pan, timestamp];
}