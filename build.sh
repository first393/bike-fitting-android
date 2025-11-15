#!/bin/bash

# 自行车姿态分析 Flutter 项目快速构建脚本

echo "======================================"
echo "  自行车姿态分析 Flutter Android 应用"
echo "  快速构建脚本"
echo "======================================"
echo ""

# 检查 Flutter 环境
echo "[1/6] 检查 Flutter 环境..."
if ! command -v flutter &> /dev/null; then
    echo "❌ 错误: Flutter 未安装或未添加到 PATH"
    echo "请先安装 Flutter: https://docs.flutter.dev/get-started/install"
    exit 1
fi
echo "✅ Flutter 已安装"
flutter --version
echo ""

# 进入项目目录
echo "[2/6] 进入项目目录..."
cd "$(dirname "$0")"
echo "✅ 当前目录: $(pwd)"
echo ""

# 安装依赖
echo "[3/6] 安装 Flutter 依赖..."
flutter pub get
if [ $? -ne 0 ]; then
    echo "❌ 错误: 依赖安装失败"
    exit 1
fi
echo "✅ 依赖安装成功"
echo ""

# 检查设备连接
echo "[4/6] 检查 Android 设备..."
flutter devices
if [ $? -ne 0 ]; then
    echo "⚠️  警告: 未检测到 Android 设备或模拟器"
    echo "请连接设备或启动模拟器后继续"
fi
echo ""

# 选择构建类型
echo "[5/6] 选择构建类型:"
echo "  1) 调试版本 (Debug) - 快速构建，用于测试"
echo "  2) 发布版本 (Release) - 优化构建，用于分发"
echo "  3) 直接运行到设备"
echo ""
read -p "请选择 (1/2/3): " choice

case $choice in
    1)
        echo ""
        echo "构建调试版本 APK..."
        flutter build apk --debug
        if [ $? -eq 0 ]; then
            echo "✅ 构建成功！"
            echo "APK 路径: build/app/outputs/flutter-apk/app-debug.apk"
        else
            echo "❌ 构建失败"
            exit 1
        fi
        ;;
    2)
        echo ""
        echo "构建发布版本 APK..."
        flutter build apk --release
        if [ $? -eq 0 ]; then
            echo "✅ 构建成功！"
            echo "APK 路径: build/app/outputs/flutter-apk/app-release.apk"
        else
            echo "❌ 构建失败"
            exit 1
        fi
        ;;
    3)
        echo ""
        echo "直接运行到设备..."
        flutter run --release
        exit 0
        ;;
    *)
        echo "❌ 无效选择"
        exit 1
        ;;
esac

echo ""
echo "[6/6] 是否安装到设备? (y/n)"
read -p "请选择: " install_choice

if [ "$install_choice" = "y" ] || [ "$install_choice" = "Y" ]; then
    echo ""
    echo "安装到设备..."
    flutter install
    if [ $? -eq 0 ]; then
        echo "✅ 安装成功！"
    else
        echo "❌ 安装失败"
        echo "可以手动使用 adb install 命令安装 APK"
    fi
fi

echo ""
echo "======================================"
echo "  构建完成！"
echo "======================================"
echo ""
echo "下一步:"
echo "  1. 如果构建了 APK，可以在 build/app/outputs/flutter-apk/ 目录找到"
echo "  2. 传输 APK 到手机并安装"
echo "  3. 首次运行时授予摄像头权限"
echo "  4. 等待 ML Kit 模型下载（需要网络）"
echo ""
echo "详细使用说明请查看 README.md"
echo ""
