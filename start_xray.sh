#!/bin/sh
# xray 独立插件启动脚本
# 位置: /opt/rt-n56u/trunk/user/xray/start_xray.sh
# 目标: xray v26.10.31

XRAY_BIN="/opt/bin/xray"
GENCONFIG="/opt/bin/genconfig.lua"
CONFIG_DIR="/tmp/xray"
CONFIG_FILE="$CONFIG_DIR/config.json"
PID_FILE="/var/run/xray.pid"
LOG_FILE="/tmp/xray.log"
RUN_FILE="/var/run/xray.run"

# NVRAM 获取函数
nvram_get() {
    nvram get "$1" 2>/dev/null
}

nvram_match() {
    [ "$(nvram_get "$1")" = "$2" ]
}

# 日志函数
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"
}

# 检查 xray 二进制
check_binary() {
    if [ ! -x "$XRAY_BIN" ]; then
        log "ERROR: xray binary not found or not executable: $XRAY_BIN"
        return 1
    fi
    return 0
}

# 检查 genconfig.lua
check_genconfig() {
    if [ ! -f "$GENCONFIG" ]; then
        log "ERROR: genconfig.lua not found: $GENCONFIG"
        return 1
    fi
    return 0
}

# 生成配置文件
generate_config() {
    mkdir -p "$CONFIG_DIR"
    log "Generating xray config..."

    # 运行 lua 生成配置
    lua "$GENCONFIG" > "$CONFIG_FILE" 2>>"$LOG_FILE"

    if [ $? -ne 0 ] || [ ! -s "$CONFIG_FILE" ]; then
        log "ERROR: Failed to generate config"
        return 1
    fi

    # 校验配置语法
    if ! "$XRAY_BIN" -test -config "$CONFIG_FILE" >>"$LOG_FILE" 2>&1; then
        log "ERROR: Config test failed"
        cat "$CONFIG_FILE" >>"$LOG_FILE"
        return 1
    fi

    log "Config generated and validated: $CONFIG_FILE"
    return 0
}

# 应用防火墙规则
apply_firewall() {
    local run_mode=$(nvram_get "xray_run_mode")
    local local_port=$(nvram_get "xray_local_port")
    local lan_ip=$(nvram_get "lan_ipaddr")
    local lan_netmask=$(nvram_get "lan_netmask")

    log "Applying firewall rules..."

    # 创建 xray 链
    iptables -t nat -N XRAY 2>/dev/null
    iptables -t mangle -N XRAY 2>/dev/null
    iptables -t nat -F XRAY 2>/dev/null
    iptables -t mangle -F XRAY 2>/dev/null

    # 返回规则：保留地址、局域网、服务器 IP 直连
    local server_ip=$(nvram_get "xray_server_ip")
    [ -n "$server_ip" ] && iptables -t nat -A XRAY -d "$server_ip" -j RETURN
    iptables -t nat -A XRAY -d 0.0.0.0/8 -j RETURN
    iptables -t nat -A XRAY -d 10.0.0.0/8 -j RETURN
    iptables -t nat -A XRAY -d 127.0.0.0/8 -j RETURN
    iptables -t nat -A XRAY -d 169.254.0.0/16 -j RETURN
    iptables -t nat -A XRAY -d 172.16.0.0/12 -j RETURN
    iptables -t nat -A XRAY -d 192.168.0.0/16 -j RETURN
    iptables -t nat -A XRAY -d 224.0.0.0/4 -j RETURN
    iptables -t nat -A XRAY -d 240.0.0.0/4 -j RETURN

    # 运行模式差异
    case "$run_mode" in
        "gfw")
            # GFW 列表模式：走 ipset 分流
            ipset -N gfwlist iphash 2>/dev/null
            ipset -F gfwlist 2>/dev/null
            # 这里需要配合 dnsmasq/ipset 更新脚本，暂留接口
            iptables -t nat -A XRAY -m set --match-set gfwlist dst -j REDIRECT --to-ports "$local_port"
            ;;
        "router"|"all")
            # 绕过大陆/全局：默认重定向，大陆 IP 除外
            iptables -t nat -A XRAY -p tcp -j REDIRECT --to-ports "$local_port"
            # 需要配合 chnroute ipset 排除大陆 IP
            ipset -N chnroute iphash 2>/dev/null
            iptables -t nat -A XRAY -m set --match-set chnroute dst -j RETURN
            ;;
        "oversea")
            # 海外模式：大陆 IP 走代理
            iptables -t nat -A XRAY -m set --match-set chnroute dst -j REDIRECT --to-ports "$local_port"
            ;;
    esac

    # 应用到 PREROUTING
    iptables -t nat -D PREROUTING -j XRAY 2>/dev/null
    iptables -t nat -I PREROUTING -j XRAY

    # OUTPUT 链（本机流量）
    iptables -t nat -D OUTPUT -j XRAY 2>/dev/null
    if [ "$(nvram_get "xray_proxy_local")" = "1" ]; then
        iptables -t nat -I OUTPUT -j XRAY
    fi

    log "Firewall rules applied"
}

# 移除防火墙规则
remove_firewall() {
    log "Removing firewall rules..."
    iptables -t nat -D PREROUTING -j XRAY 2>/dev/null
    iptables -t nat -D OUTPUT -j XRAY 2>/dev/null
    iptables -t nat -F XRAY 2>/dev/null
    iptables -t nat -X XRAY 2>/dev/null
    iptables -t mangle -F XRAY 2>/dev/null
    iptables -t mangle -X XRAY 2>/dev/null
    ipset -X gfwlist 2>/dev/null
    ipset -X chnroute 2>/dev/null
}

# 应用路由规则 (ip rule / ip route)
apply_routing() {
    local run_mode=$(nvram_get "xray_run_mode")
    local fwmark=255
    local table_id=100

    log "Applying routing rules..."

    # 创建路由表
    ip rule add fwmark "$fwmark" table "$table_id" 2>/dev/null
    ip route add local 0.0.0.0/0 dev lo table "$table_id" 2>/dev/null

    # TUN 模式额外路由
    if [ "$(nvram_get "xray_tun_enable")" = "1" ]; then
        ip route add 172.19.0.0/30 dev tun0 2>/dev/null
        ip route add fd00::/126 dev tun0 2>/dev/null
    fi
}

remove_routing() {
    local fwmark=255
    local table_id=100
    ip rule del fwmark "$fwmark" table "$table_id" 2>/dev/null
    ip route del local 0.0.0.0/0 dev lo table "$table_id" 2>/dev/null
}

# 启动 xray
start_xray() {
    log "Starting xray..."

    # 后台运行
    "$XRAY_BIN" run -config "$CONFIG_FILE" >>"$LOG_FILE" 2>&1 &
    local pid=$!
    echo $pid > "$PID_FILE"

    # 等待启动
    sleep 2

    if kill -0 $pid 2>/dev/null; then
        log "xray started with PID $pid"
        echo "1" > "$RUN_FILE"
        return 0
    else
        log "ERROR: xray failed to start"
        cat "$LOG_FILE" | tail -20
        return 1
    fi
}

# 停止 xray
stop_xray() {
    if [ -f "$PID_FILE" ]; then
        local pid=$(cat "$PID_FILE")
        if kill -0 $pid 2>/dev/null; then
            log "Stopping xray (PID $pid)..."
            kill $pid 2>/dev/null
            sleep 1
            kill -9 $pid 2>/dev/null 2>&1
        fi
        rm -f "$PID_FILE"
    fi
    echo "0" > "$RUN_FILE"
    log "xray stopped"
}

# 热重载 (SIGHUP)
reload_xray() {
    if [ -f "$PID_FILE" ]; then
        local pid=$(cat "$PID_FILE")
        if kill -0 $pid 2>/dev/null; then
            log "Reloading xray config..."
            if generate_config; then
                kill -HUP $pid 2>/dev/null
                log "Reload signal sent"
                return 0
            fi
        fi
    fi
    return 1
}

# 获取状态
status_xray() {
    if [ -f "$PID_FILE" ]; then
        local pid=$(cat "$PID_FILE")
        if kill -0 $pid 2>/dev/null; then
            echo "running (PID $pid)"
            return 0
        fi
    fi
    echo "stopped"
    return 1
}

# 主入口
case "$1" in
    start)
        if [ "$(nvram_get "xray_enable")" != "1" ]; then
            log "xray is disabled in NVRAM"
            exit 0
        fi
        check_binary || exit 1
        check_genconfig || exit 1
        generate_config || exit 1
        start_xray || exit 1
        apply_firewall
        apply_routing
        ;;
    stop)
        stop_xray
        remove_firewall
        remove_routing
        ;;
    restart)
        $0 stop
        sleep 2
        $0 start
        ;;
    reload)
        reload_xray
        ;;
    status)
        status_xray
        ;;
    *)
        echo "Usage: $0 {start|stop|restart|reload|status}"
        exit 1
        ;;
esac