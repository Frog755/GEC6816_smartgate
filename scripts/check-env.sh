#!/bin/bash
# ============================================================================
#  环境检查脚本
#  检查所有必需的依赖是否齐全，提前报错而不是编译中途失败
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${SCRIPT_DIR}/config.sh"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo ""
echo "========================================"
echo "  GEC6818 交叉编译环境检查"
echo "========================================"

ERRORS=0

# 检查函数
check_file() {
    local name="$1" path="$2"
    if [ -f "$path" ]; then
        echo -e "  ${GREEN}✓${NC} $name: $path"
    else
        echo -e "  ${RED}✗${NC} $name: $path  (不存在)"
        ERRORS=$((ERRORS + 1))
    fi
}

check_dir() {
    local name="$1" path="$2"
    if [ -d "$path" ]; then
        echo -e "  ${GREEN}✓${NC} $name: $path"
    else
        echo -e "  ${RED}✗${NC} $name: $path  (不存在)"
        ERRORS=$((ERRORS + 1))
    fi
}

# 1. 交叉编译器
check_file "交叉编译器" "$TOOLCHAIN_DIR/usr/bin/arm-linux-g++"
check_file "C 编译器" "$TOOLCHAIN_DIR/usr/bin/arm-linux-gcc"

# 2. 工具链库 (libmpfr 是常见缺失依赖)
TOOLCHAIN_LIB="$TOOLCHAIN_DIR/usr/lib/libmpfr.so.4"
if [ ! -f "$TOOLCHAIN_LIB" ]; then
    # 可能在 lib32/ 下
    TOOLCHAIN_LIB="$TOOLCHAIN_DIR/usr/lib32/libmpfr.so.4"
    if [ -f "$TOOLCHAIN_LIB" ]; then
        check_file "工具链 lib" "$TOOLCHAIN_LIB"
    else
        # 检查 sysroot 中
        TOOLCHAIN_LIB="$TOOLCHAIN_DIR/usr/arm-none-linux-gnueabi/sysroot/usr/lib/libmpfr.so.4"
        if [ -f "$TOOLCHAIN_LIB" ]; then
            check_file "工具链 lib" "$TOOLCHAIN_LIB"
        else
            echo -e "  ${YELLOW}!${NC} libmpfr.so.4 未找到 (可能不需要)"
        fi
    fi
else
    check_file "工具链 lib" "$TOOLCHAIN_LIB"
fi

# 3. Qt-Embedded
QT_LIB="$QTE_PREFIX/lib/libQt5Core.so.5"
if [ -d "$QTE_PREFIX/lib" ] && [ -f "$QT_LIB" ]; then
    echo -e "  ${GREEN}✓${NC} Qt-Embedded: $QTE_PREFIX (lib OK)"
    # 检查 platform 插件
    if [ -f "$QTE_PREFIX/plugins/platforms/libqeglfs.so" ]; then
        echo -e "  ${GREEN}  ✓${NC} platform 插件: libqeglfs.so"
    else
        echo -e "  ${YELLOW}!${NC} platform 插件可能缺失"
    fi
else
    echo -e "  ${RED}✗${NC} Qt-Embedded: $QTE_PREFIX"
    ERRORS=$((ERRORS + 1))
fi

# 4. OpenCV
if [ -d "$OPENCV_PREFIX/lib" ] && [ -d "$OPENCV_PREFIX/tools/opencv/include" ]; then
    echo -e "  ${GREEN}✓${NC} OpenCV: $OPENCV_PREFIX"
else
    echo -e "  ${RED}✗${NC} OpenCV: $OPENCV_PREFIX (lib 或 include 缺失)"
    ERRORS=$((ERRORS + 1))
fi

# 5. x86 MOC
if [ -f "$X86_MOC" ]; then
    echo -e "  ${GREEN}✓${NC} x86 MOC: $X86_MOC"
else
    # 尝试自动查找
    AUTO_MOC=$(find /usr -name moc -path "*/qt5/bin/moc" 2>/dev/null | head -1)
    if [ -n "$AUTO_MOC" ]; then
        echo -e "  ${YELLOW}!${NC} 找不到 $X86_MOC，但自动找到: $AUTO_MOC"
        echo -e "  ${YELLOW}  建议: 在 config.sh 中设置 X86_MOC=$AUTO_MOC"
    else
        echo -e "  ${RED}✗${NC} x86 MOC: $X86_MOC (不存在)"
        echo -e "  ${YELLOW}  安装: sudo apt install qt5-qmake"
    fi
fi

# 6. 项目源码
if [ -f "$PROJECT_SRC_DIR/CMakeLists.txt" ]; then
    echo -e "  ${GREEN}✓${NC} 项目源码: $PROJECT_SRC_DIR"
else
    echo -e "  ${RED}✗${NC} 项目源码: $PROJECT_SRC_DIR (CMakeLists.txt 缺失)"
    ERRORS=$((ERRORS + 1))
fi

# 7. 工具
for cmd in cmake make unzip; do
    if command -v "$cmd" >/dev/null 2>&1; then
        version=$("$cmd" --version 2>&1 | head -1)
        echo -e "  ${GREEN}✓${NC} $cmd: $version"
    else
        echo -e "  ${RED}✗${NC} $cmd: 未安装 (sudo apt install $cmd)"
        ERRORS=$((ERRORS + 1))
    fi
done

# 8. HyperLPR
if [ -f "$HYPERLPR_ZIP" ]; then
    echo -e "  ${GREEN}✓${NC} HyperLPR zip: $(ls -lh "$HYPERLPR_ZIP" | awk '{print $5}')"
else
    echo -e "  ${RED}✗${NC} HyperLPR zip: $HYPERLPR_ZIP (不存在)"
    ERRORS=$((ERRORS + 1))
fi

echo ""
if [ $ERRORS -gt 0 ]; then
    echo -e "  ${RED}发现 $ERRORS 个错误，请修正后重试${NC}"
    exit 1
else
    echo -e "  ${GREEN}所有依赖齐全，可以开始编译${NC}"
    exit 0
fi
