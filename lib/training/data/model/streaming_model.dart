import 'dart:collection';

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
  final Point3D point;
  final TracePhase phase;

  TracePoint(this.point, this.phase);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TracePoint && other.point == point && other.phase == phase;
  }

  @override
  int get hashCode => point.hashCode ^ phase.hashCode;
}

class Point3D {
  final double x;
  final double y;
  final double z;

  const Point3D(this.x, this.y, this.z);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Point3D && other.x == x && other.y == y && other.z == z;
  }

  @override
  int get hashCode => x.hashCode ^ y.hashCode ^ z.hashCode;
}
