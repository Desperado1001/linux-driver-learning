#!/bin/bash
# QEMU启动脚本 - 启动ARM vexpress开发环境

# 颜色输出
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# 默认路径
ARM_DEV_DIR="$HOME/arm_dev"
DEFAULT_KERNEL_DIR="$ARM_DEV_DIR/linux"
DEFAULT_KERNEL_IMAGE="$DEFAULT_KERNEL_DIR/arch/arm/boot/zImage"
DEFAULT_DTB="$DEFAULT_KERNEL_DIR/arch/arm/boot/dts/vexpress-v2p-ca9.dtb"
ROOTFS_IMG="$ARM_DEV_DIR/rootfs/rootfs.img"

# 解析命令行参数
KERNEL_IMAGE=${1:-$DEFAULT_KERNEL_IMAGE}
DTB=${2:-$DEFAULT_DTB}
DEBUG_MODE=${3:-"no"}

# 显示参数
echo -e "${YELLOW}启动QEMU ARM vexpress环境${NC}"
echo -e "${YELLOW}使用内核镜像: $KERNEL_IMAGE${NC}"
echo -e "${YELLOW}使用设备树: $DTB${NC}"
echo -e "${YELLOW}根文件系统: $ROOTFS_IMG${NC}"

# 检查文件是否存在
if [ ! -f "$KERNEL_IMAGE" ]; then
    echo -e "${RED}错误: 内核镜像文件不存在 '$KERNEL_IMAGE'${NC}"
    echo -e "请编译内核或指定正确的镜像路径"
    echo -e "用法: $0 [内核镜像] [设备树文件] [debug模式(yes/no)]"
    echo -e "默认: $0 $DEFAULT_KERNEL_IMAGE $DEFAULT_DTB no"
    exit 1
fi

if [ ! -f "$DTB" ]; then
    echo -e "${RED}错误: 设备树文件不存在 '$DTB'${NC}"
    echo -e "请编译内核DTB或指定正确的DTB路径"
    exit 1
fi

if [ ! -f "$ROOTFS_IMG" ]; then
    echo -e "${RED}错误: 根文件系统不存在 '$ROOTFS_IMG'${NC}"
    echo -e "请运行 setup/prepare_qemu.sh 脚本创建rootfs"
    exit 1
fi

# 构建QEMU命令
QEMU_CMD="qemu-system-arm"
QEMU_CMD+=" -M vexpress-a9"
QEMU_CMD+=" -kernel $KERNEL_IMAGE"
QEMU_CMD+=" -dtb $DTB"
QEMU_CMD+=" -drive file=$ROOTFS_IMG,format=raw"
QEMU_CMD+=" -append \"root=/dev/mmcblk0 console=ttyAMA0 rw\""
QEMU_CMD+=" -nographic"
QEMU_CMD+=" -net nic -net user,hostfwd=tcp::2222-:22"

# 是否启用调试模式
if [ "$DEBUG_MODE" = "yes" ]; then
    echo -e "${YELLOW}启用GDB调试模式${NC}"
    echo -e "在另一个终端中运行: arm-linux-gnueabi-gdb $DEFAULT_KERNEL_DIR/vmlinux"
    echo -e "然后在GDB中执行: target remote localhost:1234"
    QEMU_CMD+=" -s -S"
fi

# 输出QEMU命令
echo -e "${GREEN}执行命令:${NC}"
echo -e "$QEMU_CMD"

# 执行QEMU命令
eval "$QEMU_CMD"
