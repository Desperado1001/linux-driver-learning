# Linux驱动开发示例

本目录包含多种类型的Linux驱动示例，适合在WSL2 + QEMU环境中学习和测试。每个示例都包含详细的注释和说明，帮助您理解驱动开发的核心概念。

## 目录结构

```
examples/
├── char_driver/        # 字符设备驱动示例
│   ├── simple_char_driver.c
│   └── Makefile
├── platform_driver/    # 平台驱动示例
│   ├── simple_platform_driver.c
│   ├── simple_platform_device.c
│   └── Makefile
└── README.md           # 本文件
```

## 字符设备驱动

字符设备是Linux中最基本的设备类型之一，以字节流方式访问。字符设备示例包括：

### simple_char_driver

一个基本的字符设备驱动，实现了：
- 设备注册和初始化
- 基本的文件操作（open/read/write/close）
- 互斥锁保护并发访问
- ioctl接口示例
- 自动创建设备文件

#### 编译方法

```bash
cd examples/char_driver
make KERNEL_DIR=/path/to/kernel
```

#### 测试方法

在QEMU系统中：
```bash
# 加载模块
insmod simple_char_driver.ko

# 检查设备是否创建成功
ls -l /dev/simple_char_dev

# 写入测试数据
echo "Hello Linux Driver" > /dev/simple_char_dev

# 读取数据
cat /dev/simple_char_dev

# 查看内核日志
dmesg | grep simple_char

# 卸载模块
rmmod simple_char_driver
```

## 平台驱动（即将添加）

平台驱动是Linux设备模型的核心部分，实现了驱动和设备的分离。平台驱动示例包括：

### simple_platform_driver

一个基本的平台驱动，实现了：
- 驱动和设备分离模型
- 设备树支持
- 资源管理
- 热插拔支持

#### 编译方法

```bash
cd examples/platform_driver
make KERNEL_DIR=/path/to/kernel
```

## 学习建议

1. 从字符设备驱动开始学习，理解基本的驱动结构和文件操作
2. 学习互斥锁和并发控制机制
3. 理解模块参数和设备创建过程
4. 进阶到平台驱动模型，学习现代Linux内核的设备模型
5. 学习设备树的使用和解析

## 调试技巧

- 使用printk输出调试信息，日志级别从高到低：
  ```c
  printk(KERN_EMERG   "级别0: 系统崩溃\n");
  printk(KERN_ALERT   "级别1: 需要立即操作\n");
  printk(KERN_CRIT    "级别2: 严重情况\n");
  printk(KERN_ERR     "级别3: 错误情况\n");
  printk(KERN_WARNING "级别4: 警告情况\n");
  printk(KERN_NOTICE  "级别5: 正常但重要\n");
  printk(KERN_INFO    "级别6: 信息性消息\n");
  printk(KERN_DEBUG   "级别7: 调试信息\n");
  ```

- 使用`dmesg`命令查看内核日志
- 启用QEMU的GDB调试支持：`-s -S`参数
- 使用`container_of`宏访问包含结构体
