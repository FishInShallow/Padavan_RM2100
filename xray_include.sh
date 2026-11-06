#!/bin/sh
# xray 独立插件公共函数库
# 供 rc/firewall/dnsmasq 等系统脚本调用
# 位置: /opt/rt-n56u/trunk/user/xray/xray_include.sh

# 引用此文件: . /opt/bin/xray_include.sh

XRAY_START="/opt/bin/start_xray.sh"

# ============================================================
# NVRAM 辅助
# ============================================================
xray_nvram_get() {
    nvram get "$1" 2>/dev/null
}

xray_enabled() {
    [ "$(xray_nvram_get "xray_enable")" = "1" ]
}

xray_run_mode() {
    xray_nvram_get "xray_run_mode"
}

# ============================================================
# 启动/停止/重载 (供 rc 调用)
# ============================================================
xray_start() {
    xray_enabled || return 0
    [ -x "$XRAY_START" ] && "$XRAY_START" start
}

xray_stop() {
    [ -x "$XRAY_START" ] && "$XRAY_START" stop
}

xray_restart() {
    [ -x "$XRAY_START" ] && "$XRAY_START" restart
}

xray_reload() {
    [ -x "$XRAY_START" ] && "$XRAY_START" reload
}

# ============================================================
# 防火墙规则 (供 firewall 调用)
# ============================================================
xray_firewall_start() {
    xray_enabled || return 0
    [ -x "$XRAY_START" ] && "$XRAY_START" start >/dev/null 2>&1 &
}

xray_firewall_stop() {
    [ -x "$XRAY_START" ] && "$XRAY_START" stop >/dev/null 2>&1
}

# ============================================================
# DNS 相关 (供 dnsmasq/wan 调用)
# ============================================================
xray_dns_restart() {
    # 重载配置以更新 DNS 服务器
    xray_enabled && xray_reload
}

# ============================================================
# 状态查询
# ============================================================
xray_status() {
    [ -x "$XRAY_START" ] && "$XRAY_START" status
}

xray_pid() {
    [ -f /var/run/xray.pid ] && cat /var/run/xray.pid
}

# ============================================================
# 节点切换 (供 Web UI 调用)
# ============================================================
xray_switch_node() {
    local node_idx="$1"
    if [ -n "$node_idx" ] && [ "$node_idx" -gt 0 ] 2>/dev/null; then
        nvram set xray_global_server="$node_idx"
        nvram commit
        xray_reload
    fi
}

# ============================================================
# 订阅更新后触发
# ============================================================
xray_on_subscribe_updated() {
    # 订阅更新后重新生成配置并热重载
    xray_enabled && xray_reload
}

# ============================================================
# GeoIP/GeoSite 更新后触发
# ============================================================
xray_on_geo_updated() {
    # Geo 文件更新后需重启以重新加载
    xray_enabled && xray_restart
}

# ============================================================
# 导出函数
# ============================================================
# 无需额外 export，source 此文件即可使用上述函数