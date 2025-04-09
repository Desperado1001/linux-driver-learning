#!/bin/bash
# QEMU环境准备脚本 - 用于创建ARM vexpress开发环境

# 配置变量
ARM_DEV_DIR="$HOME/arm_dev"
ROOTFS_DIR="$ARM_DEV_DIR/rootfs"
ROOTFS_SIZE=128  # MB
ROOTFS_IMG="$ROOTFS_DIR/rootfs.img"
ROOTFS_MNT="$ROOTFS_DIR/mnt"

# 颜色输出
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}准备QEMU ARM vexpress开发环境...${NC}"

# 创建目录结构
echo -e "${YELLOW}创建目录结构...${NC}"
mkdir -p $ARM_DEV_DIR
mkdir -p $ROOTFS_DIR
mkdir -p $ROOTFS_MNT

# 创建rootfs镜像
echo -e "${YELLOW}创建rootfs镜像 (${ROOTFS_SIZE}MB)...${NC}"
dd if=/dev/zero of=$ROOTFS_IMG bs=1M count=$ROOTFS_SIZE status=progress
mkfs.ext4 $ROOTFS_IMG

# 挂载rootfs
echo -e "${YELLOW}挂载rootfs镜像...${NC}"
sudo mount $ROOTFS_IMG $ROOTFS_MNT

# 使用debootstrap创建基本系统
echo -e "${YELLOW}使用debootstrap创建基本系统 (这可能需要一些时间)...${NC}"
sudo debootstrap --arch=armhf focal $ROOTFS_MNT

# 配置系统
echo -e "${YELLOW}配置系统...${NC}"

# 创建/etc/fstab
sudo bash -c "cat > $ROOTFS_MNT/etc/fstab << EOF
/dev/mmcblk0 / ext4 errors=remount-ro 0 1
proc /proc proc defaults 0 0
sysfs /sys sysfs defaults 0 0
devpts /dev/pts devpts defaults 0 0
EOF"

# 创建/etc/network/interfaces
sudo bash -c "cat > $ROOTFS_MNT/etc/network/interfaces << EOF
auto lo
iface lo inet loopback

auto eth0
iface eth0 inet dhcp
EOF"

# 创建/etc/hostname
sudo bash -c "echo 'arm-vexpress' > $ROOTFS_MNT/etc/hostname"

# 创建/etc/hosts
sudo bash -c "cat > $ROOTFS_MNT/etc/hosts << EOF
127.0.0.1   localhost
127.0.1.1   arm-vexpress

# The following lines are desirable for IPv6 capable hosts
::1     localhost ip6-localhost ip6-loopback
ff02::1 ip6-allnodes
ff02::2 ip6-allrouters
EOF"

# 创建用户密码（root）
echo -e "${YELLOW}设置root用户密码...${NC}"
sudo chroot $ROOTFS_MNT /bin/bash -c "echo 'root:root' | chpasswd"

# 启用串口登录
sudo bash -c "cat > $ROOTFS_MNT/etc/systemd/system/serial-getty@ttyAMA0.service << EOF
[Unit]
Description=Serial Getty on ttyAMA0
Documentation=man:agetty(8) man:systemd-getty-generator(8)
After=dev-ttyAMA0.device
BindsTo=dev-ttyAMA0.device

[Service]
ExecStart=/sbin/agetty -o '-p -- \\\\u' --keep-baud 115200,38400,9600 --autologin root ttyAMA0 linux
Type=idle
Restart=always
RestartSec=0
UtmpIdentifier=ttyAMA0

[Install]
WantedBy=multi-user.target
EOF"

# 在rootfs中创建驱动模块目录
sudo mkdir -p $ROOTFS_MNT/root/modules

# 卸载rootfs
echo -e "${YELLOW}卸载rootfs镜像...${NC}"
sudo umount $ROOTFS_MNT

echo -e "${GREEN}QEMU环境准备完成！${NC}"
echo -e "要启动QEMU，请运行 scripts/start_qemu.sh 脚本"
