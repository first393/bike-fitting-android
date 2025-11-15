# Flutter Android 应用部署指南

## 构建和部署流程

### 前置条件

1. **Flutter 环境**
   ```bash
   # 检查 Flutter 环境
   flutter doctor
   
   # 确保所有项都通过（至少 Flutter 和 Android toolchain）
   ```

2. **Android 设备或模拟器**
   - 真机：启用开发者模式和 USB 调试
   - 模拟器：创建 AVD（Android Virtual Device）

### 步骤 1: 获取依赖

```bash
cd /workspace/bike_fitting_flutter
flutter pub get
```

### 步骤 2: 构建 APK

#### 调试版本（用于测试）

```bash
flutter build apk --debug
```

输出路径：`build/app/outputs/flutter-apk/app-debug.apk`

#### 发布版本（用于分发）

```bash
flutter build apk --release
```

输出路径：`build/app/outputs/flutter-apk/app-release.apk`

#### 构建 App Bundle（推荐用于 Google Play）

```bash
flutter build appbundle --release
```

输出路径：`build/app/outputs/bundle/release/app-release.aab`

### 步骤 3: 安装到设备

#### 方法 1：使用 Flutter 命令（推荐）

```bash
# 连接设备后直接安装并运行
flutter install

# 或者
flutter run --release
```

#### 方法 2：使用 ADB 命令

```bash
# 检查设备连接
adb devices

# 安装 APK
adb install build/app/outputs/flutter-apk/app-release.apk

# 如果已安装，使用 -r 覆盖安装
adb install -r build/app/outputs/flutter-apk/app-release.apk
```

#### 方法 3：手动传输

1. 将 APK 文件复制到手机
2. 在手机文件管理器中找到 APK
3. 点击安装（需要允许安装未知来源应用）

### 步骤 4: 首次运行

1. 打开应用
2. 授予摄像头权限
3. 等待 ML Kit 模型下载（需要网络连接，约 20MB）
4. 开始使用

## 签名配置（可选）

用于发布到应用商店时：

### 1. 生成密钥库

```bash
keytool -genkey -v -keystore ~/bike-fitting-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias bike-fitting
```

### 2. 创建密钥配置文件

在 `android/` 目录创建 `key.properties`：

```properties
storePassword=你的密码
keyPassword=你的密码
keyAlias=bike-fitting
storeFile=/path/to/bike-fitting-key.jks
```

### 3. 修改 build.gradle

在 `android/app/build.gradle` 中添加：

```gradle
def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file('key.properties')
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}

android {
    ...
    signingConfigs {
        release {
            keyAlias keystoreProperties['keyAlias']
            keyPassword keystoreProperties['keyPassword']
            storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
            storePassword keystoreProperties['storePassword']
        }
    }
    buildTypes {
        release {
            signingConfig signingConfigs.release
        }
    }
}
```

## 优化建议

### 1. 减小 APK 体积

```bash
# 使用代码混淆
flutter build apk --release --obfuscate --split-debug-info=./debug-info

# 构建分架构 APK
flutter build apk --release --split-per-abi
# 会生成：
# - app-armeabi-v7a-release.apk
# - app-arm64-v8a-release.apk
# - app-x86_64-release.apk
```

### 2. 性能优化

在 `android/app/build.gradle` 中：

```gradle
android {
    buildTypes {
        release {
            // 启用代码混淆
            minifyEnabled true
            // 启用资源压缩
            shrinkResources true
            proguardFiles getDefaultProguardFile('proguard-android.txt'), 'proguard-rules.pro'
        }
    }
}
```

## 测试清单

### 安装前测试

- [ ] Flutter doctor 检查通过
- [ ] 依赖安装成功
- [ ] 代码无编译错误

### 安装后测试

- [ ] 应用成功安装
- [ ] 应用图标正常显示
- [ ] 启动无崩溃
- [ ] 摄像头权限请求正常
- [ ] 摄像头预览正常
- [ ] 姿态检测工作正常
- [ ] 骨架图显示正确
- [ ] 角度数据实时更新
- [ ] FPS 显示正常
- [ ] 界面适配不同屏幕尺寸

### 性能测试

- [ ] 应用启动时间 < 3 秒
- [ ] 检测帧率 > 15 FPS
- [ ] 内存占用 < 300MB
- [ ] CPU 占用 < 50%
- [ ] 长时间运行无崩溃（30 分钟+）

## 常见问题

### Q1: 构建失败 "SDK location not found"

**解决方案**：
```bash
# 创建 local.properties
echo "sdk.dir=/path/to/android/sdk" > android/local.properties
echo "flutter.sdk=/path/to/flutter" >> android/local.properties
```

### Q2: 安装失败 "INSTALL_FAILED_UPDATE_INCOMPATIBLE"

**解决方案**：
```bash
# 卸载旧版本
adb uninstall com.bikelab.fitting
# 重新安装
adb install app-release.apk
```

### Q3: 应用闪退

**解决方案**：
```bash
# 查看 logcat 日志
adb logcat | grep -i flutter

# 或使用 Flutter 工具
flutter logs
```

### Q4: ML Kit 模型下载失败

**解决方案**：
- 确保设备联网
- 检查网络连接
- 尝试切换 WiFi/移动数据
- 重启应用

## 分发选项

### 1. 直接分发 APK

适合小范围测试：
- 通过邮件/云盘发送 APK
- 用户手动安装

### 2. Google Play Store

需要：
- 开发者账号（$25 一次性费用）
- 上传 AAB 文件
- 填写应用信息
- 等待审核

### 3. 内部测试平台

- Firebase App Distribution
- TestFlight（iOS）
- 企业内部分发

## 版本管理

更新版本号：

在 `pubspec.yaml` 中：
```yaml
version: 1.0.1+2  # 1.0.1 是版本名，2 是版本号
```

构建时自动应用：
```bash
flutter build apk --release --build-name=1.0.1 --build-number=2
```

## 技术支持

如遇到问题：
1. 查看 README.md 故障排除章节
2. 检查 Flutter 官方文档
3. 查看项目 GitHub Issues

---

**提示**：首次构建可能需要较长时间下载 Gradle 依赖，请耐心等待。
