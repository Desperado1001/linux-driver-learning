#!/bin/bash
# 驱动编译脚本

# 颜色输出
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# 默认路径
ARM_DEV_DIR="$HOME/arm_dev"
DEFAULT_KERNEL_DIR="$ARM_DEV_DIR/linux"
DEFAULT_DRIVER_DIR="examples/char_driver"

# 解析命令行参数
KERNEL_DIR=${1:-$DEFAULT_KERNEL_DIR}
DRIVER_DIR=${2:-$DEFAULT_DRIVER_DIR}

# 检查内核目录
if [ ! -d "$KERNEL_DIR" ]; then
    echo -e "${RED}错误: 内核目录 '$KERNEL_DIR' 不存在${NC}"
    echo -e "用法: $0 [内核目录] [驱动目录]"
    echo -e "默认: $0 $DEFAULT_KERNEL_DIR $DEFAULT_DRIVER_DIR"
    exit 1
fi

# 检查Makefile
if [ ! -f "$KERNEL_DIR/Makefile" ]; then
    echo -e "${RED}错误: 找不到内核Makefile, '$KERNEL_DIR'不是有效的内核源码目录${NC}"
    exit 1
fi

# 检查驱动目录
if [ ! -d "$DRIVER_DIR" ]; then
    echo -e "${RED}错误: 驱动目录 '$DRIVER_DIR' 不存在${NC}"
    exit 1
fi

# 检查驱动Makefile
if [ ! -f "$DRIVER_DIR/Makefile" ]; then
    echo -e "${RED}错误: 驱动目录中没有Makefile${NC}"
    exit 1
fi

# 导出编译环境变量
export ARCH=arm
export CROSS_COMPILE=arm-linux-gnueabi-

echo -e "${YELLOW}编译驱动: $DRIVER_DIR${NC}"
echo -e "${YELLOW}使用内核目录: $KERNEL_DIR${NC}"

# 保存当前目录
CURRENT_DIR=$(pwd)

# 进入驱动目录
cd "$DRIVER_DIR" || exit 1

# 编译驱动模块
make -C "$KERNEL_DIR" M="$(pwd)" modules

# 检查编译结果
if [ $? -eq 0 ]; then
    echo -e "${GREEN}驱动编译成功!${NC}"
    echo -e "模块位置: $(pwd)/*.ko"
else
    echo -e "${RED}驱动编译失败!${NC}"
    # 返回到原始目录
    cd "$CURRENT_DIR" || exit 1
    exit 1
fi

# 返回到原始目录
cd "$CURRENT_DIR" || exit 1