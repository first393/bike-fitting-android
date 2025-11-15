import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/pose_data.dart';
import '../services/angle_calculator.dart';
import '../widgets/skeleton_painter.dart' as sp;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isDetecting = false;
  bool _isCameraInitialized = false;
  
  // ML Kit姿态检测器
  final _poseDetector = PoseDetector(options: PoseDetectorOptions());
  
  // 角度计算器
  final _angleCalculator = AngleCalculator();
  
  // 当前姿态数据
  PoseData? _currentPoseData;
  sp.AngleData? _currentAngleData;
  
  // FPS计数
  int _frameCount = 0;
  double _fps = 0.0;
  DateTime _fpsTimestamp = DateTime.now();
  
  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }
  
  @override
  void dispose() {
    _cameraController?.dispose();
    _poseDetector.close();
    super.dispose();
  }
  
  /// 初始化摄像头
  Future<void> _initializeCamera() async {
    // 请求摄像头权限
    final status = await Permission.camera.request();
    if (!status.isGranted) {
      _showPermissionDeniedDialog();
      return;
    }
    
    try {
      // 获取可用摄像头
      _cameras = await availableCameras();
      
      if (_cameras == null || _cameras!.isEmpty) {
        _showErrorDialog('没有检测到摄像头');
        return;
      }
      
      // 使用后置摄像头
      final camera = _cameras!.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => _cameras!.first,
      );
      
      // 初始化摄像头控制器
      _cameraController = CameraController(
        camera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.nv21,
      );
      
      await _cameraController!.initialize();
      
      // 开始图像流处理
      _cameraController!.startImageStream(_processCameraImage);
      
      setState(() {
        _isCameraInitialized = true;
      });
      
    } catch (e) {
      _showErrorDialog('摄像头初始化失败: $e');
    }
  }
  
  /// 处理摄像头图像流
  Future<void> _processCameraImage(CameraImage image) async {
    if (_isDetecting) return;
    
    _isDetecting = true;
    
    try {
      // 转换为ML Kit输入格式
      final inputImage = _convertToInputImage(image);
      
      if (inputImage != null) {
        // 姿态检测
        final poses = await _poseDetector.processImage(inputImage);
        
        if (poses.isNotEmpty) {
          final pose = poses.first;
          final poseData = PoseData.fromPose(pose);
          
          // 计算角度
          final angleData = _angleCalculator.calculateAngles(poseData);
          
          // 更新UI
          setState(() {
            _currentPoseData = poseData;
            _currentAngleData = sp.AngleData(
              shoulderWristAngle: angleData.shoulderWristAngle,
              elbowAngle: angleData.elbowAngle,
              kneeAngle: angleData.kneeAngle,
            );
          });
          
          // 更新FPS
          _updateFPS();
        }
      }
    } catch (e) {
      print('姿态检测错误: $e');
    } finally {
      _isDetecting = false;
    }
  }
  
  /// 转换摄像头图像为ML Kit输入格式
  InputImage? _convertToInputImage(CameraImage image) {
    try {
      final camera = _cameraController!.description;
      
      // 获取图像旋转角度
      final sensorOrientation = camera.sensorOrientation;
      InputImageRotation? rotation;
      
      if (camera.lensDirection == CameraLensDirection.back) {
        rotation = InputImageRotation.rotation90deg;
      } else {
        rotation = InputImageRotation.rotation270deg;
      }
      
      // 获取图像格式
      final format = InputImageFormatValue.fromRawValue(image.format.raw);
      if (format == null) return null;
      
      // 构建平面数据
      final plane = image.planes.first;
      
      return InputImage.fromBytes(
        bytes: plane.bytes,
        metadata: InputImageMetadata(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          rotation: rotation,
          format: format,
          bytesPerRow: plane.bytesPerRow,
        ),
      );
    } catch (e) {
      print('图像转换错误: $e');
      return null;
    }
  }
  
  /// 更新FPS
  void _updateFPS() {
    _frameCount++;
    final now = DateTime.now();
    final diff = now.difference(_fpsTimestamp).inMilliseconds;
    
    if (diff >= 1000) {
      setState(() {
        _fps = _frameCount / (diff / 1000);
        _frameCount = 0;
        _fpsTimestamp = now;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('自行车姿态分析'),
        backgroundColor: Colors.green,
        actions: [
          // FPS显示
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Text(
                'FPS: ${_fps.toStringAsFixed(1)}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: _buildBottomPanel(),
    );
  }
  
  Widget _buildBody() {
    if (!_isCameraInitialized || _cameraController == null) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }
    
    return Stack(
      fit: StackFit.expand,
      children: [
        // 摄像头预览
        CameraPreview(_cameraController!),
        
        // 骨架图叠加
        if (_currentPoseData != null)
          CustomPaint(
            painter: sp.SkeletonPainter(
              poseData: _currentPoseData,
              angleData: _currentAngleData,
              imageSize: Size(
                _cameraController!.value.previewSize!.height,
                _cameraController!.value.previewSize!.width,
              ),
            ),
          ),
        
        // 顶部信息栏
        Positioned(
          top: 16,
          left: 16,
          right: 16,
          child: _buildInfoCard(),
        ),
      ],
    );
  }
  
  Widget _buildInfoCard() {
    return Card(
      color: Colors.black54,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '实时角度数据',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            if (_currentAngleData != null) ...[
              _buildAngleRow(
                '肩部到手腕角度',
                _currentAngleData!.shoulderWristAngle,
              ),
              _buildAngleRow(
                '肘关节角度',
                _currentAngleData!.elbowAngle,
              ),
              _buildAngleRow(
                '膝关节角度',
                _currentAngleData!.kneeAngle,
              ),
            ] else
              const Text(
                '等待检测...',
                style: TextStyle(color: Colors.white70),
              ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildAngleRow(String label, double angle) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white),
          ),
          Text(
            '${angle.toStringAsFixed(1)}°',
            style: const TextStyle(
              color: Colors.greenAccent,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildBottomPanel() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      color: Colors.black87,
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'AI Bike Fitting',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              '请保持侧面骑行姿势',
              style: TextStyle(color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }
  
  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('需要摄像头权限'),
        content: const Text('请在设置中允许访问摄像头以使用此功能。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: const Text('打开设置'),
          ),
        ],
      ),
    );
  }
  
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('错误'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }
}
