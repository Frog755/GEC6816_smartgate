#!/bin/bash
# ============================================================================
#  GEC6818 智能闸机系统 - 一键编译打包脚本
#
#  收到这个包后，只需要：
#    1. 编辑 config.sh 填入你的路径
#    2. 运行 ./build-all.sh
#  就会自动完成：检查环境 -> 编译 Qt -> 编译 alpr -> 打包部署
#
#  用法：
#    ./build-all.sh          # 完整流程
#    ./build-all.sh qt       # 只编译 Qt 应用
#    ./build-all.sh alpr     # 只编译 alpr
#    ./build-all.sh deploy   # 只打包部署
#    ./build-all.sh clean    # 清理构建产物
# ============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/config.sh"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

print_step() { echo -e "\n${BOLD}${GREEN}▶${NC} ${BOLD}$1${NC}"; }
print_ok()   { echo -e "  ${GREEN}✓${NC} $1"; }
print_err()  { echo -e "  ${RED}✗${NC} $1"; }
print_info() { echo -e "  ${CYAN}ℹ${NC} $1"; }

# ---- banner ----
echo ""
echo -e "${BOLD}${CYAN}╔══════════════════════════════════════════════════╗${NC}"
echo -e "${BOLD}${CYAN}║${NC}       GEC6818 智能闸机系统 - 构建脚本${NC}           ${BOLD}${CYAN}║${NC}"
echo -e "${BOLD}${CYAN}║${NC}  一键编译 + 打包 + 部署${NC}                         ${BOLD}${CYAN}║${NC}"
echo -e "${BOLD}${CYAN}╚══════════════════════════════════════════════════╝${NC}"
echo ""

# ---- 检查参数 ----
case "${1:-all}" in
    clean)
        print_step "清理构建产物"
        rm -rf "$BUILD_DIR"
        rm -rf "$OUTPUT_DIR"
        print_ok "已清理 $BUILD_DIR 和 $OUTPUT_DIR"
        exit 0
        ;;
    qt)  BUILD_QT=1; BUILD_ALPR=0; DO_DEPLOY=1 ;;
    alpr) BUILD_QT=0; BUILD_ALPR=1; DO_DEPLOY=1 ;;
    deploy) BUILD_QT=0; BUILD_ALPR=0; DO_DEPLOY=1 ;;
    all)  BUILD_QT=1; BUILD_ALPR=1; DO_DEPLOY=1 ;;
    *)
        echo "用法: $0 [all|qt|alpr|deploy|clean]"
        exit 1
        ;;
esac

# ---- 创建目录 ----
mkdir -p "$BUILD_DIR" "$OUTPUT_DIR"

# ---- 第一步：环境检查 ----
if [ $BUILD_QT -eq 1 ] || [ $BUILD_ALPR -eq 1 ] || [ $DO_DEPLOY -eq 1 ]; then
    print_step "环境检查"
    bash "${SCRIPT_DIR}/scripts/check-env.sh"
fi

# ---- 第二步：编译 Qt 应用 ----
if [ $BUILD_QT -eq 1 ]; then
    print_step "编译 Qt 应用 (Gec6818SmartGate)"
    bash "${SCRIPT_DIR}/scripts/build-qt.sh"
fi

# ---- 第三步：编译 alpr ----
if [ $BUILD_ALPR -eq 1 ]; then
    print_step "编译 alpr 车牌识别 (HyperLPR)"
    bash "${SCRIPT_DIR}/scripts/build-alpr.sh"
fi

# ---- 第四步：打包部署 ----
if [ $DO_DEPLOY -eq 1 ]; then
    print_step "打包部署文件"
    bash "${SCRIPT_DIR}/scripts/package-deploy.sh"
fi

# ---- 完成 ----
echo ""
echo -e "${BOLD}${GREEN}╔══════════════════════════════════════════════════╗${NC}"
echo -e "${BOLD}${GREEN}║${NC}                ${GREEN}构建完成！${NC}                        ${BOLD}${GREEN}║${NC}"
echo -e "${BOLD}${GREEN}╚══════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "  部署包: ${CYAN}${OUTPUT_DIR}/smartgate-deploy.tar.gz${NC}"
echo -e "  部署目录: ${CYAN}${OUTPUT_DIR}/deploy-final/${NC}"
echo ""
echo -e "  ${BOLD}板子上使用方法:${NC}"
echo -e "    1. 拷贝到 U 盘，插到开发板"
echo -e "    2. 板子上: cd /opt && tar xzf /mnt/usb/smartgate-deploy.tar.gz"
echo -e "    3. 板子上: cd /opt && ./Gec6818SmartGate"
echo ""
