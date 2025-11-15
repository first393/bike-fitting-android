import 'dart:math';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import '../models/pose_data.dart';

/// 角度计算服务
/// 移植自Python版本的AngleCalculator
class AngleCalculator {
  final int smoothingWindow;
  
  // 角度历史记录用于平滑处理
  final List<double> _shoulderWristHistory = [];
  final List<double> _elbowHistory = [];
  final List<double> _kneeHistory = [];
  
  AngleCalculator({this.smoothingWindow = 5});
  
  /// 计算所有角度
  AngleData calculateAngles(PoseData poseData) {
    final shoulderWrist = _calculateShoulderWristAngle(poseData);
    final elbow = _calculateElbowAngle(poseData);
    final knee = _calculateKneeAngle(poseData);
    
    // 应用平滑处理
    final smoothedShoulderWrist = _smoothAngle(shoulderWrist, _shoulderWristHistory);
    final smoothedElbow = _smoothAngle(elbow, _elbowHistory);
    final smoothedKnee = _smoothAngle(knee, _kneeHistory);
    
    return AngleData(
      shoulderWristAngle: smoothedShoulderWrist,
      elbowAngle: smoothedElbow,
      kneeAngle: smoothedKnee,
      timestamp: DateTime.now(),
    );
  }
  
  /// 计算肩部到手腕角度
  /// 反映上身前伸程度
  double _calculateShoulderWristAngle(PoseData poseData) {
    final leftShoulder = poseData.getLandmark(PoseLandmarkType.leftShoulder);
    final rightShoulder = poseData.getLandmark(PoseLandmarkType.rightShoulder);
    final leftWrist = poseData.getLandmark(PoseLandmarkType.leftWrist);
    final rightWrist = poseData.getLandmark(PoseLandmarkType.rightWrist);
    
    if (leftShoulder == null || rightShoulder == null || 
        leftWrist == null || rightWrist == null) {
      return 0.0;
    }
    
    // 计算肩部中心点
    final shoulderCenterX = (leftShoulder.x + rightShoulder.x) / 2;
    final shoulderCenterY = (leftShoulder.y + rightShoulder.y) / 2;
    
    // 计算手腕中心点
    final wristCenterX = (leftWrist.x + rightWrist.x) / 2;
    final wristCenterY = (leftWrist.y + rightWrist.y) / 2;
    
    // 计算角度（相对于水平线）
    final dx = wristCenterX - shoulderCenterX;
    final dy = wristCenterY - shoulderCenterY;
    
    final angleRad = atan2(dy, dx);
    final angleDeg = (angleRad * 180 / pi).abs();
    
    return min(angleDeg, 180.0);
  }
  
  /// 计算肘关节角度
  double _calculateElbowAngle(PoseData poseData) {
    // 计算左右肘关节角度
    final leftAngle = _calculateThreePointAngle(
      poseData.getLandmark(PoseLandmarkType.leftShoulder),
      poseData.getLandmark(PoseLandmarkType.leftElbow),
      poseData.getLandmark(PoseLandmarkType.leftWrist),
    );
    
    final rightAngle = _calculateThreePointAngle(
      poseData.getLandmark(PoseLandmarkType.rightShoulder),
      poseData.getLandmark(PoseLandmarkType.rightElbow),
      poseData.getLandmark(PoseLandmarkType.rightWrist),
    );
    
    // 选择置信度更高的
    final leftConfidence = poseData.getLandmark(PoseLandmarkType.leftElbow)?.likelihood ?? 0;
    final rightConfidence = poseData.getLandmark(PoseLandmarkType.rightElbow)?.likelihood ?? 0;
    
    if (leftConfidence > rightConfidence && leftAngle > 0) {
      return leftAngle;
    } else if (rightAngle > 0) {
      return rightAngle;
    }
    
    // 返回平均值
    final validAngles = [leftAngle, rightAngle].where((a) => a > 0).toList();
    return validAngles.isEmpty ? 0.0 : validAngles.reduce((a, b) => a + b) / validAngles.length;
  }
  
  /// 计算膝关节角度
  double _calculateKneeAngle(PoseData poseData) {
    final leftAngle = _calculateThreePointAngle(
      poseData.getLandmark(PoseLandmarkType.leftHip),
      poseData.getLandmark(PoseLandmarkType.leftKnee),
      poseData.getLandmark(PoseLandmarkType.leftAnkle),
    );
    
    final rightAngle = _calculateThreePointAngle(
      poseData.getLandmark(PoseLandmarkType.rightHip),
      poseData.getLandmark(PoseLandmarkType.rightKnee),
      poseData.getLandmark(PoseLandmarkType.rightAnkle),
    );
    
    // 返回平均值
    final validAngles = [leftAngle, rightAngle].where((a) => a > 0).toList();
    return validAngles.isEmpty ? 0.0 : validAngles.reduce((a, b) => a + b) / validAngles.length;
  }
  
  /// 计算三点形成的角度
  /// point2是顶点
  double _calculateThreePointAngle(
    PoseLandmark? point1,
    PoseLandmark? point2,
    PoseLandmark? point3,
  ) {
    if (point1 == null || point2 == null || point3 == null) {
      return 0.0;
    }
    
    // 检查可见性
    if (point1.likelihood < 0.5 || point2.likelihood < 0.5 || point3.likelihood < 0.5) {
      return 0.0;
    }
    
    // 构建向量
    final v1x = point1.x - point2.x;
    final v1y = point1.y - point2.y;
    final v2x = point3.x - point2.x;
    final v2y = point3.y - point2.y;
    
    // 计算点积和模长
    final dotProduct = v1x * v2x + v1y * v2y;
    final norm1 = sqrt(v1x * v1x + v1y * v1y);
    final norm2 = sqrt(v2x * v2x + v2y * v2y);
    
    if (norm1 == 0 || norm2 == 0) {
      return 0.0;
    }
    
    // 计算角度
    var cosAngle = dotProduct / (norm1 * norm2);
    cosAngle = max(-1.0, min(1.0, cosAngle)); // 避免浮点误差
    
    final angleRad = acos(cosAngle);
    final angleDeg = angleRad * 180 / pi;
    
    return angleDeg;
  }
  
  /// 平滑角度数据
  double _smoothAngle(double angle, List<double> history) {
    if (angle > 0) {
      history.add(angle);
      
      // 保持窗口大小
      if (history.length > smoothingWindow) {
        history.removeAt(0);
      }
      
      // 返回移动平均
      return history.reduce((a, b) => a + b) / history.length;
    } else {
      // 如果当前值为0，保持上一次的有效值
      return history.isEmpty ? 0.0 : history.last;
    }
  }
  
  /// 重置历史记录
  void reset() {
    _shoulderWristHistory.clear();
    _elbowHistory.clear();
    _kneeHistory.clear();
  }
}
