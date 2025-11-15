# GitHub Actions 自动构建指南

## 🚀 快速开始

无需本地Flutter环境！通过GitHub Actions自动构建Android APK。

### 第一步：上传代码到GitHub

1. 创建新的GitHub仓库：
   ```bash
   # 在GitHub上创建仓库 bike-fitting-android
   ```

2. 上传项目代码：
   ```bash
   git init
   git add .
   git commit -m "Initial commit: Flutter bike fitting app"
   git branch -M main
   git remote add origin https://github.com/YOUR_USERNAME/bike-fitting-android.git
   git push -u origin main
   ```

### 第二步：启用Actions

1. 进入GitHub仓库页面
2. 点击 "Actions" 标签
3. GitHub会自动检测 `.github/workflows/build-android.yml` 文件
4. 点击 "Enable" 启用Actions

### 第三步：触发构建

每次推送代码到main分支，Actions会自动：
1. 安装Flutter环境
2. 分析代码
3. 运行测试
4. 构建APK
5. 上传APK文件到Artifacts

### 第四步：下载APK

构建完成后：
1. 进入Actions页面
2. 点击最新的workflow run
3. 向下滚动到 "Artifacts" 部分
4. 下载对应的APK文件：
   - `app-arm64-release.apk` - 适用于现代64位Android设备
   - `app-armeabi-v7a-release.apk` - 适用于大多数Android设备
   - `app-x86_64-release.apk` - 适用于64位模拟器

### 第五步：安装和测试

1. **传输APK到手机**
   - 通过邮件、微信、QQ等方式发送APK文件

2. **安装APK**
   ```bash
   # 或在手机上直接点击APK文件安装
   adb install app-arm64-release.apk
   ```

3. **权限设置**
   - 首次启动时会请求摄像头权限，请选择"允许"

### 📱 测试验证清单

在Android设备上测试时请验证：
- [ ] 应用启动正常
- [ ] 摄像头权限请求正常
- [ ] 摄像头预览画面显示
- [ ] 姿态检测能够识别人体关键点
- [ ] 绿色骨架图正确叠加在视频上
- [ ] 角度数值实时更新显示（肩部-手腕角度、肘部角度、膝部角度）
- [ ] FPS显示正常工作
- [ ] 应用运行流畅，无崩溃或卡顿

### 🔧 自定义构建

如需修改构建配置，编辑 `.github/workflows/build-android.yml` 文件：

- **Flutter版本：** 修改 `flutter-version: '3.24.0'`
- **Java版本：** 修改 `java-version: '11'`
- **构建类型：** 修改 `--release` 为 `--debug`（调试版）
- **架构支持：** 修改 `--split-per-abi` 控制架构

### ⚠️ 注意事项

1. **GitHub Actions免费额度**：每月2000分钟构建时间
2. **构建时间**：通常需要5-10分钟完成
3. **APK大小**：约20-30MB（包含MediaPipe模型）
4. **兼容性**：需要Android 5.0+ (API level 21+)

### 🆘 故障排除

如果构建失败：

1. **检查Actions日志**
   - 点击失败的workflow run
   - 查看具体的错误信息

2. **常见问题**
   - `pubspec.yaml` 依赖问题 → 更新依赖版本
   - 代码语法错误 → 运行 `flutter analyze` 检查
   - 权限问题 → 检查GitHub Actions权限设置

3. **获取帮助**
   - 查看Flutter文档：https://flutter.dev/docs
   - 查看Actions文档：https://docs.github.com/en/actions

### 📈 持续集成

该配置实现了：
- ✅ 自动化代码检查
- ✅ 自动化测试
- ✅ 自动化构建
- ✅ 多架构APK生成
- ✅ 工件自动保存

每次代码更新都会自动构建最新版本的APK！