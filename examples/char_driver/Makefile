# 字符设备驱动Makefile
#
# 这个Makefile用于编译simple_char_driver.c模块
# 可以在WSL2环境中使用
#
# 使用方法:
# 1. 如果已设置KERNEL_DIR，可以直接运行make
# 2. 否则，需指定内核源码目录: make KERNEL_DIR=/path/to/kernel
#
# 默认使用ARM交叉编译

# 编译模块目标
obj-m += simple_char_driver.o

# 默认内核源码路径
KERNEL_DIR ?= $(HOME)/arm_dev/linux

# 检查目标架构是否已设置，否则默认为ARM
ifeq ($(ARCH),)
  # 未指定架构，默认为ARM
  ARCH := arm
  CROSS_COMPILE := arm-linux-gnueabi-
endif

# 定义全部目标
all: module

# 编译模块
module:
	@echo "编译字符设备驱动模块..."
	@echo "使用内核源码: $(KERNEL_DIR)"
	@echo "架构: $(ARCH), 交叉编译器: $(CROSS_COMPILE)"
	$(MAKE) -C $(KERNEL_DIR) M=$(PWD) modules

# 清理编译结果
clean:
	$(MAKE) -C $(KERNEL_DIR) M=$(PWD) clean

# 安装模块（可选）
install:
	$(MAKE) -C $(KERNEL_DIR) M=$(PWD) modules_install

# 帮助信息
help:
	@echo "可用目标:"
	@echo "  all     - 编译驱动模块 (默认)"
	@echo "  clean   - 清理编译结果"
	@echo "  install - 安装模块"
	@echo "  help    - 显示此帮助信息"
	@echo ""
	@echo "环境变量:"
	@echo "  KERNEL_DIR     - 内核源码目录 (默认: $(HOME)/arm_dev/linux)"
	@echo "  ARCH           - 目标架构 (默认: arm)"
	@echo "  CROSS_COMPILE  - 交叉编译器前缀 (默认: arm-linux-gnueabi-)"

.PHONY: all module clean install help
