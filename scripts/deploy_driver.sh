#!/bin/bash
# 驱动部署脚本 - 将编译好的驱动模块复制到QEMU根文件系统

# 颜色输出
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# 默认路径
ARM_DEV_DIR="$HOME/arm_dev"
ROOTFS_IMG="$ARM_DEV_DIR/rootfs/rootfs.img"
ROOTFS_MNT="$ARM_DEV_DIR/rootfs/mnt"
DEFAULT_DRIVER_DIR="examples/char_driver"
DEFAULT_MODULE_NAME="simple_char_driver.ko"

# 解析命令行参数
DRIVER_DIR=${1:-$DEFAULT_DRIVER_DIR}
MODULE_NAME=${2:-$DEFAULT_MODULE_NAME}

# 显示参数
echo -e "${YELLOW}部署驱动: $DRIVER_DIR/$MODULE_NAME${NC}"
echo -e "${YELLOW}目标位置: rootfs:/root/modules/${NC}"

# 检查驱动文件是否存在
if [ ! -f "$DRIVER_DIR/$MODULE_NAME" ]; then
    echo -e "${RED}错误: 找不到模块 '$DRIVER_DIR/$MODULE_NAME'${NC}"
    echo -e "请先编译驱动模块"
    echo -e "用法: $0 [驱动目录] [模块名称]"
    echo -e "默认: $0 $DEFAULT_DRIVER_DIR $DEFAULT_MODULE_NAME"
    exit 1
fi

# 检查rootfs镜像是否存在
if [ ! -f "$ROOTFS_IMG" ]; then
    echo -e "${RED}错误: 找不到rootfs镜像 '$ROOTFS_IMG'${NC}"
    echo -e "请先运行 setup/prepare_qemu.sh 脚本创建rootfs"
    exit 1
fi

# 创建挂载点（如果不存在）
if [ ! -d "$ROOTFS_MNT" ]; then
    echo -e "${YELLOW}创建挂载点 $ROOTFS_MNT${NC}"
    mkdir -p "$ROOTFS_MNT"
fi

# 检查挂载点是否已挂载
if mountpoint -q "$ROOTFS_MNT"; then
    echo -e "${RED}错误: $ROOTFS_MNT 已挂载${NC}"
    echo -e "请先卸载: sudo umount $ROOTFS_MNT"
    exit 1
fi

# 挂载rootfs
echo -e "${YELLOW}挂载rootfs镜像...${NC}"
sudo mount "$ROOTFS_IMG" "$ROOTFS_MNT"

if [ $? -ne 0 ]; then
    echo -e "${RED}错误: 无法挂载rootfs镜像${NC}"
    exit 1
fi

# 创建模块目录
echo -e "${YELLOW}创建模块目录...${NC}"
sudo mkdir -p "$ROOTFS_MNT/root/modules"

# 复制模块
echo -e "${YELLOW}复制模块...${NC}"
sudo cp "$DRIVER_DIR/$MODULE_NAME" "$ROOTFS_MNT/root/modules/"

if [ $? -ne 0 ]; then
    echo -e "${RED}错误: 无法复制模块${NC}"
    sudo umount "$ROOTFS_MNT"
    exit 1
fi

# 检查模块是否复制成功
if sudo test -f "$ROOTFS_MNT/root/modules/$MODULE_NAME"; then
    echo -e "${GREEN}模块已成功部署到rootfs${NC}"
else
    echo -e "${RED}错误: 模块未能部署到rootfs${NC}"
    sudo umount "$ROOTFS_MNT"
    exit 1
fi

# 卸载rootfs
echo -e "${YELLOW}卸载rootfs镜像...${NC}"
sudo umount "$ROOTFS_MNT"

if [ $? -ne 0 ]; then
    echo -e "${RED}警告: 无法卸载rootfs镜像, 请手动卸载${NC}"
    exit 1
fi

echo -e "${GREEN}驱动部署完成!${NC}"
echo -e "在QEMU中加载驱动: insmod /root/modules/$MODULE_NAME"