#!/bin/bash
# ============================================================================
#  打包部署文件
#  把编译产物 + 运行时依赖 打包成最终可部署的目录
# ============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${SCRIPT_DIR}/config.sh"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo ""
echo "--- 打包部署文件 ---"

# 清理并创建输出目录
DEPLOY="$OUTPUT_DIR/deploy-final"
rm -rf "$DEPLOY"
mkdir -p "$DEPLOY/lib" "$DEPLOY/alpr/model"

# 1. Qt 主程序
if [ -f "$BUILD_DIR/qt/Gec6818SmartGate" ]; then
    cp "$BUILD_DIR/qt/Gec6818SmartGate" "$DEPLOY/"
    chmod +x "$DEPLOY/Gec6818SmartGate"
    echo "  ✓ Gec6818SmartGate ($(ls -lh "$DEPLOY/Gec6818SmartGate" | awk '{print $5}'))"
else
    echo "  ✗ Qt 应用不存在: $BUILD_DIR/qt/Gec6818SmartGate"
    exit 1
fi

# 2. alpr + 模型
if [ -f "$BUILD_DIR/HyperLPR/Prj-Linux/lpr/alpr" ]; then
    cp "$BUILD_DIR/HyperLPR/Prj-Linux/lpr/alpr" "$DEPLOY/alpr/"
    chmod +x "$DEPLOY/alpr/alpr"
    echo "  ✓ alpr ($(ls -lh "$DEPLOY/alpr/alpr" | awk '{print $5}'))"
else
    echo "  ✗ alpr 不存在"
    exit 1
fi

if [ -d "$BUILD_DIR/HyperLPR/Prj-Linux/lpr/model" ]; then
    cp "$BUILD_DIR/HyperLPR/Prj-Linux/lpr/model/"* "$DEPLOY/alpr/model/"
    echo "  ✓ alpr/model/ ($(ls "$DEPLOY/alpr/model/" | wc -l) 个文件)"
else
    echo "  ⚠ 模型目录不存在: $BUILD_DIR/HyperLPR/Prj-Linux/lpr/model/"
fi

# 3. OpenCV 运行时库 (部署到 lib/ 子目录，rpath 已设为 \$ORIGIN/lib)
OPENCV_LIBS=(
    libopencv_core.so.3.4
    libopencv_imgproc.so.3.4
    libopencv_imgcodecs.so.3.4
    libopencv_videoio.so.3.4
    libopencv_dnn.so.3.4
    libopencv_objdetect.so.3.4
    libopencv_ml.so.3.4
    libopencv_highgui.so.3.4
)

for lib in "${OPENCV_LIBS[@]}"; do
    if [ -f "$OPENCV_PREFIX/lib/$lib" ]; then
        cp "$OPENCV_PREFIX/lib/$lib" "$DEPLOY/lib/"
    else
        echo "  ⚠ OpenCV 库缺失: $lib"
    fi
done

# 创建 .so -> .so.3.4 的软链接 (有些程序按 .so 找)
# vmhgfs 不支持 symlink，改用 cp; 在板子本地 ext4 上 symlink 没问题
cd "$DEPLOY/lib"
for f in libopencv_core libopencv_imgproc libopencv_imgcodecs \
         libopencv_dnn libopencv_objdetect libopencv_ml \
         libopencv_videoio libopencv_highgui; do
    if [ -e "${f}.so.3.4" ] && [ ! -e "${f}.so" ]; then
        cp "${f}.so.3.4" "${f}.so" 2>/dev/null || true
    fi
done
cd - >/dev/null

echo "  ✓ lib/ ($(ls "$DEPLOY/lib/" | wc -l) 个文件)"

# 4. 生成部署包 (tar.gz)
DEPLOY_TAR="$OUTPUT_DIR/smartgate-deploy.tar.gz"
echo ""
echo "  打包 tar.gz..."
cd "$OUTPUT_DIR"
# --ignore-failed-read: 忽略打包时模型文件可能还在写入的警告
tar czf "$DEPLOY_TAR" --ignore-failed-read deploy-final/

echo ""
echo "  ${GREEN}部署包生成完毕${NC}"
echo "  位置: $DEPLOY_TAR"
echo "  大小: $(ls -lh "$DEPLOY_TAR" | awk '{print $5}')"
echo ""
echo "  部署到开发板:"
echo "    1. 拷贝到 U 盘: cp $DEPLOY_TAR /media/\$USER/USB/"
echo "    2. 板子上: mkdir -p /opt && cd /opt && tar xzf /mnt/usb/smartgate-deploy.tar.gz"
echo "    3. 运行: cd /opt && ./Gec6818SmartGate"
