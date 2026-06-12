# GEC6818 无人车库管理系统

基于 Qt5 + OpenCV + RFID 的嵌入式 Linux 无人车库系统，运行在粤嵌 GEC6818 开发板上。

## 下载地址

**完整分发包（包含所有依赖，解压即可编译）：**

https://share.feijipan.com/s/ThcHFqjV

文件名：`smartgate-distribution-full.tar.gz`（约 310MB）

## 功能列表

| 功能 | 说明 |
|------|------|
| 图形解锁 | 3x3 网格图案解锁，密码：1→2→3→6→9 |
| 车辆入库 | 摄像头抓拍 → ALPR 车牌识别 → 确认入库 |
| 车辆出库 | 摄像头抓拍 → ALPR 车牌识别 → 计算停车费 → 确认出库 |
| RFID 自动出入库 | 刷卡自动识别车辆，根据数据库判断入库/出库 |
| 车位计数 | 实时显示当前库内车辆数 |
| 进出记录 | 查看最近 20 条进出记录 |
| 超时锁屏 | 1 分钟无操作自动锁屏 |
| 开机动画 | 启动时播放视频动画 |

## 快速开始

### 1. 下载分发包

从上方链接下载 `smartgate-distribution-full.tar.gz`

### 2. 解压

```bash
tar xzf smartgate-distribution-full.tar.gz
cd smartgate-distribution
```

### 3. 一键编译

```bash
./build-all.sh
```

编译过程约 2-3 分钟，自动完成：
- 环境检查
- 编译 Qt 主程序
- 编译 ALPR 车牌识别
- 打包部署文件

### 4. 部署到开发板

编译产物在 `output/smartgate-deploy.tar.gz`（22MB），拷贝到开发板：

```bash
# 在开发板上
mkdir -p /opt/smartgate
tar xzf smartgate-deploy.tar.gz -C /opt/smartgate
cd /opt/smartgate
chmod +x Gec6818SmartGate alpr/alpr
./Gec6818SmartGate
```

**不需要 install.sh、不需要 export LD_LIBRARY_PATH、不需要 apt install。**

## 分发包内容

| 内容 | 大小 | 说明 |
|------|------|------|
| deps/arm-toolchain/ | 310MB | ARM 交叉编译器 (GCC 5.4.0) |
| deps/Qt-Embedded-5.7.0/ | 232MB | Qt-Embedded 精简版 |
| deps/opencv-3.4-cross/ | 50MB | OpenCV 交叉编译包 |
| deps/HyperLPR.zip | 103MB | 车牌识别引擎源码 |
| project-src/ | 89KB | 项目源码 + CMake 配置 |
| scripts/ | 15KB | 编译脚本 |
| build-all.sh | 4KB | 一键编译入口 |

## 编译环境要求

### 虚拟机要求

- Ubuntu 16.04/18.04（推荐）
- 已安装 VMware Tools 或 Open VM Tools

### 主机依赖

```bash
sudo apt install qt5-qmake cmake make unzip
```

## 项目结构

```
smartgate-distribution/
├── build-all.sh            一键入口（检查→编译Qt→编译alpr→打包）
├── config.sh               路径配置（自动指向包内 deps/，一般不用改）
├── README.md               本文件
├── scripts/                四个步骤脚本
│   ├── check-env.sh        环境检查
│   ├── build-qt.sh         编译 Qt 主程序 (Gec6818SmartGate)
│   ├── build-alpr.sh       编译 HyperLPR 车牌识别
│   └── package-deploy.sh   打包部署文件
├── project-src/            项目源码
│   ├── CMakeLists.txt
│   ├── toolchain-gec6818.cmake
│   ├── include/            头文件
│   │   ├── bridge.h
│   │   ├── lockscreen.h
│   │   ├── mainwindow.h
│   │   ├── patternlock.h
│   │   ├── rfidreader.h
│   │   └── touchscreen.h
│   └── src/                源代码
│       ├── main.cpp
│       ├── mainwindow.cpp
│       ├── lockscreen.cpp
│       ├── patternlock.cpp
│       ├── rfidreader.cpp
│       ├── touchscreen.cpp
│       └── alpr_main.cpp
├── deps/                   内置依赖（自动使用）
│   ├── arm-toolchain/      交叉编译器 ~310MB
│   ├── Qt-Embedded-5.7.0/  Qt-Embedded 精简版 ~232MB
│   ├── opencv-3.4-cross/   OpenCV 交叉编译包 ~50MB
│   └── zeusees-HyperLPR-master源码包.zip  ~103MB
└── output/                 编译结果
    ├── smartgate-deploy.tar.gz   22MB 部署压缩包
    └── deploy-final/             部署目录
        ├── Gec6818SmartGate  257K ARM ELF (主程序)
        ├── alpr/alpr         293K ARM ELF (车牌识别)
        ├── alpr/model/       9个 ML 模型 (~10MB)
        └── lib/            16个 OpenCV 库 (~16MB)
```

## 按需编译

```bash
./build-all.sh qt        # 只编译 Qt 主程序
./build-all.sh alpr      # 只编译 alpr 车牌识别
./build-all.sh deploy    # 只打包（不编译）
./build-all.sh clean     # 清理构建产物
```

## 运行说明

### 程序流程

1. **开机动画**（如果存在 `start.MP4`）
   - 播放开机动画视频
   - 自动清屏进入锁屏界面

2. **锁屏界面**
   - 绘制图案 1→2→3→6→9 解锁
   - 点击"显示/隐藏密码"查看提示

3. **主界面**
   - 左侧：摄像头实时预览
   - 右侧：操作按钮 + 状态显示

### 操作说明

| 操作 | 说明 |
|------|------|
| 车辆入库 | 点击按钮 → 抓拍 → 识别车牌 → 确认 → 写入数据库 |
| 车辆出库 | 点击按钮 → 抓拍 → 识别车牌 → 计算费用 → 确认 → 写入数据库 |
| RFID 刷卡 | 自动抓拍 → 识别 → 判断入库/出库 → 确认 |
| 查看记录 | 显示最近 20 条进出记录 |
| 锁屏 | 返回锁屏界面 |

### 数据存储

- **数据库路径**：`/frog/gate.db`
- **格式**：CSV 文本文件
- **内容**：车牌标识,操作类型(inbound/outbound),时间戳

## RFID 配置

### 硬件连接

- **模块**：HW-033 RFID 读卡器
- **串口**：`/dev/ttySAC1`（GEC6818 UART1）
- **波特率**：9600

### 卡号映射

在 `project-src/src/mainwindow.cpp` 构造函数中配置：

```cpp
// 初始化卡号-车牌映射（硬编码）
cardPlateMap_["83533443"] = "贵B91VIP";
// 添加更多卡号映射：
// cardPlateMap_["XXXXXXXX"] = "车牌号";
```

### 获取卡号

在开发板上刷卡测试，查看程序输出：

```
读到卡号: 83533443 (0x83533443)
```

## 故障排查

| 问题 | 解决方法 |
|------|----------|
| 摄像头黑屏 | `ls /dev/video*` 确认设备节点，代码默认 `/dev/video7` |
| 库找不到 | 确保 `cd` 到部署目录再运行，不要用绝对路径调用 |
| ALPR 启动失败 | 检查 `alpr/alpr` 存在且有执行权限 |
| ALPR 模型找不到 | 检查 `alpr/model/` 目录下有 9 个模型文件 |
| 识别结果为空 | 检查抓拍照片是否有清晰车牌 |
| RFID 无反应 | 检查串口连接，确认 `/dev/ttySAC1` 存在 |
| RFID 读取失败 | 检查串口权限：`chmod 666 /dev/ttySAC1` |
| 界面显示偏移 | 检查 LCD 分辨率是否为 800x480 |
| 超时不锁屏 | 检查是否有持续的触摸事件干扰 |
| 编译报 moc 错误 | 确认 `/usr/lib/x86_64-linux-gnu/qt5/bin/moc` 存在 |
| 编译报 Qt 头文件错误 | 确认 Qt-Embedded 路径正确 |

## 技术栈

| 组件 | 技术 |
|------|------|
| UI 框架 | Qt 5.7 Embedded |
| 图像处理 | OpenCV 3.4 |
| 车牌识别 | HyperLPR |
| RFID 通信 | 串口 UART (9600 8N1) |
| 构建系统 | CMake 3.10+ |
| 目标平台 | ARM Cortex-A53 (GEC6818) |

## 硬件清单

| 硬件 | 型号/说明 | 连接方式 |
|------|----------|---------|
| 开发板 | GEC6818（ARM Cortex-A53） | - |
| 摄像头 | USB 摄像头 | USB 接口 |
| LCD 屏 | 800x480 液晶屏 | 开发板自带 |
| 触摸屏 | 电容触摸屏 | 开发板自带 |
| RFID 模块 | HW-033 | UART1（/dev/ttySAC1） |
| RFID 卡 | NFC 门禁卡 | 无线 |

## 拓展功能

- [x] RFID 自动出入库
- [x] 超时自动锁屏（1分钟）
- [x] 开机动画
- [x] 车位计数显示
- [x] 进出记录查看
- [ ] GPIO 控制（蜂鸣器/LED）
- [ ] 远程监控
- [ ] 数据统计图表

## 技术报告

详细技术报告请参见项目源码中的 `技术报告.md` 文件。

## 许可证

本项目仅供学习交流使用。

## 致谢

- 粤嵌 GEC6818 开发板
- Qt 5.7 Embedded
- OpenCV 3.4
- HyperLPR 车牌识别引擎

---

*版本 2.0 | 目标: GEC6818 (ARM Cortex-A53, 800x480)*
*Qt-Embedded 5.7.0 | OpenCV 3.4 | HyperLPR | ARM GCC 5.4.0 | 分发包 ~310MB*
