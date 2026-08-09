# Android ARM64 Build Fix

解决在 ARM64 (aarch64) 架构上构建 Android 项目时遇到的 AAPT2 `Illegal instruction` 问题。

## 问题原因

Android SDK 的 AAPT2 工具仅提供 x86_64 架构的 Linux 二进制文件。当在 ARM64 环境中运行时，会因指令集不兼容导致崩溃。

```
Illegal instruction (core dumped) [aapt2]
exit code 132
```

## 解决方案

### 方案 1: 使用 x86_64 GitHub Actions Runner (推荐)

最简单、最稳定的方案。GitHub Actions 默认提供 x86_64 的 Ubuntu runner。

**适用场景**: 构建目标 APK 兼容 ARM64 设备，但构建环境可以使用 x86_64

```yaml
jobs:
  build:
    runs-on: ubuntu-latest  # x86_64
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-java@v4
        with:
          java-version: '17'
          distribution: 'temurin'
      - run: ./gradlew assembleDebug
```

### 方案 2: 使用 Box64 模拟器

在 ARM64 环境中通过 Box64 模拟 x86_64 指令集。

**适用场景**: 必须在 ARM64 原生环境构建

```bash
# 安装 Box64
sudo apt-get update
sudo apt-get install -y wget git build-essential cmake
git clone --depth 1 https://github.com/ptitSeb/box64.git
cd box64 && mkdir build && cd build
cmake .. -DCMAKE_BUILD_TYPE=RelWithDebInfo
make -j$(nproc)
sudo make install
sudo ldconfig

# 使用 Box64 运行 Gradle
BOX64_LOG=0 ./gradlew assembleDebug
```

### 方案 3: 使用 ARM64 原生构建工具

安装专门编译的 ARM64 版本 AAPT2 等工具。

**适用场景**: 长期在 ARM64 服务器构建

```bash
# 自动安装 ARM64 版本的构建工具
curl -fsSL https://raw.githubusercontent.com/Commit451/android-arm-build-tools/main/install.sh | bash
```

### 方案 4: 使用 Docker + QEMU

通过 Docker 模拟 x86_64 环境。

```yaml
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: docker/setup-qemu-action@v3
      - uses: docker/build-push-action@v5
        with:
          platforms: linux/amd64
          context: .
          push: false
```

## GitHub Actions 工作流

本仓库提供了完整的工作流配置文件:

| 文件 | 说明 | 推荐度 |
|------|------|--------|
| `.github/workflows/build.yml` | 包含 3 种方案的完整配置 | ⭐⭐⭐⭐⭐ |

## 快速开始

### 1. 克隆或 Fork 此仓库

```bash
git clone https://github.com/ghtrxv/android-arm64-build-fix.git
cd android-arm64-build-fix
```

### 2. 复制工作流到你的项目

```bash
cp -r .github/workflows /path/to/your/android-project/
```

### 3. 选择适合你的方案并推送

在 GitHub 仓库的 Actions 标签页查看构建结果。

## 本地 ARM64 环境修复

### 手动修复步骤

```bash
# 1. 安装依赖
sudo apt-get update
sudo apt-get install -y box64

# 2. 设置环境变量
export BOX64_LOG=0

# 3. 运行构建
./gradlew assembleDebug
```

## 参考资料

- [Commit451/android-arm-build-tools](https://github.com/Commit451/android-arm-build-tools)
- [Box64 - x86_64 Emulator](https://github.com/ptitSeb/box64)
- [Android Gradle Plugin 文档](https://developer.android.com/build)
- [GitHub Actions 文档](https://docs.github.com/en/actions)

## 常见问题

### Q: 为什么 GitHub Actions 的 runner 是 x86_64 而不是 ARM64?

GitHub 的 Ubuntu runner (`ubuntu-latest`) 目前基于 x86_64 架构，这正好可以解决 AAPT2 的兼容性问题。

### Q: 构建出来的 APK 能在 ARM64 设备上运行吗?

可以。APK 的架构兼容性由 `abiFilters` 配置决定，与构建环境无关。

## 许可证

MIT