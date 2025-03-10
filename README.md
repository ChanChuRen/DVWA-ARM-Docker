# DVWA 自动部署脚本

## 简介
这是一个用于自动部署 DVWA (Damn Vulnerable Web Application) 的 Shell 脚本。DVWA 是一个用于安全测试和教学的故意存在漏洞的 Web 应用程序。

## 适用范围
- 操作系统：Ubuntu 22.04 Server ARM
- 运行环境：Docker 容器 / 本地 linux(arm)
- 依赖组件：Apache2、MariaDB、PHP

## 主要功能
1. 自动安装并配置 LAMP 环境
2. 自动下载并部署最新版本的 DVWA
3. 自动配置数据库和必要的权限
4. 自动配置 Apache 虚拟主机
5. 自动配置 PHP 运行环境
6. 自动设置安全所需的文件权限

## 使用方法
### 方式一：直接部署
1. 将脚本复制到目标系统
2. 赋予脚本执行权限：
   ```bash
   chmod +x dvwa.sh
3. 以 root 权限运行脚本：
   ```bash
   sudo ./dvwa.sh
### 方式二：Docker Compose 部署（推荐）
1. 将下载的 ```docker-compose.yml```文件和```dvwa.sh```文件放在同一目录下，在此目录打开命令行
2. 启动服务：
   ```bash
   docker compose up -d
3. 查看部署进度：
   ```bash
   docker compose logs -f
4. 看到如下图所示即完成部署

   <img width="506" alt="image" src="https://github.com/user-attachments/assets/d12948ba-979e-4eec-9e0b-53ca1d2df2c1" />

## 访问信息
### 直接部署
- 访问地址： http://[服务器IP]/DVWA
- Web 端口：80
### Docker 部署
- 访问地址： http://[服务器IP]:8800/DVWA
- Web 端口：8800

## 登录凭据
### Web 登录信息
- 用户名： admin
- 密码： password
### 数据库信息
- 数据库用户： dvwa
- 数据库密码： dvwa_password
- 数据库名： dvwa

## 注意事项
1. 本项目仅用于学习和测试目的
2. 请勿在生产环境中使用
3. 首次登录后建议立即修改密码
4. Docker 部署需要确保 8800 端口未被占用
5. 直接部署方式需要 root 权限
6. 部署过程需要保持网络连接

## 安全提醒
DVWA 是一个包含多个安全漏洞的应用程序，仅供安全学习使用。请勿在生产环境或公网环境部署此应用。

