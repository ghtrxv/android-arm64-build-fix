#!/bin/bash
# ARM64 环境 Android 构建修复脚本
# 解决 AAPT2 Illegal instruction 问题

set -e

echo "========================================"
echo "  Android ARM64 Build Fix Script"
echo "========================================"
echo ""
echo "Architecture: $(uname -m)"
echo "Date: $(date)"
echo ""

# 检查是否是 ARM64
if [ "$(uname -m)" != "aarch64" ] && [ "$(uname -m)" != "arm64" ]; then
    echo "⚠️  这不是 ARM64 环境，可能不需要此脚本"
    echo "   当前架构: $(uname -m)"
    echo ""
    echo "如果使用 GitHub Actions，可以直接使用默认的 ubuntu-latest runner"
    echo "(它是 x86_64 架构，原生支持 AAPT2)"
fi

# 显示菜单
echo "请选择解决方案:"
echo ""
echo "  1. 使用 GitHub Actions (推荐 - 最简单)"
echo "  2. 本地安装 Box64 (模拟 x86_64)"
echo "  3. 本地安装 ARM64 原生构建工具"
echo "  4. 查看详细说明"
echo "  0. 退出"
echo ""

read -p "请选择 [0-4]: " choice

case $choice in
    1)
        echo ""
        echo "📋 GitHub Actions 配置步骤:"
        echo ""
        echo "1. 创建 .github/workflows/build.yml 文件:"
        echo "cat > .github/workflows/build.yml << 'EOF'
name: Android Build

on: [push, pull_request]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-java@v4
        with:
          java-version: '17'
          distribution: 'temurin'
          cache: gradle
      - run: chmod +x ./gradlew
      - run: ./gradlew assembleDebug
      - uses: actions/upload-artifact@v4
        with:
          name: app-debug
          path: app/build/outputs/apk/debug/*.apk
EOF
"
        echo ""
        echo "2. 推送到 GitHub:"
        echo "   git add ."
        echo "   git commit -m 'Add GH Actions workflow'"
        echo "   git push"
        echo ""
        echo "✅ 推送后，GitHub Actions 会自动构建!"
        ;;
    
    2)
        echo ""
        echo "📦 安装 Box64..."
        echo ""
        sudo apt-get update
        sudo apt-get install -y wget git build-essential cmake
        
        echo ""
        echo "克隆 Box64..."
        cd /tmp
        if [ ! -d "box64" ]; then
            git clone --depth 1 https://github.com/ptitSeb/box64.git
        fi
        
        echo ""
        echo "编译安装 Box64..."
        cd box64
        mkdir -p build && cd build
        cmake .. -DCMAKE_BUILD_TYPE=RelWithDebInfo
        make -j$(nproc)
        sudo make install
        sudo ldconfig
        
        echo ""
        echo "✅ Box64 安装完成!"
        echo ""
        echo "使用方法:"
        echo "  export BOX64_LOG=0"
        echo "  ./gradlew assembleDebug"
        ;;
    
    3)
        echo ""
        echo "📦 安装 ARM64 原生构建工具..."
        echo ""
        echo "下载 ARM64 版本的 AAPT2、aidl、zipalign 等工具"
        curl -fsSL https://raw.githubusercontent.com/Commit451/android-arm-build-tools/main/install.sh | bash
        echo ""
        echo "✅ ARM64 构建工具已安装!"
        echo ""
        echo "使用方法:"
        echo "  ./gradlew assembleDebug"
        ;;
    
    4)
        echo ""
        echo "📖 详细说明:"
        echo ""
        echo "问题原因:"
        echo "  - Android SDK 的 AAPT2 工具仅提供 x86_64 架构的二进制文件"
        echo "  - 在 ARM64 环境运行时，会因为指令集不兼容导致 Illegal instruction"
        echo ""
        echo "解决方案对比:"
        echo "  方案 1: GitHub Actions (最简单)"
        echo "    - 优点: 零配置，最快，最稳定"
        echo "    - 缺点: 需要网络，APK 上传到 GitHub"
        echo ""
        echo "  方案 2: Box64 模拟"
        echo "    - 优点: 本地运行，速度快"
        echo "    - 缺点: 需要编译安装，占用空间"
        echo ""
        echo "  方案 3: ARM64 原生工具"
        echo "    - 优点: 最接近原生体验"
        echo "    - 缺点: 工具版本可能滞后"
        echo ""
        ;;
    
    0)
        echo ""
        echo "👋 再见!"
        exit 0
        ;;
    
    *)
        echo ""
        echo "❌ 无效选择"
        ;;
esac

echo ""
echo "========================================"
echo "  完成!"
echo "========================================"
echo ""
echo "💡 提示: 对于大多数用户，推荐使用 GitHub Actions 方案"
echo ""
