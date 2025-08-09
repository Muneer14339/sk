import 'dart:collection';
import 'dart:math';

class StreamingModel {
  double roll;
  double pitch;
  double yaw;
  Queue<TracePoint> points;
  bool shotDetected;

  StreamingModel({
    required this.roll,
    required this.pitch,
    required this.yaw,
    required this.points,
    required this.shotDetected,
  });
}

enum TracePhase {
  preShot,
  shot,
  postShot,
}

class TracePoint {
  final Point point;
  final TracePhase phase;

  TracePoint(this.point, this.phase);
}
