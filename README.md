# LXD和LXD的管理

### 基本概念

**LXC** 容器的底层工具

**LXD** 管理LXC的工具，基本用不上相关命令

**IMAGES** 镜像，指打包好的独立镜像，可以从以镜像为底子启动容器

**CONTAINER** 容器，正在运行的虚拟化实例，从镜像启动，可以打快照，每个容器内部自成一体，与外界隔离

**宿主机** 运行lxc/lxd的主机，本例中即此台物理机

### 当前系统的组成

1. 系统共两块磁盘，其中2T用于系统，2T用于容器，之后若空间不足，可以将部分系统的配额也共享给容器使用。

2. lxc 4.0提供运行环境，命令如`lxc list`, `lxc start <containname>`

3. 每一个容器内启用ssh，端口是8880（外部用户无需关心）

4. 宿主机上启用iptables 进行端口转发，如将 *宿主机:2001* 转发至 *容器1:8880*，由此可让用户直接ssh进容器内部。

### 常用操作

1. 新加用户。
   ```shell
   cd /root/manager
   ./new_user.sh username
   # 会提示对应的端口
   # keys 文件夹下会成对应的私钥文件
   # 将端口和私钥，发给申请者
   # 使用 ssh -i 私钥 -p 端口 root@宿主机IP 连接 
   ```
   会自动克隆ubuntu-template的容器，并给它配置好端口转发

2. 查看容器的使用情况
   ```shell
   lxc info s-username
   ```
3. 删除容器
   ```shell
   lxc stop s-username && lxc rm s-username
   ```
4. iptables规则丢失，需要修复转发规则
   ```shell
   cd /root/manager
   ./refresh_ports.sh
   ```

5. 快照。快照可以非常方便的恢复到某一历史状态，具体操作见lxc文档（注意为4.0）
