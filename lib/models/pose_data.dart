import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

/// 姿态数据模型
class PoseData {
  final Map<PoseLandmarkType, PoseLandmark> landmarks;
  final double confidence;
  final DateTime timestamp;
  
  PoseData({
    required this.landmarks,
    required this.confidence,
    required this.timestamp,
  });
  
  /// 从ML Kit Pose结果创建
  factory PoseData.fromPose(Pose pose) {
    final landmarksMap = <PoseLandmarkType, PoseLandmark>{};
    
    for (var landmark in pose.landmarks.values) {
      landmarksMap[landmark.type] = landmark;
    }
    
    // 计算平均置信度
    double totalConfidence = 0;
    int count = 0;
    for (var landmark in pose.landmarks.values) {
      totalConfidence += landmark.likelihood;
      count++;
    }
    double avgConfidence = count > 0 ? totalConfidence / count : 0.0;
    
    return PoseData(
      landmarks: landmarksMap,
      confidence: avgConfidence,
      timestamp: DateTime.now(),
    );
  }
  
  /// 获取特定关键点
  PoseLandmark? getLandmark(PoseLandmarkType type) {
    return landmarks[type];
  }
  
  /// 检查关键点是否可见
  bool isLandmarkVisible(PoseLandmarkType type, {double threshold = 0.5}) {
    final landmark = landmarks[type];
    return landmark != null && landmark.likelihood >= threshold;
  }
  
  /// 获取关键点坐标（归一化坐标0-1）
  Map<String, double>? getLandmarkPosition(PoseLandmarkType type) {
    final landmark = landmarks[type];
    if (landmark == null) return null;
    
    return {
      'x': landmark.x,
      'y': landmark.y,
      'z': landmark.z,
    };
  }
}

/// 角度数据模型
class AngleData {
  final double shoulderWristAngle;
  final double elbowAngle;
  final double kneeAngle;
  final DateTime timestamp;
  
  AngleData({
    required this.shoulderWristAngle,
    required this.elbowAngle,
    required this.kneeAngle,
    required this.timestamp,
  });
  
  factory AngleData.zero() {
    return AngleData(
      shoulderWristAngle: 0,
      elbowAngle: 0,
      kneeAngle: 0,
      timestamp: DateTime.now(),
    );
  }
  
  bool get isValid {
    return shoulderWristAngle > 0 || elbowAngle > 0 || kneeAngle > 0;
  }
}
