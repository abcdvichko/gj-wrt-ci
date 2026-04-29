#!/bin/bash
# DIY Part1: 更新 feeds 和基础修改
# 在 feeds update 之后执行

echo "========== GJ-WRT DIY Part1 =========="

# 修改默认 LAN IP 为 10.7.7.1
sed -i 's/192.168.1.1/10.7.7.1/g' package/base-files/files/bin/config_generate
sed -i 's/192.168.1.1/10.7.7.1/g' package/base-files/luci2/bin/config_generate 2>/dev/null || true

# 修改默认主机名
sed -i 's/OpenWrt/GJ-WRT/g' package/base-files/files/bin/config_generate

# 修改默认时区为上海
sed -i "s/'UTC'/'CST-8'/g" package/base-files/files/bin/config_generate
sed -i "/'CST-8'/a \\		set system.@system[-1].zonename='Asia/Shanghai'" package/base-files/files/bin/config_generate

# 修改默认 WiFi SSID 和密码
cat > package/base-files/files/etc/uci-defaults/99-gj-wrt-wifi <<'EOF'
#!/bin/sh
# GJ-WRT WiFi 默认配置

# 2.4G
uci set wireless.radio0.disabled='0'
uci set wireless.default_radio0.ssid='GJ-Llink-2.4G'
uci set wireless.default_radio0.encryption='psk2'
uci set wireless.default_radio0.key='77777777'
uci set wireless.default_radio0.mode='ap'

# 5G
uci set wireless.radio1.disabled='0'
uci set wireless.default_radio1.ssid='GJ-Llink-5G'
uci set wireless.default_radio1.encryption='psk2'
uci set wireless.default_radio1.key='77777777'
uci set wireless.default_radio1.mode='ap'

uci commit wireless
EOF
chmod +x package/base-files/files/etc/uci-defaults/99-gj-wrt-wifi

# 添加 GJ-SDWAN 源 (如果 feeds.conf.default 中没有)
if ! grep -q "gj-sdwan" feeds.conf.default 2>/dev/null; then
    echo "src-git gj_sdwan https://github.com/your-repo/gj-sdwan-openwrt.git" >> feeds.conf.default
fi

# 添加 PassWall 源
if ! grep -q "passwall" feeds.conf.default 2>/dev/null; then
    echo "src-git passwall https://github.com/xiaorouji/openwrt-passwall.git;main" >> feeds.conf.default
    echo "src-git passwall_packages https://github.com/xiaorouji/openwrt-passwall-packages.git;main" >> feeds.conf.default
fi

# 更新和安装 feeds
./scripts/feeds update -a
./scripts/feeds install -a

echo "========== DIY Part1 完成 =========="
