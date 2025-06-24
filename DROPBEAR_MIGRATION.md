# SSH服务迁移：从OpenSSH到Dropbear

## 更改概述

此Docker镜像已从OpenSSH服务器（sshd）迁移到Dropbear SSH服务器，以提供更轻量级的SSH访问。

## 主要更改

### 1. 软件包替换
- 移除：`openssh-server`
- 添加：`dropbear-bin`

### 2. 服务配置
- **端口**: 22 (保持不变)
- **启动方式**: Dropbear以前台模式运行 (`-F`)
- **日志**: 错误输出到stderr (`-E`)
- **PID文件**: `/var/run/dropbear.pid`

### 3. 文件结构更改
```
删除的文件：
- configs/sshd_config
- s6-rc.d/sshd/
- s6-rc.d/sshd-log/
- configs/fail2ban-jail.d-sshd.conf

新增的文件：
- s6-rc.d/dropbear/
- s6-rc.d/dropbear-log/
- configs/fail2ban-jail.d-dropbear.conf
```

### 4. Fail2ban配置
- jail名称从 `sshd` 改为 `dropbear`
- 日志路径从 `/var/log/sshd/current` 改为 `/var/log/dropbear/current`
- 使用dropbear专用的fail2ban过滤器

## Dropbear特性

### 优势
- **轻量级**: 比OpenSSH占用更少的内存和存储空间
- **简单**: 配置更简单，依赖更少
- **快速**: 启动速度更快

### 局限性
- **功能较少**: 相比OpenSSH功能相对简单
- **端口转发**: 支持有限的端口转发功能
- **配置选项**: 配置选项比OpenSSH少

## 使用说明

### SSH连接
连接方式与之前完全相同：
```bash
ssh root@container_ip
```

### 密钥认证
- Dropbear支持RSA、DSA、ECDSA密钥
- 公钥存放位置：`~/.ssh/authorized_keys`
- 密码认证已禁用（安全考虑）

### 故障排除

1. **检查Dropbear是否运行**
   ```bash
   ps aux | grep dropbear
   ```

2. **查看日志**
   ```bash
   tail -f /var/log/dropbear/current
   ```

3. **检查端口监听**
   ```bash
   netstat -tlnp | grep :22
   ```

## 迁移注意事项

- 所有SSH密钥验证功能保持不变
- 端口22保持不变
- 用户体验基本一致
- Fail2ban保护仍然有效

## 构建和运行

构建镜像：
```bash
docker build -t your-app:dropbear .
```

运行容器：
```bash
docker run -d -p 22:22 your-app:dropbear
``` 