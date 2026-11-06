#!/usr/bin/env lua
-- xray 独立插件配置生成器
-- 目标版本: xray v26.10.31
-- 参考: v2rayN 配置结构 + xtls.github.io/config 官方文档

local cjson = require "cjson"
local nvram = require "nvram"

-- ============================================================
-- 工具函数
-- ============================================================

local function get(key, default)
    local v = nvram.get(key)
    return (v and v ~= "") and v or default
end

local function get_num(key, default)
    local v = get(key, default)
    return tonumber(v) or default
end

local function get_bool(key, default)
    local v = get(key, default)
    return v == "1" or v == "true"
end

local function split(str, sep)
    local t = {}
    for s in string.gmatch(str, "([^" .. sep .. "]+)") do
        table.insert(t, s)
    end
    return t
end

local function json_decode(str)
    if not str or str == "" then return nil end
    local ok, t = pcall(cjson.decode, str)
    return ok and t or nil
end

local function read_nodes()
    local nodes = {}
    local max_nodes = get_num("xray_node_max", 0)
    for i = 1, max_nodes do
        local key = "xray_node_json_" .. i
        local raw = nvram.get(key)
        if raw and raw ~= "" and raw ~= "deleting" then
            local node = json_decode(raw)
            if node then
                node._index = i
                nodes[i] = node
            end
        end
    end
    return nodes
end

local function get_current_node(nodes)
    local idx = get_num("xray_global_server", 0)
    if idx > 0 and nodes[idx] then
        return nodes[idx], idx
    end
    -- 找第一个可用节点
    for i, node in ipairs(nodes) do
        return node, i
    end
    return nil, 0
end

-- ============================================================
-- Inbound 构建
-- ============================================================

local function build_inbounds()
    local inbounds = {}
    local run_mode = get("xray_run_mode", "router")
    local local_port = get_num("xray_local_port", 1080)
    local socks_port = get_num("xray_socks_port", 1081)
    local http_port = get_num("xray_http_port", 0)
    local tun_enable = get_bool("xray_tun_enable", false)
    local dns_mode = get("xray_dns_mode", "local")

    -- 1. 透明代理 (dokodemo-door) - router/all 模式需要
    if run_mode ~= "gfw" and local_port > 0 then
        table.insert(inbounds, {
            tag = "tproxy-in",
            port = local_port,
            protocol = "dokodemo-door",
            settings = {
                network = "tcp,udp",
                followRedirect = true
            },
            sniffing = {
                enabled = true,
                destOverride = { "http", "tls", "quic" },
                routeOnly = false
            }
        })
    end

    -- 2. SOCKS5 入站
    if socks_port > 0 then
        table.insert(inbounds, {
            tag = "socks-in",
            port = socks_port,
            protocol = "socks",
            settings = {
                auth = "noauth",
                udp = true,
                ip = "0.0.0.0"
            },
            sniffing = {
                enabled = true,
                destOverride = { "http", "tls", "quic" }
            }
        })
    end

    -- 3. HTTP 入站
    if http_port > 0 then
        table.insert(inbounds, {
            tag = "http-in",
            port = http_port,
            protocol = "http",
            settings = {
                allowTransparent = false,
                userLevel = 0
            }
        })
    end

    -- 4. TUN 入站 (xray 26.10+ 新增，透明代理替代方案)
    if tun_enable then
        table.insert(inbounds, {
            tag = "tun-in",
            protocol = "tun",
            settings = {
                device = "tun0",
                address = { "172.19.0.1/30", "fd00::1/126" },
                mtu = 9000,
                route = true,
                strictRoute = false,
                inet4RouteAddress = { "0.0.0.0/1", "128.0.0.0/1" },
                inet6RouteAddress = { "::/1", "8000::/1" },
                autoRoute = true,
                fwmark = 255
            }
        })
    end

    return inbounds
end

-- ============================================================
-- Outbound 构建 (核心：从节点数据映射到 xray 标准配置)
-- ============================================================

local function build_outbound(node)
    if not node then
        return { protocol = "freedom", tag = "direct" }
    end

    local proto = node.protocol or "vless"
    local outbound = {
        tag = "proxy",
        protocol = proto,
        settings = {}
    }

    -- 通用 vnext 结构 (vless/vmess/trojan)
    if proto == "vless" or proto == "vmess" or proto == "trojan" then
        local vnext = {
            address = node.server or "",
            port = tonumber(node.server_port) or 443,
            users = {}
        }

        if proto == "vless" then
            vnext.users[1] = {
                id = node.uuid or node.vmess_id or "",
                flow = node.flow or "",
                encryption = node.encryption or "none",
                level = 0
            }
        elseif proto == "vmess" then
            vnext.users[1] = {
                id = node.uuid or node.vmess_id or "",
                alterId = tonumber(node.alter_id) or 0,
                security = node.security or "auto",
                level = 0
            }
        elseif proto == "trojan" then
            vnext.users[1] = {
                password = node.password or "",
                level = 0
            }
        end

        outbound.settings.vnext = { vnext }
    elseif proto == "shadowsocks" then
        outbound.settings.servers = {{
            address = node.server or "",
            port = tonumber(node.server_port) or 443,
            method = node.method or "aes-128-gcm",
            password = node.password or "",
            level = 0
        }}
    elseif proto == "socks" then
        outbound.settings.servers = {{
            address = node.server or "",
            port = tonumber(node.server_port) or 1080,
            users = (node.username and node.password) and {{
                user = node.username,
                pass = node.password
            }} or nil
        }}
    end

    -- streamSettings (传输层配置)
    local transport = node.transport or "tcp"
    local tls = node.tls or "0"  -- 0=none, 1=tls, 2=reality
    local stream = {
        network = transport,
        security = (tls == "1") and "tls" or ((tls == "2") and "reality" or "none")
    }

    -- TLS 设置
    if tls == "1" then
        stream.tlsSettings = {
            show = false,
            allowInsecure = get_bool("xray_tls_insecure", false),
            fingerprint = node.fingerprint or "chrome",
            serverName = node.tls_host or node.server or "",
            alpn = { "h2", "http/1.1" }
        }
    end

    -- Reality 设置 (xray 26.10+ 支持 shortIds 数组)
    if tls == "2" then
        local short_ids = {}
        if node.short_id and node.short_id ~= "" then
            for _, id in ipairs(split(node.short_id, ",")) do
                table.insert(short_ids, id)
            end
        end
        stream.realitySettings = {
            show = false,
            fingerprint = node.fingerprint or "chrome",
            serverName = node.tls_host or node.server or "",
            publicKey = node.public_key or "",
            shortIds = short_ids,
            spiderX = node.spider_x or "/"
        }
    end

    -- 各传输层特定配置
    if transport == "ws" or transport == "httpupgrade" then
        stream.wsSettings = {
            path = node.path or "/",
            headers = (node.host and node.host ~= "") and { Host = node.host } or nil
        }
    elseif transport == "grpc" then
        stream.grpcSettings = {
            serviceName = node.service_name or "",
            multiMode = node.multi_mode ~= "gun",
            idle_timeout = tonumber(node.grpc_idle_timeout) or 60,
            health_check_timeout = tonumber(node.grpc_health_check_timeout) or 20
        }
    elseif transport == "h2" then
        stream.httpSettings = {
            path = node.path or "/",
            host = node.host or "",
            read_idle_timeout = 60,
            health_check_timeout = 20
        }
    elseif transport == "xhttp" then
        stream.xhttpSettings = {
            host = node.host or "",
            path = node.path or "/",
            mode = node.xhttp_mode or "auto"
        }
    elseif transport == "kcp" then
        stream.kcpSettings = {
            mtu = tonumber(node.mtu) or 1350,
            tti = tonumber(node.tti) or 50,
            uplinkCapacity = tonumber(node.uplink_capacity) or 5,
            downlinkCapacity = tonumber(node.downlink_capacity) or 20,
            congestion = get_bool(node.congestion, false),
            readBufferSize = tonumber(node.read_buffer_size) or 2,
            writeBufferSize = tonumber(node.write_buffer_size) or 2,
            header = { type = node.kcp_guise or "none" }
        }
    elseif transport == "quic" then
        stream.quicSettings = {
            security = node.quic_security or "none",
            key = node.quic_key or "",
            header = { type = node.quic_guise or "none" }
        }
    elseif transport == "tcp" then
        if node.tcp_guise and node.tcp_guise ~= "none" then
            stream.tcpSettings = {
                header = { type = node.tcp_guise }
            }
            if node.tcp_guise == "http" then
                stream.tcpSettings.header.request = {
                    path = { node.http_path or "/" },
                    headers = {
                        Host = { node.http_host or "" }
                    }
                }
            end
        end
    end

    outbound.streamSettings = stream

    -- mux (多路复用)
    if node.mux and node.mux ~= "0" then
        outbound.mux = {
            enabled = true,
            concurrency = tonumber(node.mux_concurrency) or 8,
            xudpConcurrency = tonumber(node.mux_xudp_concurrency) or 16,
            xudpProxyUDP443 = node.flow == "xtls-rprx-vision-udp443"
        }
    end

    return outbound
end

local function build_outbounds(node)
    local outbounds = {}

    -- 主代理出站
    table.insert(outbounds, build_outbound(node))

    -- 直连出站
    table.insert(outbounds, {
        protocol = "freedom",
        tag = "direct",
        settings = {
            domainStrategy = "UseIPv4"
        }
    })

    -- 拦截出站
    table.insert(outbounds, {
        protocol = "blackhole",
        tag = "block"
    })

    -- DNS 出站 (用于 DNS over HTTPS/TLS)
    table.insert(outbounds, {
        protocol = "dns",
        tag = "dns-out"
    })

    return outbounds
end

-- ============================================================
-- Routing 构建
-- ============================================================

local function build_routing()
    local run_mode = get("xray_run_mode", "router")
    local geo_update = get_bool("xray_geo_update", true)

    local routing = {
        domainStrategy = "IPIfNonMatch",
        rules = {},
        balancers = {}
    }

    -- 基础规则：阻断局域网、保留地址
    table.insert(routing.rules, {
        type = "field",
        outboundTag = "direct",
        ip = { "geoip:private", "geoip:cn" }
    })

    table.insert(routing.rules, {
        type = "field",
        outboundTag = "direct",
        domain = { "geosite:cn", "geosite:private" }
    })

    -- 运行模式差异
    if run_mode == "gfw" then
        -- GFW 列表模式：默认直连，GFW 列表走代理
        table.insert(routing.rules, {
            type = "field",
            outboundTag = "proxy",
            domain = { "geosite:gfw" }
        })
        table.insert(routing.rules, {
            type = "field",
            outboundTag = "proxy",
            ip = { "geoip:gfw" }
        })
    elseif run_mode == "router" then
        -- 绕过大陆模式：默认走代理，大陆直连
        table.insert(routing.rules, 1, {
            type = "field",
            outboundTag = "proxy",
            network = "tcp,udp"
        })
    elseif run_mode == "all" then
        -- 全局模式：全部走代理
        table.insert(routing.rules, 1, {
            type = "field",
            outboundTag = "proxy",
            network = "tcp,udp"
        })
    elseif run_mode == "oversea" then
        -- 海外模式：大陆 IP 走代理，其余直连
        table.insert(routing.rules, 1, {
            type = "field",
            outboundTag = "proxy",
            ip = { "geoip:cn" }
        })
    end

    -- 兜底：未匹配走直连
    table.insert(routing.rules, {
        type = "field",
        outboundTag = "direct",
        network = "tcp,udp"
    })

    return routing
end

-- ============================================================
-- DNS 构建 (xray 26.10+ 完整 DNS 客户端)
-- ============================================================

local function build_dns()
    local dns_mode = get("xray_dns_mode", "local")
    local fakeip_range = get("xray_fakeip_range", "198.18.0.0/16")
    local local_dns = get("xray_local_dns", "223.5.5.5,114.114.114.114")
    local remote_dns = get("xray_remote_dns", "1.1.1.1,8.8.8.8")
    local doh_dns = get("xray_doh_dns", "https://1.1.1.1/dns-query,https://8.8.8.8/dns-query")

    local dns = {
        tag = "dns-in",
        hosts = {},
        servers = {},
        rules = {},
        fakeip = {
            enabled = dns_mode == "fakeip",
            inet4Range = fakeip_range,
            inet6Range = "fc00::/18"
        }
    }

    -- 本地 DNS 服务器
    for _, s in ipairs(split(local_dns, ",")) do
        table.insert(dns.servers, {
            address = s,
            port = 53,
            domains = { "geosite:cn", "geosite:private" },
            expectIPs = { "geoip:cn", "geoip:private" }
        })
    end

    -- 远程 DNS 服务器 (DoH/DoT)
    for _, s in ipairs(split(remote_dns, ",")) do
        table.insert(dns.servers, {
            address = s,
            port = 53,
            domains = { "geosite:gfw" },
            expectIPs = { "geoip:gfw" }
        })
    end

    -- DoH 服务器
    for _, s in ipairs(split(doh_dns, ",")) do
        table.insert(dns.servers, {
            address = s,
            port = 443,
            domains = { "geosite:gfw" },
            expectIPs = { "geoip:gfw" }
        })
    end

    -- 规则：按域名分流 DNS 查询
    table.insert(dns.rules, {
        type = "field",
        outboundTag = "dns-out",
        domain = { "geosite:gfw" }
    })
    table.insert(dns.rules, {
        type = "field",
        outboundTag = "direct",
        domain = { "geosite:cn", "geosite:private" }
    })

    return dns
end

-- ============================================================
-- Policy 构建
-- ============================================================

local function build_policy()
    local threads = get_num("xray_threads", 0)
    return {
        levels = {
            [0] = {
                handshake = 4,
                connIdle = 300,
                uplinkOnly = 2,
                downlinkOnly = 5,
                statsUserUplink = false,
                statsUserDownlink = false,
                bufferSize = threads > 0 and (threads * 2) or 0
            }
        },
        system = {
            statsInboundUplink = false,
            statsInboundDownlink = false,
            statsOutboundUplink = false,
            statsOutboundDownlink = false
        }
    }
end

-- ============================================================
// Transport 构建 (全局传输优化)
-- ============================================================

local function build_transport()
    return {
        tcpSettings = {
            acceptProxyProtocol = false,
            header = { type = "none" }
        },
        kcpSettings = {},
        wsSettings = {},
        httpSettings = {},
        quicSettings = {}
    }
end

-- ============================================================
-- 主流程
-- ============================================================

local function main()
    -- 1. 读取节点
    local nodes = read_nodes()
    local node, node_idx = get_current_node(nodes)

    -- 2. 构建完整配置
    local config = {
        log = {
            loglevel = get("xray_log_level", "warning"),
            access = "",
            error = ""
        },
        inbounds = build_inbounds(),
        outbounds = build_outbounds(node),
        routing = build_routing(),
        dns = build_dns(),
        policy = build_policy(),
        transport = build_transport(),
        stats = {},
        reverse = {},
        fakedns = {},
        browserForwarder = {},
        observatory = {}
    }

    -- 3. 输出 JSON
    print(cjson.encode(config))
end

main()