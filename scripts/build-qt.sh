#!/bin/bash
# ============================================================================
#  编译 Qt 应用 (Gec6818SmartGate)
# ============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${SCRIPT_DIR}/config.sh"

# 加载配置
source "${SCRIPT_DIR}/config.sh"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo ""
echo "--- 编译 Qt 应用 ---"

# 创建构建目录
mkdir -p "$BUILD_DIR/qt"
cd "$BUILD_DIR/qt"

# cmake 配置
cmake "$PROJECT_SRC_DIR" \
    -DCROSS_COMPILE=ON \
    -DTOOLCHAIN_DIR="$TOOLCHAIN_DIR" \
    -DQTE_PREFIX="$QTE_PREFIX" \
    -DOPENCV_PREFIX="$OPENCV_PREFIX" \
    -DX86_MOC="$X86_MOC" \
    2>&1 | grep -E "(CMake 错误|CMake Warning|-- )" | tail -20

# 编译 (需要设置 LD_LIBRARY_PATH 让编译器找到 libmpfr.so.4)
export LD_LIBRARY_PATH="$TOOLCHAIN_DIR/usr/lib"
make -j"$(nproc)" 2>&1 | grep -vE "^(arm-linux-g\+\+: WARNING:|/usr/local/arm|Scanning dependencies|Built target)" | tail -30

# 检查产物
if [ -f "$BUILD_DIR/qt/Gec6818SmartGate" ]; then
    echo -e "  ${GREEN}✓ Qt 应用编译成功${NC}"
    echo "    大小: $(ls -lh "$BUILD_DIR/qt/Gec6818SmartGate" | awk '{print $5}')"
    file "$BUILD_DIR/qt/Gec6818SmartGate"
else
    echo -e "  ${RED}✗ Qt 应用编译失败${NC}"
    exit 1
fi
