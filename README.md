# GJ-WRT 固件编译项目

## 项目简介

基于 OpenWrt 24.10 的 MT7981B 路由器固件，集成 GJ-SDWAN 智能组网功能。

## 设备信息

- **处理器**: 联发科 MT7981B (双核 1.3GHz ARM)
- **内存**: 256MB DDR3
- **闪存**: 128MB SPI-NAND
- **网络**: 1WAN + 3LAN (千兆)
- **无线**: WiFi6 2.4G + 5G

## 默认配置

| 项目 | 值 |
|------|-----|
| 管理地址 | http://10.7.7.1 |
| 2.4G SSID | GJ-Llink-2.4G |
| 5G SSID | GJ-Llink-5G |
| WiFi 密码 | 77777777 |
| 主机名 | GJ-WRT |
| 时区 | Asia/Shanghai |

## 双权限系统

- **超级管理员**: 访问所有功能（PassWall、WireGuard、GJ-SDWAN 等高级插件）
- **普通管理员**: 基础功能（网络设置、WiFi、DDNS、在线升级）

## 内置插件

### 高级功能（超级管理员）
- PassWall / PassWall2
- WireGuard
- NPS/NPC 客户端
- TurboACC 网络加速
- GJ-SDWAN 智能组网

### 基础功能（普通管理员）
- DDNS
- UPnP
- 在线升级 (Attended Sysupgrade)
- WiFi 定时开关

## 使用方法

### 1. Fork 本仓库

点击右上角 Fork 按钮，将仓库复制到您的 GitHub 账户。

### 2. 配置 GitHub Actions

进入仓库 Settings -> Secrets and variables -> Actions，添加以下 Secrets：

- `TELEGRAM_BOT_TOKEN` (可选): Telegram 机器人 Token
- `TELEGRAM_CHAT_ID` (可选): Telegram 聊天 ID

### 3. 手动触发编译

进入 Actions 页面，选择 "GJ-WRT CI Build"，点击 "Run workflow"。

### 4. 下载固件

编译完成后，固件将自动上传到 Release 页面。

## 本地编译

```bash
# 克隆仓库
git clone https://github.com/your-username/gj-wrt-ci.git
cd gj-wrt-ci

# 安装依赖 (Ubuntu/Debian)
sudo apt update
sudo apt install -y build-essential ccache ecj fastjar file g++ gawk     gettext git java-propose-classpath libelf-dev libncurses5-dev     libncursesw5-dev libssl-dev python python2.7-dev python3 unzip wget     python3-distutils python3-setuptools python3-dev rsync subversion     swig time xsltproc zlib1g-dev

# 执行编译
bash scripts/diy-part1.sh
bash scripts/diy-part2.sh
cd openwrt
make menuconfig
make -j$(nproc)
```

## 目录结构

```
.
├── .github/workflows/          # GitHub Actions 工作流
│   └── build-gj-wrt.yml       # 编译配置
├── configs/                    # OpenWrt 编译配置
│   └── mt7981b-gj-wrt.config  # MT7981B 配置
├── scripts/                    # DIY 脚本
│   ├── diy-part1.sh           # 基础修改
│   └── diy-part2.sh           # 深度定制
├── feeds.conf.default         # Feeds 源配置
└── README.md                  # 本文件
```

## 注意事项

1. 编译过程大约需要 2-4 小时，请耐心等待
2. GitHub Actions 免费用户有 2000 分钟/月的限制
3. 建议配置 Telegram 通知，编译完成后及时获取通知
4. 首次刷机建议通过 Breed/不死控制台刷入

## 许可证

GPL-2.0

## 联系方式

- 官网: https://www.gj-link.com
- 技术支持: support@gj-link.com
