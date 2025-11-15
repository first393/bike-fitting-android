import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import '../models/pose_data.dart';

/// 骨架绘制器
/// 移植自Python版本的SkeletonRenderer
class SkeletonPainter extends CustomPainter {
  final PoseData? poseData;
  final AngleData? angleData;
  final Size imageSize;
  
  SkeletonPainter({
    required this.poseData,
    required this.angleData,
    required this.imageSize,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    if (poseData == null) return;
    
    // 绘制骨架连接线
    _drawSkeletonLines(canvas, size);
    
    // 绘制关键点
    _drawKeypoints(canvas, size);
    
    // 绘制角度标注
    if (angleData != null) {
      _drawAngleAnnotations(canvas, size);
    }
    
    // 绘制髋关节准星
    _drawHipCrosshair(canvas, size);
  }
  
  /// 绘制骨架连接线
  void _drawSkeletonLines(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = Colors.green
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;
    
    // 定义骨架连接关系
    final connections = [
      // 躯干
      [PoseLandmarkType.leftShoulder, PoseLandmarkType.rightShoulder],
      [PoseLandmarkType.leftShoulder, PoseLandmarkType.leftHip],
      [PoseLandmarkType.rightShoulder, PoseLandmarkType.rightHip],
      [PoseLandmarkType.leftHip, PoseLandmarkType.rightHip],
      
      // 左臂
      [PoseLandmarkType.leftShoulder, PoseLandmarkType.leftElbow],
      [PoseLandmarkType.leftElbow, PoseLandmarkType.leftWrist],
      
      // 右臂
      [PoseLandmarkType.rightShoulder, PoseLandmarkType.rightElbow],
      [PoseLandmarkType.rightElbow, PoseLandmarkType.rightWrist],
      
      // 左腿
      [PoseLandmarkType.leftHip, PoseLandmarkType.leftKnee],
      [PoseLandmarkType.leftKnee, PoseLandmarkType.leftAnkle],
      
      // 右腿
      [PoseLandmarkType.rightHip, PoseLandmarkType.rightKnee],
      [PoseLandmarkType.rightKnee, PoseLandmarkType.rightAnkle],
    ];
    
    for (final connection in connections) {
      final point1 = poseData!.getLandmark(connection[0]);
      final point2 = poseData!.getLandmark(connection[1]);
      
      if (point1 != null && point2 != null && 
          point1.likelihood > 0.5 && point2.likelihood > 0.5) {
        final p1 = _translatePoint(point1, size);
        final p2 = _translatePoint(point2, size);
        canvas.drawLine(p1, p2, linePaint);
      }
    }
  }
  
  /// 绘制关键点
  void _drawKeypoints(Canvas canvas, Size size) {
    final pointPaint = Paint()
      ..color = Colors.green
      ..style = PaintingStyle.fill;
    
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    
    for (final landmark in poseData!.landmarks.values) {
      if (landmark.likelihood > 0.5) {
        final point = _translatePoint(landmark, size);
        
        // 绘制关键点
        canvas.drawCircle(point, 8, pointPaint);
        canvas.drawCircle(point, 8, borderPaint);
      }
    }
  }
  
  /// 绘制角度标注
  void _drawAngleAnnotations(Canvas canvas, Size size) {
    final textStyle = const TextStyle(
      color: Colors.white,
      fontSize: 16,
      fontWeight: FontWeight.bold,
      backgroundColor: Colors.black54,
    );
    
    // 绘制肩部到手腕角度
    if (angleData!.shoulderWristAngle > 0) {
      final leftShoulder = poseData!.getLandmark(PoseLandmarkType.leftShoulder);
      if (leftShoulder != null) {
        final point = _translatePoint(leftShoulder, size);
        _drawText(
          canvas,
          '肩部-手腕: ${angleData!.shoulderWristAngle.toStringAsFixed(1)}°',
          Offset(point.dx - 50, point.dy - 30),
          textStyle,
        );
      }
    }
    
    // 绘制肘关节角度
    if (angleData!.elbowAngle > 0) {
      final leftElbow = poseData!.getLandmark(PoseLandmarkType.leftElbow);
      if (leftElbow != null) {
        final point = _translatePoint(leftElbow, size);
        _drawText(
          canvas,
          '肘部: ${angleData!.elbowAngle.toStringAsFixed(1)}°',
          Offset(point.dx + 10, point.dy),
          textStyle,
        );
      }
    }
    
    // 绘制膝关节角度
    if (angleData!.kneeAngle > 0) {
      final leftKnee = poseData!.getLandmark(PoseLandmarkType.leftKnee);
      if (leftKnee != null) {
        final point = _translatePoint(leftKnee, size);
        _drawText(
          canvas,
          '膝部: ${angleData!.kneeAngle.toStringAsFixed(1)}°',
          Offset(point.dx + 10, point.dy),
          textStyle,
        );
      }
    }
  }
  
  /// 绘制髋关节准星（红色十字）
  void _drawHipCrosshair(Canvas canvas, Size size) {
    final leftHip = poseData!.getLandmark(PoseLandmarkType.leftHip);
    final rightHip = poseData!.getLandmark(PoseLandmarkType.rightHip);
    
    if (leftHip != null && rightHip != null) {
      final leftPoint = _translatePoint(leftHip, size);
      final rightPoint = _translatePoint(rightHip, size);
      
      // 计算髋部中心点
      final centerX = (leftPoint.dx + rightPoint.dx) / 2;
      final centerY = (leftPoint.dy + rightPoint.dy) / 2;
      final center = Offset(centerX, centerY);
      
      final crosshairPaint = Paint()
        ..color = Colors.red
        ..strokeWidth = 2.0
        ..style = PaintingStyle.stroke;
      
      const size = 15.0;
      
      // 绘制十字线
      canvas.drawLine(
        Offset(center.dx - size, center.dy),
        Offset(center.dx + size, center.dy),
        crosshairPaint,
      );
      canvas.drawLine(
        Offset(center.dx, center.dy - size),
        Offset(center.dx, center.dy + size),
        crosshairPaint,
      );
      
      // 绘制圆圈
      canvas.drawCircle(center, size + 5, crosshairPaint);
    }
  }
  
  /// 将关键点坐标转换为画布坐标
  Offset _translatePoint(PoseLandmark landmark, Size size) {
    // ML Kit返回的坐标是像素坐标，需要根据图像大小和画布大小进行缩放
    final scaleX = size.width / imageSize.width;
    final scaleY = size.height / imageSize.height;
    
    return Offset(
      landmark.x * scaleX,
      landmark.y * scaleY,
    );
  }
  
  /// 绘制文本
  void _drawText(Canvas canvas, String text, Offset position, TextStyle style) {
    final textSpan = TextSpan(text: text, style: style);
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );
    
    textPainter.layout();
    textPainter.paint(canvas, position);
  }
  
  @override
  bool shouldRepaint(covariant SkeletonPainter oldDelegate) {
    return oldDelegate.poseData != poseData || oldDelegate.angleData != angleData;
  }
}

class AngleData {
  final double shoulderWristAngle;
  final double elbowAngle;
  final double kneeAngle;
  
  AngleData({
    required this.shoulderWristAngle,
    required this.elbowAngle,
    required this.kneeAngle,
  });
}
