#!/bin/bash
# Linux驱动开发依赖项安装脚本 - 针对WSL2环境

echo "安装Linux驱动开发所需依赖项..."

# 更新软件包列表
sudo apt update

# 安装基本开发工具
sudo apt install -y build-essential git vim nano
sudo apt install -y flex bison libssl-dev libelf-dev bc
sudo apt install -y libncurses-dev libncurses5-dev libncursesw5-dev

# 安装ARM交叉编译工具
sudo apt install -y gcc-arm-linux-gnueabi binutils-arm-linux-gnueabi 
sudo apt install -y gcc-arm-linux-gnueabihf binutils-arm-linux-gnueabihf

# 安装QEMU相关工具
sudo apt install -y qemu-system-arm qemu-utils

# 安装Debootstrap（创建rootfs用）
sudo apt install -y debootstrap

# 安装GDB调试工具
sudo apt install -y gdb-multiarch

# 安装文档工具
sudo apt install -y doxygen graphviz

echo "设置环境变量..."
echo 'export ARCH=arm' >> ~/.bashrc
echo 'export CROSS_COMPILE=arm-linux-gnueabi-' >> ~/.bashrc

echo "所有依赖项安装完成！"
echo "请运行 'source ~/.bashrc' 使环境变量生效"
