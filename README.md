# Linux驱动开发学习仓库

## 简介

本仓库提供了Linux内核驱动开发的学习资源和实践示例，特别关注在WSL2环境中使用QEMU进行ARM架构驱动的开发与测试。无论您是驱动开发初学者还是希望提升技能的开发者，本仓库都提供了系统化的学习路径和实用工具。

### 本仓库特点

- 完整的WSL2+QEMU开发环境搭建指南
- 循序渐进的驱动开发学习路径
- 多种类型的驱动示例（字符设备、平台驱动等）
- 实用开发脚本和调试技巧
- 详细的文档和分步教程

## 目录结构

```
linux-driver-learning/
├── README.md                   # 主文档
├── setup/                      # 环境配置脚本
│   ├── install_dependencies.sh # 安装依赖项
│   ├── prepare_qemu.sh         # 配置QEMU环境
│   └── setup_wsl.sh            # WSL2配置指南
├── examples/                   # 驱动示例
│   ├── char_driver/            # 字符设备驱动
│   ├── platform_driver/        # 平台驱动
│   └── README.md               # 示例说明
├── scripts/                    # 实用脚本
│   ├── build_driver.sh         # 编译驱动
│   ├── deploy_driver.sh        # 部署驱动
│   └── start_qemu.sh           # 启动QEMU
└── docs/                       # 详细文档
    ├── debugging.md            # 调试技巧
    ├── device_tree.md          # 设备树
    └── kernel_integration.md   # 内核集成
```

## 🗺️ 学习路线

### 第一阶段: 环境搭建与基础知识

1. **开发环境搭建**
   - WSL2配置与优化
   - 交叉编译工具链安装
   - QEMU安装与配置

2. **Linux内核基础**
   - 内核模块概念
   - 内核API基础
   - 驱动开发框架

3. **第一个驱动模块**
   - Hello World内核模块
   - 模块参数
   - 加载与卸载

### 第二阶段: 字符设备驱动开发

1. **字符设备驱动基础**
   - 字符设备注册
   - 文件操作接口
   - 用户空间通信

2. **高级字符设备功能**
   - ioctl接口实现
   - 同步与互斥
   - 阻塞与非阻塞IO

### 第三阶段: 平台驱动与设备树

1. **平台驱动模型**
   - 驱动与设备分离
   - probe与remove
   - 设备与驱动匹配

2. **设备树基础**
   - 设备树结构
   - 设备树节点编写
   - 设备树覆盖文件

### 第四阶段: 高级主题

1. **内存与DMA**
   - 内核内存管理
   - DMA操作
   - 缓冲区管理

2. **中断处理**
   - 中断注册
   - 顶半部与底半部
   - 工作队列与tasklet

3. **调试技术**
   - printk技巧
   - 内核调试选项
   - QEMU与GDB联合调试

## 📋 环境配置指南

### WSL2环境准备

```bash
# 检查WSL版本
wsl --status

# 安装必要的开发工具
sudo apt update
sudo apt install -y build-essential flex bison libssl-dev libelf-dev bc
sudo apt install -y qemu-system-arm gcc-arm-linux-gnueabi binutils-arm-linux-gnueabi 
sudo apt install -y debootstrap

# WSL2性能优化 (.wslconfig文件位于C:\Users\<用户名>\.wslconfig)
# [wsl2]
# memory=8GB
# processors=4
```

### 获取并编译Linux内核

```bash
# 克隆Linux内核
git clone --depth=1 https://github.com/torvalds/linux.git
cd linux

# 配置ARM vexpress
export ARCH=arm
export CROSS_COMPILE=arm-linux-gnueabi-
make vexpress_defconfig

# 可选：自定义配置
make menuconfig

# 编译内核
make -j$(nproc) zImage dtbs modules
```

### 准备QEMU根文件系统

```bash
# 创建rootfs
mkdir -p ~/arm_dev/rootfs
cd ~/arm_dev/rootfs
dd if=/dev/zero of=rootfs.img bs=1M count=128
mkfs.ext4 rootfs.img
mkdir -p mnt
sudo mount rootfs.img mnt
sudo debootstrap --arch=armhf focal mnt
sudo umount mnt
```

### 启动QEMU环境

```bash
qemu-system-arm \
  -M vexpress-a9 \
  -kernel path/to/your/zImage \
  -dtb path/to/your/vexpress-v2p-ca9.dtb \
  -drive file=rootfs/rootfs.img,format=raw \
  -append "root=/dev/mmcblk0 console=ttyAMA0 rw" \
  -nographic \
  -net nic -net user,hostfwd=tcp::2222-:22
```

## 🧪 驱动示例

### 简单字符设备驱动

见 [examples/char_driver/simple_char_driver.c](examples/char_driver/simple_char_driver.c)

主要功能:
- 字符设备注册与初始化
- 基本的读/写操作实现
- 设备文件自动创建

### 使用说明

1. 编译驱动模块:
```bash
cd examples/char_driver
make ARCH=arm CROSS_COMPILE=arm-linux-gnueabi-
```

2. 部署到QEMU:
```bash
# 挂载根文件系统
sudo mount ~/arm_dev/rootfs/rootfs.img ~/arm_dev/rootfs/mnt
# 复制驱动模块
sudo cp simple_char_driver.ko ~/arm_dev/rootfs/mnt/root/
sudo umount ~/arm_dev/rootfs/mnt
```

3. 在QEMU中测试:
```bash
# 在QEMU中
insmod /root/simple_char_driver.ko
ls -l /dev/simple_char_dev
echo "测试内容" > /dev/simple_char_dev
cat /dev/simple_char_dev
dmesg | grep simple_char
```

## 🔧 调试技巧

### printk日志级别

```c
// 不同级别的日志
printk(KERN_EMERG   "级别0: 系统崩溃\n");    // 最高级别
printk(KERN_ALERT   "级别1: 需要立即操作\n");
printk(KERN_CRIT    "级别2: 严重情况\n");
printk(KERN_ERR     "级别3: 错误情况\n");
printk(KERN_WARNING "级别4: 警告情况\n");
printk(KERN_NOTICE  "级别5: 正常但重要\n");
printk(KERN_INFO    "级别6: 信息性消息\n");
printk(KERN_DEBUG   "级别7: 调试信息\n");    // 最低级别
```

### QEMU + GDB调试

```bash
# 启动QEMU并开启GDB服务器
qemu-system-arm \
  -M vexpress-a9 \
  -kernel path/to/zImage \
  -dtb path/to/vexpress-v2p-ca9.dtb \
  -drive file=rootfs/rootfs.img,format=raw \
  -append "root=/dev/mmcblk0 console=ttyAMA0 rw" \
  -nographic \
  -s -S

# 在另一个终端中启动GDB
arm-linux-gnueabi-gdb path/to/vmlinux
(gdb) target remote localhost:1234
(gdb) b simple_char_init  # 设置断点
(gdb) c                   # 继续执行
```

## 📚 推荐资源

- [Linux内核开发 (Robert Love)](https://www.amazon.com/Linux-Kernel-Development-Robert-Love/dp/0672329468)
- [Linux设备驱动开发 (Jonathan Corbet)](https://lwn.net/Kernel/LDD3/)
- [Linux内核文档](https://www.kernel.org/doc/html/latest/)
- [ARM架构参考手册](https://developer.arm.com/documentation/)

## 🤝 贡献

欢迎通过Issue和Pull Request来贡献您的代码和想法！

## 📄 许可证

本项目采用GPL许可证，详见[LICENSE](LICENSE)文件。
