#!/bin/bash
# ============================================================================
#  GEC6818 智能闸机系统 - 路径配置文件
#
#  这个包自带了所有依赖（Qt-Embedded、交叉编译器、OpenCV、HyperLPR源码），
#  路径默认已经配好，一般不需要修改。
#  如果你自己的机器上有不同位置的依赖，可以修改下面的变量。
# ============================================================================

# ---- 交叉编译工具链 ----
TOOLCHAIN_DIR="${TOOLCHAIN_DIR:-${SCRIPT_DIR}/deps/arm-toolchain}"

# ---- Qt-Embedded 5.7.0 ----
QTE_PREFIX="${QTE_PREFIX:-${SCRIPT_DIR}/deps/Qt-Embedded-5.7.0}"

# ---- OpenCV 3.4 ----
OPENCV_PREFIX="${OPENCV_PREFIX:-${SCRIPT_DIR}/deps/opencv-3.4-cross}"

# ---- x86 MOC ----
# 主机上的 moc 工具（生成 C++ 代码，用 ARM 编译器编译）
X86_MOC="${X86_MOC:-/usr/lib/x86_64-linux-gnu/qt5/bin/moc}"

# ---- HyperLPR 源码压缩包 ----
HYPERLPR_ZIP="${HYPERLPR_ZIP:-${SCRIPT_DIR}/deps/zeusees-HyperLPR-master源码包.zip}"

# ---- 项目源码目录 ----
PROJECT_SRC_DIR="${PROJECT_SRC_DIR:-${SCRIPT_DIR}/project-src}"

# ---- 编译输出目录 ----
BUILD_DIR="${BUILD_DIR:-${SCRIPT_DIR}/build-output}"

# ---- 部署输出目录 ----
OUTPUT_DIR="${OUTPUT_DIR:-${SCRIPT_DIR}/output}"
