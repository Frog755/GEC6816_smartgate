cmake_minimum_required(VERSION 3.10)
project(Gec6818SmartGate VERSION 1.0.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# ============================================================================
# 路径参数（由 build-all.sh 传入）
# ============================================================================
#   CROSS_COMPILE=ON                    - 是否交叉编译
#   TOOLCHAIN_DIR  - 交叉编译器根目录
#   QTE_PREFIX     - Qt-Embedded 安装目录 (lib 所在)
#   OPENCV_PREFIX  - OpenCV 交叉编译目录
#   X86_MOC        - x86 moc 工具路径
# ============================================================================

# 检测交叉编译模式
if(CROSS_COMPILE)
    message(STATUS "交叉编译模式已启用")
elseif(CMAKE_CXX_COMPILER MATCHES "arm-linux" OR CMAKE_CXX_COMPILER MATCHES "aarch64")
    message(STATUS "检测到交叉编译器，启用交叉编译模式")
    set(CROSS_COMPILE ON)
else()
    message(STATUS "本地编译模式 (x86 PC 调试用)")
    set(CROSS_COMPILE OFF)
endif()

if(CROSS_COMPILE)
    # ---- 参数校验 ----
    foreach(var TOOLCHAIN_DIR QTE_PREFIX OPENCV_PREFIX X86_MOC)
        if(NOT ${var})
            message(FATAL_ERROR "交叉编译需要指定 -D${var}=<path>")
        endif()
    endforeach()

    message(STATUS "工具链: ${TOOLCHAIN_DIR}")
    message(STATUS "Qt-Embedded: ${QTE_PREFIX}")
    message(STATUS "OpenCV: ${OPENCV_PREFIX}")
    message(STATUS "MOC: ${X86_MOC}")

    # 设置交叉编译器 (必须显式设置，cmake 不会自动从 toolchain 文件推断)
    set(CMAKE_C_COMPILER   "${TOOLCHAIN_DIR}/usr/bin/arm-linux-gcc")
    set(CMAKE_CXX_COMPILER "${TOOLCHAIN_DIR}/usr/bin/arm-linux-g++")

    # 设置 sysroot
    set(CMAKE_SYSROOT "${TOOLCHAIN_DIR}/usr/arm-none-linux-gnueabi/sysroot")
    set(CMAKE_FIND_ROOT_PATH "${TOOLCHAIN_DIR}/usr/arm-none-linux-gnueabi/sysroot")
    set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
    set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
    set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
    set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY)

    # ---- Qt 头文件 ----
    # 交叉编译时，用系统 x86 Qt5 头文件（API 签名一致，不依赖架构）
    # 因为 Qt-Embedded 5.7.0 的 include 目录不可用
    find_package(Qt5 QUIET COMPONENTS Core Gui Widgets)
    if(Qt5_FOUND)
        # 系统有 Qt5-dev，用它的头文件
        include_directories(
            ${Qt5Core_INCLUDE_DIRS}
            ${Qt5Gui_INCLUDE_DIRS}
            ${Qt5Widgets_INCLUDE_DIRS}
        )
        message(STATUS "使用系统 Qt5 头文件")
    else()
        # fallback: 手动指定常见路径
        include_directories(
            /usr/include/x86_64-linux-gnu/qt5
            /usr/include/x86_64-linux-gnu/qt5/QtWidgets
            /usr/include/x86_64-linux-gnu/qt5/QtGui
            /usr/include/x86_64-linux-gnu/qt5/QtCore
        )
        message(STATUS "手动指定 Qt5 头文件路径")
    endif()

    # ---- 设置 moc ----
    set(QT5_MOC_EXECUTABLE "${X86_MOC}")

    # ---- OpenCV 路径 ----
    set(OPENCV_INCLUDE "${OPENCV_PREFIX}/tools/opencv/include")
    set(OPENCV_LIB "${OPENCV_PREFIX}/lib")

# else: 本地模式
else()
    message(STATUS "使用系统 Qt5 (PC调试模式)")
    find_package(Qt5 REQUIRED COMPONENTS Widgets Core Gui)
    set(QT5_MOC_EXECUTABLE "${X86_MOC}")
endif()

if(NOT QT5_MOC_EXECUTABLE)
    message(FATAL_ERROR "moc not found. 设置 -DX86_MOC=<path>")
endif()
message(STATUS "MOC: ${QT5_MOC_EXECUTABLE}")

# 包含项目头文件目录
include_directories(${CMAKE_SOURCE_DIR}/include)

# 收集源文件
set(SOURCES
    src/main.cpp
    src/touchscreen.cpp
    src/patternlock.cpp
    src/lockscreen.cpp
    src/mainwindow.cpp
    src/rfidreader.cpp
)

# 生成 moc 文件
set(MOC_HDRS
    ${CMAKE_SOURCE_DIR}/include/patternlock.h
    ${CMAKE_SOURCE_DIR}/include/lockscreen.h
    ${CMAKE_SOURCE_DIR}/include/mainwindow.h
    ${CMAKE_SOURCE_DIR}/include/bridge.h
    ${CMAKE_SOURCE_DIR}/include/rfidreader.h
)

set(MOC_FILES)
foreach(MOC_HDR ${MOC_HDRS})
    get_filename_component(MOC_NAME ${MOC_HDR} NAME_WE)
    set(MOC_OUT ${CMAKE_CURRENT_BINARY_DIR}/moc_${MOC_NAME}.cpp)
    add_custom_command(
        OUTPUT ${MOC_OUT}
        COMMAND ${CMAKE_COMMAND} -E make_directory ${CMAKE_CURRENT_BINARY_DIR}
        COMMAND ${QT5_MOC_EXECUTABLE} ${MOC_HDR} -o ${MOC_OUT}
        DEPENDS ${MOC_HDR}
        COMMENT "MOC ${MOC_NAME}.h"
    )
    list(APPEND MOC_FILES ${MOC_OUT})
endforeach()

list(APPEND SOURCES ${MOC_FILES})

# 生成可执行文件
add_executable(Gec6818SmartGate ${SOURCES})

if(CROSS_COMPILE)
    # 交叉编译：直接链接 ARM Qt 库
    target_compile_options(Gec6818SmartGate PRIVATE -fPIC)
    target_link_libraries(Gec6818SmartGate
        ${QTE_PREFIX}/lib/libQt5Core.so
        ${QTE_PREFIX}/lib/libQt5Gui.so
        ${QTE_PREFIX}/lib/libQt5Widgets.so
    )

    # 链接 OpenCV
    target_include_directories(Gec6818SmartGate PRIVATE
        ${OPENCV_INCLUDE}
        ${OPENCV_INCLUDE}/opencv
    )
    target_link_libraries(Gec6818SmartGate
        ${OPENCV_LIB}/libopencv_core.so.3.4
        ${OPENCV_LIB}/libopencv_imgproc.so.3.4
        ${OPENCV_LIB}/libopencv_imgcodecs.so.3.4
        ${OPENCV_LIB}/libopencv_videoio.so.3.4
    )

    # 设置 rpath:
    #   $ORIGIN          -> 可执行文件所在目录 (部署目录)
    #   $ORIGIN/lib      -> 部署目录下的 lib/ (OpenCV 运行时库)
    #   QTE_PREFIX/lib   -> Qt-Embedded 在板子上的路径
    set(_RPATH_FLAGS "-Wl,-rpath,\$ORIGIN -Wl,-rpath,\$ORIGIN/lib -Wl,-rpath,${QTE_PREFIX}/lib")
    set_target_properties(Gec6818SmartGate PROPERTIES
        LINK_FLAGS "${_RPATH_FLAGS}"
    )
else()
    # 本地模式
    target_link_libraries(Gec6818SmartGate
        Qt5::Core
        Qt5::Gui
        Qt5::Widgets
    )
endif()

# 编译选项
target_compile_options(Gec6818SmartGate PRIVATE -Wall -Wextra)
