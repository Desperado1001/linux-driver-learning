# Linux驱动调试技巧

本文档介绍在WSL2和QEMU环境中调试Linux驱动的各种方法和技巧。

## 基础调试方法

### printk日志

printk是内核开发中最常用的调试手段，类似于用户空间的printf。

#### 日志级别

```c
/* 日志级别从高到低 */
printk(KERN_EMERG   "级别0: 系统崩溃\n");     /* 最高级别 */
printk(KERN_ALERT   "级别1: 需要立即操作\n");
printk(KERN_CRIT    "级别2: 严重情况\n");
printk(KERN_ERR     "级别3: 错误情况\n");
printk(KERN_WARNING "级别4: 警告情况\n");
printk(KERN_NOTICE  "级别5: 正常但重要\n");
printk(KERN_INFO    "级别6: 信息性消息\n");
printk(KERN_DEBUG   "级别7: 调试信息\n");     /* 最低级别 */
```

#### 查看内核日志

在目标系统中：
```bash
# 查看全部日志
dmesg

# 持续查看日志（类似tail -f）
dmesg -w

# 清除日志缓冲区
dmesg -c

# 使用grep过滤日志
dmesg | grep simple_char
```

#### 控制日志级别

设置控制台日志级别：
```bash
echo 7 > /proc/sys/kernel/printk
```

#### 使用pr_*宏函数

更好的做法是使用pr_*系列宏函数：
```c
pr_emerg("系统崩溃: %s\n", error_msg);
pr_alert("需要立即操作: %s\n", error_msg);
pr_crit("严重情况: %s\n", error_msg);
pr_err("错误情况: %s\n", error_msg);
pr_warning("警告情况: %s\n", error_msg);
pr_notice("正常但重要: %s\n", error_msg);
pr_info("信息性消息: %s\n", error_msg);
pr_debug("调试信息: %s\n", error_msg);
```

#### 驱动专用日志宏

使用dev_*系列宏在日志中包含设备信息：
```c
dev_emerg(dev, "设备错误消息\n");
dev_alert(dev, "设备警告消息\n");
dev_crit(dev, "设备严重消息\n");
dev_err(dev, "设备错误消息\n");
dev_warn(dev, "设备警告消息\n");
dev_notice(dev, "设备通知消息\n");
dev_info(dev, "设备信息消息\n");
dev_dbg(dev, "设备调试消息\n");
```

## QEMU调试

QEMU提供了强大的调试功能，可以与GDB结合使用。

### 启用QEMU GDB调试

启动QEMU时添加`-s -S`参数：
```bash
qemu-system-arm \
  -M vexpress-a9 \
  -kernel path/to/zImage \
  -dtb path/to/vexpress-v2p-ca9.dtb \
  -drive file=rootfs/rootfs.img,format=raw \
  -append "root=/dev/mmcblk0 console=ttyAMA0 rw" \
  -nographic \
  -s -S
```

参数说明：
- `-s`: 在TCP端口1234上启动GDB服务器（相当于`-gdb tcp::1234`）
- `-S`: 启动时暂停CPU执行，等待GDB连接

### 使用GDB连接QEMU

在另一个终端窗口中：
```bash
arm-linux-gnueabi-gdb path/to/vmlinux
(gdb) target remote localhost:1234
(gdb) b simple_char_init  # 在函数入口处设置断点
(gdb) c                   # 继续执行，直到遇到断点
```

### 常用GDB命令

```bash
# 设置断点
(gdb) b function_name     # 在函数处设置断点
(gdb) b filename:line     # 在源文件指定行设置断点
(gdb) b *0x80001234       # 在内存地址处设置断点

# 控制执行
(gdb) c                   # 继续执行
(gdb) s                   # 单步执行，进入函数
(gdb) n                   # 单步执行，不进入函数
(gdb) finish              # 执行直到当前函数返回

# 检查程序状态
(gdb) p variable          # 打印变量值
(gdb) p/x variable        # 以十六进制打印变量
(gdb) info registers      # 查看寄存器值
(gdb) bt                  # 查看调用栈
(gdb) info locals         # 查看局部变量
```

## 动态调试技术

### 动态打印(Dynamic Debug)

内核提供了动态调试功能，可以在运行时启用或禁用调试信息。

在内核配置中启用：
```
Kernel hacking -> Dynamic Debug
```

在代码中使用动态调试：
```c
#define DEBUG
#include <linux/dynamic_debug.h>

/* 使用pr_debug或dev_dbg都将启用动态调试 */
pr_debug("这是一条动态调试消息\n");
dev_dbg(dev, "这是一条设备动态调试消息\n");
```

在系统运行时控制：
```bash
# 启用特定文件的所有调试信息
echo 'file simple_char_driver.c +p' > /sys/kernel/debug/dynamic_debug/control

# 启用特定函数的调试信息
echo 'func dev_open +p' > /sys/kernel/debug/dynamic_debug/control

# 禁用特定文件的调试信息
echo 'file simple_char_driver.c -p' > /sys/kernel/debug/dynamic_debug/control
```

### ftrace跟踪

ftrace是内核内置的跟踪工具，可以跟踪函数调用。

在内核配置中启用：
```
Kernel hacking -> Tracers -> Function Tracer
```

使用ftrace：
```bash
# 挂载debugfs（如果尚未挂载）
mount -t debugfs none /sys/kernel/debug

# 列出可用的跟踪器
cat /sys/kernel/debug/tracing/available_tracers

# 启用函数跟踪
echo "function" > /sys/kernel/debug/tracing/current_tracer

# 启用特定函数的跟踪
echo "simple_char_*" > /sys/kernel/debug/tracing/set_ftrace_filter

# 启动跟踪
echo 1 > /sys/kernel/debug/tracing/tracing_on

# 查看跟踪结果
cat /sys/kernel/debug/tracing/trace
```

## 内存调试

### 内存泄漏检测(KMEMLEAK)

内核提供了内存泄漏检测工具KMEMLEAK。

在内核配置中启用：
```
Kernel hacking -> Memory Debugging -> Kernel memory leak detector
```

使用KMEMLEAK：
```bash
# 扫描内存泄漏
echo scan > /sys/kernel/debug/kmemleak

# 查看内存泄漏报告
cat /sys/kernel/debug/kmemleak
```

### 内存边界检查(KASAN)

KASAN (Kernel Address Sanitizer) 用于检测内存边界访问错误。

在内核配置中启用：
```
Kernel hacking -> Memory Debugging -> Kernel Address Sanitizer
```

KASAN会自动在运行时检测内存边界错误并报告。

## WSL2特有的调试考虑

在WSL2环境中调试时，有一些特殊考虑：

1. **端口转发**：如果在QEMU中使用GDB服务器，确保端口在WSL2和Windows之间正确转发

2. **文件系统性能**：避免在Windows挂载的目录中编译和调试，优先使用WSL2原生文件系统路径

3. **图形界面**：如果需要使用图形调试工具，需要配置X服务器

## 调试脚本

以下是一个实用的调试脚本，可以在WSL2中快速启动QEMU调试环境：

```bash
#!/bin/bash
# debug_qemu.sh - 启动QEMU调试环境

KERNEL_IMAGE="$HOME/arm_dev/linux/arch/arm/boot/zImage"
DTB="$HOME/arm_dev/linux/arch/arm/boot/dts/vexpress-v2p-ca9.dtb"
ROOTFS_IMG="$HOME/arm_dev/rootfs/rootfs.img"
VMLINUX="$HOME/arm_dev/linux/vmlinux"

# 启动QEMU
qemu-system-arm \
  -M vexpress-a9 \
  -kernel "$KERNEL_IMAGE" \
  -dtb "$DTB" \
  -drive file="$ROOTFS_IMG",format=raw \
  -append "root=/dev/mmcblk0 console=ttyAMA0 rw" \
  -nographic \
  -s -S &

QEMU_PID=$!
echo "QEMU已启动，PID: $QEMU_PID"
echo "启动GDB连接..."

# 启动GDB
arm-linux-gnueabi-gdb "$VMLINUX" -ex "target remote localhost:1234"

# 当GDB退出后，终止QEMU
echo "GDB已退出，关闭QEMU..."
kill $QEMU_PID
```

使用方法：
```bash
chmod +x debug_qemu.sh
./debug_qemu.sh
```

## 参考资源

- [Linux内核文档 - printk](https://www.kernel.org/doc/html/latest/core-api/printk-basics.html)
- [Linux内核文档 - Dynamic Debug](https://www.kernel.org/doc/html/latest/admin-guide/dynamic-debug-howto.html)
- [Linux内核文档 - ftrace](https://www.kernel.org/doc/html/latest/trace/ftrace.html)
- [Linux内核文档 - KASAN](https://www.kernel.org/doc/html/latest/dev-tools/kasan.html)
