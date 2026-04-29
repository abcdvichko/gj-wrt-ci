#!/bin/bash
# DIY Part2: 深度定制和插件集成
# 在 make menuconfig 之前执行

echo "========== GJ-WRT DIY Part2 =========="

# ====================
# 1. 修改默认配置
# ====================

# 确保 LAN IP 为 10.7.7.1
sed -i 's/192.168.1.1/10.7.7.1/g' package/base-files/files/bin/config_generate

# 修改默认密码 (root/空密码改为 root/admin)
# sed -i 's/root:::0:99999:7:::/root:$1$V4UetPzk$CYXluq4wUazHjmCDBqEGe1:0:0:99999:7:::/g' package/base-files/files/etc/shadow

# 修改默认主机名
sed -i 's/OpenWrt/GJ-WRT/g' package/base-files/files/bin/config_generate

# 添加自定义 banner
cat > package/base-files/files/etc/banner <<'EOF'
  _______       _____       __      __   __
 / ___/ /  ___ / _/ /____ _/ /_____/ /  / /
/ /__/ _ \/ -_) _/ __/ _ `/ __/ __/ _ \/ / 
\___/_//_/\__/_/  \__/\_,_/\__/\__/_//_/_/  

        GJ-WRT 智能路由器固件
        管理地址: http://10.7.7.1
        WiFi: GJ-Llink-2.4G / GJ-Llink-5G
        密码: 77777777

====================================================
EOF

# ====================
# 2. 集成 GJ-SDWAN
# ====================

# 创建 GJ-SDWAN 插件目录结构
mkdir -p package/gj-sdwan/files/usr/lib/lua/luci/model/cbi/gj-sdwan
mkdir -p package/gj-sdwan/files/usr/lib/lua/luci/controller
mkdir -p package/gj-sdwan/files/etc/config
mkdir -p package/gj-sdwan/files/etc/init.d
mkdir -p package/gj-sdwan/files/usr/bin

# GJ-SDWAN 控制器文件
cat > package/gj-sdwan/files/usr/lib/lua/luci/controller/gj-sdwan.lua <<'EOF'
module("luci.controller.gj-sdwan", package.seeall)

function index()
    if not nixio.fs.access("/etc/config/gj-sdwan") then
        return
    end

    local page = entry({"admin", "services", "gj-sdwan"}, 
        cbi("gj-sdwan/overview"), 
        _("GJ-SDWAN"), 60)
    page.dependent = true
    page.acl_depends = { "luci-app-gj-sdwan" }

    entry({"admin", "services", "gj-sdwan", "nodes"}, 
        cbi("gj-sdwan/nodes"), 
        _("节点管理"), 1).leaf = true
    entry({"admin", "services", "gj-sdwan", "tunnels"}, 
        cbi("gj-sdwan/tunnels"), 
        _("隧道管理"), 2).leaf = true
    entry({"admin", "services", "gj-sdwan", "routes"}, 
        cbi("gj-sdwan/routes"), 
        _("智能路由"), 3).leaf = true
    entry({"admin", "services", "gj-sdwan", "monitor"}, 
        cbi("gj-sdwan/monitor"), 
        _("监控中心"), 4).leaf = true
    entry({"admin", "services", "gj-sdwan", "status"}, 
        call("act_status")).leaf = true
end

function act_status()
    local sys = require "luci.sys"
    local http = require "luci.http"
    local uci = require "luci.model.uci".cursor()

    local status = {
        running = (sys.call("pgrep -f gj-sdwan >/dev/null") == 0),
        version = "2.2.0",
        nodes = 0,
        tunnels = 0
    }

    uci:foreach("gj-sdwan", "node", function(s)
        status.nodes = status.nodes + 1
    end)

    uci:foreach("gj-sdwan", "tunnel", function(s)
        status.tunnels = status.tunnels + 1
    end)

    http.prepare_content("application/json")
    http.write_json(status)
end
EOF

# GJ-SDWAN 配置文件
cat > package/gj-sdwan/files/etc/config/gj-sdwan <<'EOF'
config global 'global'
    option enabled '1'
    option log_level 'info'
    option controller 'https://sd.gjlink.xyz'
    option api_key ''
    option heartbeat_interval '30'
    option auto_failover '1'

config node 'local'
    option name 'Local-Router'
    option type 'gateway'
    option wan_ifname 'eth0'
    option lan_ifname 'br-lan'
    option public_ip ''
    option private_ip '10.7.7.1'
    option status 'active'
EOF

# GJ-SDWAN 启动脚本
cat > package/gj-sdwan/files/etc/init.d/gj-sdwan <<'EOF'
#!/bin/sh /etc/rc.common

START=99
STOP=10

USE_PROCD=1

PROG=/usr/bin/gj-sdwan
CONF=/etc/config/gj-sdwan

start_service() {
    config_load gj-sdwan

    local enabled
    config_get enabled global enabled 0

    [ "$enabled" -eq 1 ] || return 0

    procd_open_instance
    procd_set_param command $PROG -c $CONF
    procd_set_param respawn
    procd_set_param stdout 1
    procd_set_param stderr 1
    procd_close_instance
}

stop_service() {
    killall -9 gj-sdwan 2>/dev/null
}

reload_service() {
    stop
    start
}
EOF
chmod +x package/gj-sdwan/files/etc/init.d/gj-sdwan

# GJ-SDWAN Makefile
cat > package/gj-sdwan/Makefile <<'EOF'
include $(TOPDIR)/rules.mk

PKG_NAME:=gj-sdwan
PKG_VERSION:=2.2.0
PKG_RELEASE:=1

PKG_MAINTAINER:=GJ-Link <support@gj-link.com>
PKG_LICENSE:=GPL-2.0

include $(INCLUDE_DIR)/package.mk

define Package/gj-sdwan
  SECTION:=net
  CATEGORY:=Network
  SUBMENU:=VPN
  TITLE:=GJ-SDWAN Controller
  DEPENDS:=+libubox +libubus +libuci +kmod-tun +wireguard-tools +curl +jq
  PKGARCH:=all
endef

define Package/gj-sdwan/description
  GJ-SDWAN 智能组网控制器
  支持 WireGuard 隧道、智能路由、节点管理
endef

define Package/luci-app-gj-sdwan
  SECTION:=luci
  CATEGORY:=LuCI
  SUBMENU:=3. Applications
  TITLE:=GJ-SDWAN LuCI Interface
  DEPENDS:=+gj-sdwan +luci-base
  PKGARCH:=all
endef

define Build/Compile
endef

define Package/gj-sdwan/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) ./files/usr/bin/gj-sdwan $(1)/usr/bin/
	$(INSTALL_DIR) $(1)/etc/config
	$(INSTALL_CONF) ./files/etc/config/gj-sdwan $(1)/etc/config/
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) ./files/etc/init.d/gj-sdwan $(1)/etc/init.d/
endef

define Package/luci-app-gj-sdwan/install
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci/controller
	$(INSTALL_DATA) ./files/usr/lib/lua/luci/controller/gj-sdwan.lua $(1)/usr/lib/lua/luci/controller/
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci/model/cbi/gj-sdwan
	$(INSTALL_DATA) ./files/usr/lib/lua/luci/model/cbi/gj-sdwan/*.lua $(1)/usr/lib/lua/luci/model/cbi/gj-sdwan/
endef

$(eval $(call BuildPackage,gj-sdwan))
$(eval $(call BuildPackage,luci-app-gj-sdwan))
EOF

# 创建简单的 gj-sdwan 二进制占位脚本
mkdir -p package/gj-sdwan/files/usr/bin
cat > package/gj-sdwan/files/usr/bin/gj-sdwan <<'EOF'
#!/bin/sh
# GJ-SDWAN 控制器主程序
# 实际使用时替换为真实编译的二进制

CONF="$2"
LOG_FILE="/var/log/gj-sdwan.log"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

log "GJ-SDWAN 控制器启动"
log "配置文件: $CONF"

# 保持运行
while true; do
    sleep 30
    log "心跳检测正常"
done
EOF
chmod +x package/gj-sdwan/files/usr/bin/gj-sdwan

# ====================
# 3. 双权限系统支持
# ====================

# 修改 LuCI 菜单，实现权限分离
mkdir -p package/base-files/files/etc/uci-defaults

cat > package/base-files/files/etc/uci-defaults/98-gj-wrt-permissions <<'EOF'
#!/bin/sh
# GJ-WRT 双权限系统初始化

# 创建普通管理员账户 (默认密码: admin123)
# 实际使用时建议首次登录修改

# 配置 RBAC (基于角色的访问控制)
uci add rpcd login
uci set rpcd.@login[-1].username='admin'
uci set rpcd.@login[-1].password='$p$admin'
uci set rpcd.@login[-1].read='*'
uci set rpcd.@login[-1].write='admin.services.gj-sdwan admin.services.passwall admin.services.passwall2 admin.system.admin'

uci add rpcd login
uci set rpcd.@login[-1].username='user'
uci set rpcd.@login[-1].password='$p$user'
uci set rpcd.@login[-1].read='*'
uci set rpcd.@login[-1].write='admin.network admin.wireless admin.system.admin admin.services.ddns admin.services.upnp'

uci commit rpcd

# 设置默认登录页面提示
cat > /etc/config/gj-wrt <<'INNEREOF'
config system 'info'
    option product_name 'GJ-WRT Pro'
    option hardware_version 'MT7981B-v1.0'
    option firmware_version '24.10.0'
    option admin_ip '10.7.7.1'
    option default_ssid_2g 'GJ-Llink-2.4G'
    option default_ssid_5g 'GJ-Llink-5G'
    option default_wifi_key '77777777'
INNEREOF
EOF
chmod +x package/base-files/files/etc/uci-defaults/98-gj-wrt-permissions

# ====================
# 4. 主题和 UI 优化
# ====================

# 下载 Argon 主题 (如果 feeds 中没有)
if [ ! -d "feeds/luci/themes/luci-theme-argon" ]; then
    git clone --depth 1 https://github.com/jerrykuku/luci-theme-argon.git package/luci-theme-argon 2>/dev/null || true
fi

# 设置默认主题为 Argon
sed -i 's/luci-theme-bootstrap/luci-theme-argon/g' feeds/luci/collections/luci/Makefile 2>/dev/null || true
sed -i 's/luci-theme-bootstrap/luci-theme-argon/g' package/feeds/luci/luci/Makefile 2>/dev/null || true

# ====================
# 5. 网络优化
# ====================

# 启用 BBR
sed -i '/net.ipv4.tcp_congestion_control/d' package/kernel/linux/files/sysctl-tcp-bbr.conf 2>/dev/null || true
echo 'net.ipv4.tcp_congestion_control=bbr' >> package/base-files/files/etc/sysctl.conf 2>/dev/null || true

# 优化网络参数
cat >> package/base-files/files/etc/sysctl.conf <<'EOF'
# GJ-WRT 网络优化
net.core.rmem_max = 67108864
net.core.wmem_max = 67108864
net.ipv4.tcp_rmem = 4096 87380 67108864
net.ipv4.tcp_wmem = 4096 65536 67108864
net.ipv4.tcp_mtu_probing = 1
net.ipv4.tcp_fastopen = 3
net.netfilter.nf_conntrack_max = 65536
EOF

# ====================
# 6. 在线升级支持
# ====================

# 配置 attendedsysupgrade
sed -i 's|https://sysupgrade.openwrt.org|https://firmware.gj-link.com/api|g' \
    package/feeds/luci/luci-app-attendedsysupgrade/root/usr/share/ucode/templates/attendedsysupgrade.uc 2>/dev/null || true

echo "========== DIY Part2 完成 =========="
