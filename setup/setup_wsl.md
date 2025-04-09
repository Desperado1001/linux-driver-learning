# WSL2 环境配置指南

本文档提供了在Windows 10/11上配置WSL2环境以进行Linux驱动开发的详细步骤。

## 安装和配置WSL2

### 1. 启用WSL2

打开PowerShell（以管理员身份运行）并执行以下命令：

```powershell
# 启用WSL和虚拟机平台功能
dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart
dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart

# 重启计算机
# 重启后继续以下步骤

# 设置WSL2为默认版本
wsl --set-default-version 2
```

### 2. 安装Linux发行版

从Microsoft Store安装Ubuntu 22.04 LTS（或您喜欢的其他发行版）。

或使用PowerShell命令行安装：

```powershell
# 列出可用的Linux发行版
wsl --list --online

# 安装Ubuntu 22.04
wsl --install -d Ubuntu-22.04
```

### 3. 初始化WSL2

首次启动WSL2时，会提示您创建用户名和密码。完成此设置。

### 4. WSL2性能优化

为提高性能，建议创建`.wslconfig`文件来限制WSL2的资源使用：

在Windows中，创建文件：`C:\Users\<您的用户名>\.wslconfig`，内容如下：

```ini
[wsl2]
memory=8GB
processors=4
swap=2GB
```

根据您的系统资源调整这些值。

### 5. 配置图形界面（可选）

如果需要在WSL2中使用图形应用程序：

1. 在Windows上安装X服务器，如[VcXsrv](https://sourceforge.net/projects/vcxsrv/)或[Xming](https://sourceforge.net/projects/xming/)

2. 在WSL2中添加DISPLAY环境变量。编辑`~/.bashrc`文件：

```bash
echo 'export DISPLAY=$(grep -m 1 nameserver /etc/resolv.conf | awk "{print \$2}"):0.0' >> ~/.bashrc
source ~/.bashrc
```

## 安装开发工具

在WSL2的Ubuntu环境中执行以下命令安装必要的开发工具：

```bash
# 运行本仓库提供的安装脚本
bash ./install_dependencies.sh
```

或手动安装：

```bash
sudo apt update
sudo apt install -y build-essential git vim nano
sudo apt install -y flex bison libssl-dev libelf-dev bc
sudo apt install -y libncurses-dev 
sudo apt install -y gcc-arm-linux-gnueabi binutils-arm-linux-gnueabi
sudo apt install -y qemu-system-arm
```

## WSL2特有配置

### 文件系统性能

* 避免在Windows挂载的目录中编译（如`/mnt/c/`）
* 使用WSL2原生文件系统（`/home/<用户>/`目录）进行内核编译和驱动开发

### 网络设置

WSL2使用NAT网络，如果需要在Windows访问WSL2中的服务，需要使用端口转发：

```powershell
# PowerShell示例 - 将WSL2的22端口转发到Windows的2222端口
netsh interface portproxy add v4tov4 listenport=2222 listenaddress=0.0.0.0 connectport=22 connectaddress=$(wsl hostname -I)
```

### 使用Visual Studio Code

VS Code可以直接与WSL2集成，提供高效的开发体验：

1. 在Windows中安装VS Code
2. 安装[Remote - WSL](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-wsl)扩展
3. 在WSL2命令行中，进入项目目录并输入`code .`

## 故障排除

### WSL2版本检查

```bash
wsl --list --verbose
```

确保您的Linux发行版在"VERSION"列中显示"2"。

### 升级WSL

如果遇到问题，可以尝试升级WSL：

```powershell
wsl --update
```

### 内存不足问题

如果遇到内存不足错误，请调整`.wslconfig`文件中的内存分配。

### 图形界面问题

如果X11应用程序无法显示，确认：

1. X服务器正在Windows中运行
2. 防火墙允许X服务器接收连接
3. DISPLAY环境变量设置正确

## 下一步

环境配置完成后，您可以继续以下步骤：

1. 获取Linux内核源码
2. 配置和编译ARM架构的内核
3. 准备QEMU环境
4. 开始驱动开发

请参考本仓库中的其他文档获取这些步骤的详细说明。
