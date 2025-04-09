/**
 * @file simple_char_driver.c
 * @brief 简单字符设备驱动示例
 * 
 * 这是一个简单的字符设备驱动示例，实现了基本的open/read/write/release操作。
 * 适合在WSL2 + QEMU环境中测试和学习Linux驱动开发。
 */

#include <linux/module.h>
#include <linux/kernel.h>
#include <linux/fs.h>
#include <linux/cdev.h>
#include <linux/device.h>
#include <linux/uaccess.h>

#define DEVICE_NAME "simple_char_dev"    /* 设备名称 */
#define CLASS_NAME "simple_char"         /* 设备类名称 */
#define BUFFER_SIZE 256                  /* 内部缓冲区大小 */

/* 模块参数 */
static int major_number = 0;             /* 动态分配主设备号 */
module_param(major_number, int, 0);
MODULE_PARM_DESC(major_number, "主设备号，为0则动态分配");

/* 驱动私有数据结构 */
struct simple_char_dev {
    struct cdev cdev;
    char buffer[BUFFER_SIZE];
    size_t buffer_size;
    struct mutex lock;                   /* 互斥锁 */
};

/* 全局变量 */
static struct simple_char_dev *dev;
static struct class *simple_char_class = NULL;
static struct device *simple_char_device = NULL;

/* 函数原型 */
static int dev_open(struct inode *, struct file *);
static int dev_release(struct inode *, struct file *);
static ssize_t dev_read(struct file *, char __user *, size_t, loff_t *);
static ssize_t dev_write(struct file *, const char __user *, size_t, loff_t *);
static long dev_ioctl(struct file *, unsigned int, unsigned long);

/**
 * 文件操作结构体
 * 
 * 定义了设备支持的文件操作，这些函数将被VFS调用
 */
static struct file_operations fops = {
    .owner = THIS_MODULE,
    .open = dev_open,
    .read = dev_read,
    .write = dev_write,
    .release = dev_release,
    .unlocked_ioctl = dev_ioctl,
};

/**
 * 设备打开函数
 * 
 * 当用户程序调用open()打开设备时被调用
 */
static int dev_open(struct inode *inodep, struct file *filep)
{
    /* 获取设备结构体指针 */
    struct simple_char_dev *dev = container_of(inodep->i_cdev, struct simple_char_dev, cdev);
    filep->private_data = dev;

    printk(KERN_INFO "simple_char: 设备已打开\n");
    return 0;
}

/**
 * 设备读取函数
 * 
 * 当用户程序调用read()从设备读取数据时被调用
 */
static ssize_t dev_read(struct file *filep, char __user *buffer, size_t len, loff_t *offset)
{
    int ret = 0;
    struct simple_char_dev *dev = filep->private_data;
    
    /* 获取互斥锁 */
    if (mutex_lock_interruptible(&dev->lock))
        return -ERESTARTSYS;
    
    /* 如果偏移量超过缓冲区大小，返回EOF */
    if (*offset >= dev->buffer_size) {
        mutex_unlock(&dev->lock);
        return 0;
    }
    
    /* 计算实际可读取的数据量 */
    if (*offset + len > dev->buffer_size)
        len = dev->buffer_size - *offset;
    
    /* 将数据复制到用户空间 */
    if (copy_to_user(buffer, dev->buffer + *offset, len)) {
        ret = -EFAULT;
        goto out;
    }
    
    /* 更新文件偏移量 */
    *offset += len;
    ret = len;
    
    printk(KERN_INFO "simple_char: 已读取 %zu 字节数据\n", len);
    
out:
    mutex_unlock(&dev->lock);
    return ret;
}

/**
 * 设备写入函数
 * 
 * 当用户程序调用write()向设备写入数据时被调用
 */
static ssize_t dev_write(struct file *filep, const char __user *buffer, size_t len, loff_t *offset)
{
    int ret = 0;
    struct simple_char_dev *dev = filep->private_data;
    
    /* 获取互斥锁 */
    if (mutex_lock_interruptible(&dev->lock))
        return -ERESTARTSYS;
    
    /* 限制写入长度不超过缓冲区大小 */
    if (len > BUFFER_SIZE - 1)
        len = BUFFER_SIZE - 1;
    
    /* 清空缓冲区 */
    memset(dev->buffer, 0, BUFFER_SIZE);
    
    /* 从用户空间复制数据 */
    if (copy_from_user(dev->buffer, buffer, len)) {
        ret = -EFAULT;
        goto out;
    }
    
    /* 更新缓冲区大小 */
    dev->buffer_size = len;
    dev->buffer[len] = '\0';  /* 确保以null结尾 */
    *offset = len;
    ret = len;
    
    printk(KERN_INFO "simple_char: 已写入 %zu 字节数据: %s\n", len, dev->buffer);
    
out:
    mutex_unlock(&dev->lock);
    return ret;
}

/**
 * 设备关闭函数
 * 
 * 当用户程序调用close()关闭设备时被调用
 */
static int dev_release(struct inode *inodep, struct file *filep)
{
    printk(KERN_INFO "simple_char: 设备已关闭\n");
    return 0;
}

/**
 * 设备ioctl函数
 * 
 * 用于支持设备的特殊控制命令
 */
static long dev_ioctl(struct file *filep, unsigned int cmd, unsigned long arg)
{
    struct simple_char_dev *dev = filep->private_data;
    
    /* 这里可以添加设备特定的ioctl命令 */
    switch (cmd) {
    case 0: /* 清空缓冲区 */
        if (mutex_lock_interruptible(&dev->lock))
            return -ERESTARTSYS;
        
        memset(dev->buffer, 0, BUFFER_SIZE);
        dev->buffer_size = 0;
        
        mutex_unlock(&dev->lock);
        printk(KERN_INFO "simple_char: ioctl - 缓冲区已清空\n");
        return 0;
    
    default:
        return -ENOTTY; /* 不支持的命令 */
    }
}

/**
 * 模块初始化函数
 * 
 * 在加载模块时调用
 */
static int __init simple_char_init(void)
{
    int ret;
    dev_t dev_no;
    
    printk(KERN_INFO "simple_char: 初始化模块\n");
    
    /* 分配设备结构体 */
    dev = kmalloc(sizeof(struct simple_char_dev), GFP_KERNEL);
    if (!dev) {
        printk(KERN_ALERT "simple_char: 无法分配内存\n");
        return -ENOMEM;
    }
    
    /* 初始化互斥锁 */
    mutex_init(&dev->lock);
    memset(dev->buffer, 0, BUFFER_SIZE);
    dev->buffer_size = 0;
    
    /* 分配设备号 */
    if (major_number) {
        dev_no = MKDEV(major_number, 0);
        ret = register_chrdev_region(dev_no, 1, DEVICE_NAME);
    } else {
        ret = alloc_chrdev_region(&dev_no, 0, 1, DEVICE_NAME);
        major_number = MAJOR(dev_no);
    }
    
    if (ret < 0) {
        printk(KERN_ALERT "simple_char: 无法分配设备号 %d\n", major_number);
        goto fail_chrdev;
    }
    
    printk(KERN_INFO "simple_char: 设备号 %d 已分配\n", major_number);
    
    /* 初始化字符设备 */
    cdev_init(&dev->cdev, &fops);
    dev->cdev.owner = THIS_MODULE;
    
    /* 添加字符设备到系统 */
    ret = cdev_add(&dev->cdev, dev_no, 1);
    if (ret < 0) {
        printk(KERN_ALERT "simple_char: 无法添加设备到系统\n");
        goto fail_cdev;
    }
    
    /* 创建设备类 */
    simple_char_class = class_create(THIS_MODULE, CLASS_NAME);
    if (IS_ERR(simple_char_class)) {
        ret = PTR_ERR(simple_char_class);
        printk(KERN_ALERT "simple_char: 无法创建设备类\n");
        goto fail_class;
    }
    
    /* 创建设备文件 */
    simple_char_device = device_create(simple_char_class, NULL, 
                                      MKDEV(major_number, 0), NULL, DEVICE_NAME);
    if (IS_ERR(simple_char_device)) {
        ret = PTR_ERR(simple_char_device);
        printk(KERN_ALERT "simple_char: 无法创建设备文件\n");
        goto fail_device;
    }
    
    printk(KERN_INFO "simple_char: 设备初始化完成，可以使用 /dev/%s\n", DEVICE_NAME);
    return 0;
    
fail_device:
    class_destroy(simple_char_class);
fail_class:
    cdev_del(&dev->cdev);
fail_cdev:
    unregister_chrdev_region(MKDEV(major_number, 0), 1);
fail_chrdev:
    kfree(dev);
    return ret;
}

/**
 * 模块清理函数
 * 
 * 在卸载模块时调用
 */
static void __exit simple_char_exit(void)
{
    /* 销毁设备文件和类 */
    device_destroy(simple_char_class, MKDEV(major_number, 0));
    class_destroy(simple_char_class);
    
    /* 删除字符设备 */
    cdev_del(&dev->cdev);
    
    /* 释放设备号 */
    unregister_chrdev_region(MKDEV(major_number, 0), 1);
    
    /* 释放设备结构体 */
    kfree(dev);
    
    printk(KERN_INFO "simple_char: 模块已卸载\n");
}

/* 指定模块入口和出口函数 */
module_init(simple_char_init);
module_exit(simple_char_exit);

/* 模块许可证和信息 */
MODULE_LICENSE("GPL");
MODULE_AUTHOR("Desperado1001");
MODULE_DESCRIPTION("简单字符设备驱动示例");
MODULE_VERSION("0.1");
