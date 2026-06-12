#!/bin/bash
# ============================================================================
#  编译 alpr 车牌识别引擎 (HyperLPR)
# ============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${SCRIPT_DIR}/config.sh"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo ""
echo "--- 编译 alpr 车牌识别 ---"

# 1. 解压 HyperLPR 源码
HYPERLPR_EXTRACT="$BUILD_DIR/HyperLPR"
if [ ! -d "$HYPERLPR_EXTRACT/Prj-Linux/lpr" ]; then
    echo "  解压 HyperLPR 源码..."
    mkdir -p "$BUILD_DIR"
    cd "$BUILD_DIR"
    if command -v unzip >/dev/null 2>&1; then
        unzip -q -o "$HYPERLPR_ZIP"
    else
        python3 -c "import zipfile; zipfile.ZipFile('$HYPERLPR_ZIP').extractall('$BUILD_DIR')"
    fi
    if [ ! -d "$HYPERLPR_EXTRACT/Prj-Linux/lpr" ]; then
        TOP_DIR=$(ls -d "$BUILD_DIR"/HyperLPR* "$BUILD_DIR"/zeusees* 2>/dev/null | head -1)
        if [ -n "$TOP_DIR" ] && [ -d "$TOP_DIR/Prj-Linux/lpr" ]; then
            HYPERLPR_EXTRACT="$TOP_DIR"
        else
            echo "  解压后未找到 Prj-Linux/lpr 目录"
            ls -la "$BUILD_DIR"
            exit 1
        fi
    fi
fi

LPR_SRC="$HYPERLPR_EXTRACT/Prj-Linux/lpr"
LPR_BUILD="$BUILD_DIR/alpr-build"

# 2. 替换 main.cpp (管道版)
echo "  替换 main.cpp 为管道版..."
cp "$PROJECT_SRC_DIR/src/alpr_main.cpp" "$LPR_SRC/main.cpp"

# 3. 完全重写 CMakeLists.txt (用 printf 避免 bash 变量展开)
echo "  重写 CMakeLists.txt..."
printf '%s\n' \
'cmake_minimum_required(VERSION 3.6)' \
'project(HyperLPR-Linux)' \
'' \
'set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=c++11")' \
'set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR})' \
'' \
'# 收集所有源文件' \
'set(SRC_DETECTION src/PlateDetection.cpp src/util.h include/PlateDetection.h)' \
'set(SRC_FINEMAPPING src/FineMapping.cpp)' \
'set(SRC_FASTDESKEW src/FastDeskew.cpp)' \
'set(SRC_SEGMENTATION src/PlateSegmentation.cpp)' \
'set(SRC_RECOGNIZE src/Recognizer.cpp src/CNNRecognizer.cpp)' \
'set(SRC_PIPLINE src/Pipeline.cpp)' \
'set(SRC_SEGMENTATIONFREE src/SegmentationFreeRecognizer.cpp)' \
'' \
'# 主目标：alpr' \
'add_executable(alpr main.cpp' \
'    ${SRC_DETECTION}' \
'    ${SRC_FINEMAPPING}' \
'    ${SRC_FASTDESKEW}' \
'    ${SRC_SEGMENTATION}' \
'    ${SRC_RECOGNIZE}' \
'    ${SRC_PIPLINE}' \
'    ${SRC_SEGMENTATIONFREE}' \
')' \
'' \
'# 包含头文件路径' \
'target_include_directories(alpr PRIVATE' \
'    ${CMAKE_CURRENT_SOURCE_DIR}/include' \
"    $OPENCV_PREFIX/tools/opencv/include" \
"    $OPENCV_PREFIX/tools/opencv/include/opencv" \
')' \
'' \
'# 链接 OpenCV 库 (全部链接，避免链式依赖问题)' \
'target_link_libraries(alpr' \
"    $OPENCV_PREFIX/lib/libopencv_calib3d.so.3.4" \
"    $OPENCV_PREFIX/lib/libopencv_core.so.3.4" \
"    $OPENCV_PREFIX/lib/libopencv_dnn.so.3.4" \
"    $OPENCV_PREFIX/lib/libopencv_features2d.so.3.4" \
"    $OPENCV_PREFIX/lib/libopencv_flann.so.3.4" \
"    $OPENCV_PREFIX/lib/libopencv_highgui.so.3.4" \
"    $OPENCV_PREFIX/lib/libopencv_imgcodecs.so.3.4" \
"    $OPENCV_PREFIX/lib/libopencv_imgproc.so.3.4" \
"    $OPENCV_PREFIX/lib/libopencv_ml.so.3.4" \
"    $OPENCV_PREFIX/lib/libopencv_objdetect.so.3.4" \
"    $OPENCV_PREFIX/lib/libopencv_photo.so.3.4" \
"    $OPENCV_PREFIX/lib/libopencv_shape.so.3.4" \
"    $OPENCV_PREFIX/lib/libopencv_stitching.so.3.4" \
"    $OPENCV_PREFIX/lib/libopencv_superres.so.3.4" \
"    $OPENCV_PREFIX/lib/libopencv_video.so.3.4" \
"    $OPENCV_PREFIX/lib/libopencv_videoio.so.3.4" \
"    $OPENCV_PREFIX/lib/libopencv_videostab.so.3.4" \
')' \
'' \
'# rpath: alpr 在 alpr/ 子目录，库在 lib/ 同级' \
"set_target_properties(alpr PROPERTIES" \
'    LINK_FLAGS "-Wl,-rpath,$ORIGIN/.. -Wl,-rpath,$ORIGIN/../lib")' \
> "$LPR_SRC/CMakeLists.txt"

echo "  ✓ CMakeLists.txt 已重写"

# 4. 编译
mkdir -p "$LPR_BUILD"
cd "$LPR_BUILD"

echo "  运行 cmake..."
export LD_LIBRARY_PATH="$TOOLCHAIN_DIR/usr/lib"

cmake "$LPR_SRC" \
    -DCMAKE_TOOLCHAIN_FILE="$PROJECT_SRC_DIR/toolchain-gec6818.cmake" \
    2>&1 | tail -15

if [ $? -ne 0 ]; then
    echo "  cmake 配置失败"
    cat "$LPR_BUILD/CMakeFiles/CMakeError.log" 2>/dev/null | tail -20 || true
    exit 1
fi

echo "  编译中..."
make -j"$(nproc)" 2>&1 | grep -vE "^(Scanning dependencies|Built target)" | tail -30

# 检查产物
if [ -f "$LPR_SRC/alpr" ]; then
    echo -e "  ${GREEN}✓ alpr 编译成功${NC}"
    echo "    大小: $(ls -lh "$LPR_SRC/alpr" | awk '{print $5}')"
    file "$LPR_SRC/alpr"
else
    echo -e "  ${RED}✗ alpr 编译失败${NC}"
    ls -la "$LPR_SRC/" 2>/dev/null | grep -E "^-.*alpr"
    exit 1
fi
