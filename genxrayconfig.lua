local cjson = require "cjson"
local server_section = arg[1]
local proto = arg[2]
local local_port = arg[3] or "0"
local socks_port = arg[4] or "0"
local ssrindext = io.popen("dbus get ssconf_basic_json_" .. server_section)
local servertmp = ssrindext:read("*all")
local server = cjson.decode(servertmp)
local xray = {
	log = {
		-- error = "/var/ssrplus.log",
		loglevel = "warning"
	},
	-- 传入连接
	inbounds = {
		(local_port ~= "0") and {
			tag = "all-in",
			port = local_port,
			protocol = "dokodemo-door",
			settings = {
				network = proto,
				followRedirect = true
			},
			sniffing = {
				enabled = true,
				destOverride = { "http", "tls" }
			}
		} or nil,
	-- 开启 socks 代理
		(proto == "tcp" and socks_port ~= "0") and {
			protocol = "socks",
			port = socks_port,
			settings = {
				auth = "noauth",
				udp = true
			},
			sniffing = {
				enabled = true,
				destOverride = { "http", "tls" }
			}		
		} or nil,
	},
	-- 传出连接
	outbounds = {
		{
			protocol = "vless",
			settings = {
				vnext = {
					{
						address = server.server,
						port = tonumber(server.server_port),
						users = {
							{
								id = server.vmess_id,
								flow = server.flow,
								level = tonumber(server.alter_id),
								encryption = server.security
							}
						}
					}
				}
			},
			-- 底层传输配置
			streamSettings = {
				network = server.transport,
				security = (server.tls == '1') and "tls" or ((server.tls == '2') and "reality" or "none"),
				tlsSettings = (server.tls == '1') and 
				{
					show = false,
					allowInsecure = (server.insecure ~= "0") and true or false,
					fingerprint = server.tls_fp, serverName=server.tls_host
				} or nil,

				realitySettings = (server.tls == '2') and
				{
					show = false,
					fingerprint = server.tls_fp,
					serverName = server.tls_host,
					publicKey = server.public_key,
					shortId = server.short_id,
					spiderX = server.spiderx
				} or nil,

				grpcSettings = (server.transport == "grpc") and {
					serviceName = server.service_name,
					multiMode = (server.multi_mode ~= "gun") and true or false
				} or nil,

				kcpSettings = (server.transport == "kcp") and {
					mtu = tonumber(server.mtu),
					tti = tonumber(server.tti),
					uplinkCapacity = tonumber(server.uplink_capacity),
					downlinkCapacity = tonumber(server.downlink_capacity),
					congestion = (server.congestion == "1") and true or false,
					readBufferSize = tonumber(server.read_buffer_size),
					writeBufferSize = tonumber(server.write_buffer_size),
					header = {
						type = server.kcp_guise
					}
				} or nil,
				wsSettings = (server.transport == "ws") and (server.ws_path ~= nil or server.ws_host ~= nil) and {
					path = server.ws_path,
					headers = (server.ws_host ~= nil) and {
						Host = server.ws_host
					} or nil,
				} or nil,
				httpSettings = (server.transport == "h2") and (server.tls == '1') and {
					path = server.h2_path,
					host = server.h2_host
				} or ((server.transport == "h2") and (server.tls == '2') and {
					read_idle_timeout = 60,
					health_check_timeout = 20
				} or nil),
				quicSettings = (server.transport == "quic") and {
					security = server.quic_security,
					key = server.quic_key,
					header = {
						type = server.quic_guise
					}
				} or nil
			},
			tag = "proxy"
		},
		-- 额外传出连接
		{
			protocol = "freedom",
			tag = "direct"
		},
		{
			protocol =  "blackhole",
			tag = "block"
		}
	}
}

print(cjson.encode(xray))
