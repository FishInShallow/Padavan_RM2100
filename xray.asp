<!DOCTYPE html>
<html>
<head>
    <title><#Web_Title#> - Xray</title>
    <meta http-equiv="Content-Type" content="text/html; charset=utf-8">
    <meta http-equiv="Pragma" content="no-cache">
    <meta http-equiv="Expires" content="-1">
    <link rel="shortcut icon" href="images/favicon.ico">
    <link rel="icon" href="images/favicon.png">
    <link rel="stylesheet" type="text/css" href="/bootstrap/css/bootstrap.min.css">
    <link rel="stylesheet" type="text/css" href="/bootstrap/css/bootstrap-table.min.css">
    <link rel="stylesheet" type="text/css" href="/bootstrap/css/main.css">
    <link rel="stylesheet" type="text/css" href="/bootstrap/css/engage.itoggle.css">
    <script type="text/javascript" src="/jquery.js?random=<% uptime(); %>"></script>
    <script type="text/javascript" src="/bootstrap/js/bootstrap.min.js"></script>
    <script type="text/javascript" src="/bootstrap/js/bootstrap-table.min.js"></script>
    <script type="text/javascript" src="/bootstrap/js/bootstrap-table-zh-CN.min.js"></script>
    <script type="text/javascript" src="/bootstrap/js/engage.itoggle.min.js"></script>
    <script type="text/javascript" src="/state.js"></script>
    <script type="text/javascript" src="/general.js"></script>
    <script type="text/javascript" src="/itoggle.js"></script>
    <script type="text/javascript" src="/popup.js"></script>
    <script type="text/javascript" src="/help.js"></script>
    <script type="text/javascript" src="/validator.js"></script>
    <script>
        var node_global_max = 0;
        var editing_node_id = 0;
        var $j = jQuery.noConflict();

        <% xray_status(); %>

        $j(document).ready(function () {
            init_itoggle('xray_enable');
            init_itoggle('xray_tun_enable');
            init_itoggle('xray_proxy_local');
            init_itoggle('xray_geo_update');
            init_itoggle('xray_mux');
            init_itoggle('xray_sub_enable');

            $j("#tab_xray_cfg, #tab_xray_nodes, #tab_xray_routing, #tab_xray_dns, #tab_xray_log, #tab_xray_help").click(
                function () {
                    var newHash = $j(this).attr('href').toLowerCase();
                    showTab(newHash);
                    return false;
                });

            $j("#close_node").click(function () {
                $j("#node_settings").fadeOut(200);
            });

            $j("#btn_add_node").click(function () {
                initNodeParams();
                editing_node_id = 0;
                document.getElementById("node_title").innerHTML = "添加节点";
                $j("#node_settings").fadeIn(200);
            });

            $j("#btn_del_node").click(function () {
                del_nodes();
            });

            $j("#btn_update_sub").click(function () {
                update_subscribe();
            });

            $j("#btn_rest_sub").click(function () {
                clear_subscribe();
            });

            $j("#v2_tls").change(onTlsChange);
            $j("#v2_transport").change(onTransportChange);
            $j("#protocol").change(onProtocolChange);

            initial();
            showTab(getHash());
        });

        function initial() {
            show_banner(2);
            show_menu(13, 13, 0);
            show_footer();
            fill_xray_status(xray_status());
            document.form.xray_run_mode.value = '<% nvram_get_x("", "xray_run_mode"); %>';
            document.form.xray_threads.value = '<% nvram_get_x("", "xray_threads"); %>';
            document.form.xray_local_port.value = '<% nvram_get_x("", "xray_local_port"); %>';
            document.form.xray_socks_port.value = '<% nvram_get_x("", "xray_socks_port"); %>';
            document.form.xray_http_port.value = '<% nvram_get_x("", "xray_http_port"); %>';
            document.form.xray_dns_mode.value = '<% nvram_get_x("", "xray_dns_mode"); %>';
            document.form.xray_fakeip_range.value = '<% nvram_get_x("", "xray_fakeip_range"); %>';
            document.form.xray_local_dns.value = '<% nvram_get_x("", "xray_local_dns"); %>';
            document.form.xray_remote_dns.value = '<% nvram_get_x("", "xray_remote_dns"); %>';
            document.form.xray_doh_dns.value = '<% nvram_get_x("", "xray_doh_dns"); %>';
            document.form.xray_fingerprint.value = '<% nvram_get_x("", "xray_fingerprint"); %>';
            document.form.xray_mux_concurrency.value = '<% nvram_get_x("", "xray_mux_concurrency"); %>';
            document.form.xray_mux_xudp_concurrency.value = '<% nvram_get_x("", "xray_mux_xudp_concurrency"); %>';
            document.form.xray_log_level.value = '<% nvram_get_x("", "xray_log_level"); %>';
            document.form.xray_sub_url.value = '<% nvram_get_x("", "xray_sub_url"); %>';
            document.form.xray_sub_interval.value = '<% nvram_get_x("", "xray_sub_interval"); %>';
            document.form.xray_sub_keyword.value = '<% nvram_get_x("", "xray_sub_keyword"); %>';

            showNodeList();
        }

        function fill_xray_status(status_code) {
            var stext = "Unknown";
            if (status_code == 0) stext = "<#Stopped#>";
            else if (status_code == 1) stext = "<#Running#>";
            $("xray_status").innerHTML = '<span class="label label-' + (status_code != 0 ? 'success' : 'warning') + '">' + stext + '</span>';
        }

        var arrHashes = ["cfg", "nodes", "routing", "dns", "log", "help"];
        function showTab(curHash) {
            var obj = $('tab_xray_' + curHash.slice(1));
            if (obj == null || obj.style.display == 'none') curHash = '#cfg';
            for (var i = 0; i < arrHashes.length; i++) {
                if (curHash == ('#' + arrHashes[i])) {
                    $j('#tab_xray_' + arrHashes[i]).parents('li').addClass('active');
                    $j('#wnd_xray_' + arrHashes[i]).show();
                } else {
                    $j('#wnd_xray_' + arrHashes[i]).hide();
                    $j('#tab_xray_' + arrHashes[i]).parents('li').removeClass('active');
                }
            }
            window.location.hash = curHash;
        }

        function getHash() {
            var curHash = window.location.hash.toLowerCase();
            for (var i = 0; i < arrHashes.length; i++) {
                if (curHash == ('#' + arrHashes[i])) return curHash;
            }
            return '#cfg';
        }

        function onTlsChange() {
            const tlsVal = document.getElementById('v2_tls').value;
            showhide_div('row_tls_fp', tlsVal != '0');
            showhide_div('row_tls_host', tlsVal != '0');
            showhide_div('row_tls_insecure', tlsVal == '1');
            showhide_div('row_reality_pubkey', tlsVal == '2');
            showhide_div('row_reality_shortid', tlsVal == '2');
            showhide_div('row_reality_spiderx', tlsVal == '2');
        }

        function onTransportChange() {
            const transport = document.getElementById('v2_transport').value;
            showhide_div('row_ws_host', transport == 'ws' || transport == 'httpupgrade');
            showhide_div('row_ws_path', transport == 'ws' || transport == 'httpupgrade');
            showhide_div('row_grpc_service', transport == 'grpc');
            showhide_div('row_grpc_mode', transport == 'grpc');
            showhide_div('row_grpc_idle', transport == 'grpc');
            showhide_div('row_grpc_health', transport == 'grpc');
            showhide_div('row_h2_host', transport == 'h2');
            showhide_div('row_h2_path', transport == 'h2');
            showhide_div('row_xhttp_host', transport == 'xhttp');
            showhide_div('row_xhttp_path', transport == 'xhttp');
            showhide_div('row_xhttp_mode', transport == 'xhttp');
            showhide_div('row_kcp_mtu', transport == 'kcp');
            showhide_div('row_kcp_tti', transport == 'kcp');
            showhide_div('row_kcp_uplink', transport == 'kcp');
            showhide_div('row_kcp_downlink', transport == 'kcp');
            showhide_div('row_kcp_congestion', transport == 'kcp');
            showhide_div('row_kcp_readbuf', transport == 'kcp');
            showhide_div('row_kcp_writebuf', transport == 'kcp');
            showhide_div('row_kcp_header', transport == 'kcp');
            showhide_div('row_tcp_header', transport == 'tcp');
            showhide_div('row_tcp_host', transport == 'tcp');
            showhide_div('row_tcp_path', transport == 'tcp');
            showhide_div('row_quic_security', transport == 'quic');
            showhide_div('row_quic_key', transport == 'quic');
            showhide_div('row_quic_header', transport == 'quic');
            showhide_div('row_flow', transport == 'tcp' || transport == 'ws' || transport == 'grpc' || transport == 'h2' || transport == 'xhttp');
        }

        function onProtocolChange() {
            const proto = document.getElementById('protocol').value;
            showhide_div('row_uuid', proto == 'vless' || proto == 'vmess');
            showhide_div('row_alterid', proto == 'vmess');
            showhide_div('row_security', proto == 'vmess');
            showhide_div('row_password', proto == 'trojan' || proto == 'shadowsocks' || proto == 'socks');
            showhide_div('row_ss_method', proto == 'shadowsocks');
            showhide_div('row_flow', proto == 'vless');
            showhide_div('row_encryption', proto == 'vless');
        }

        function applyRule() {
            if (validForm()) {
                showLoading();
                document.form.action_mode.value = " Restart ";
                document.form.current_page.value = "Xray.asp";
                document.form.next_page.value = "";
                document.form.submit();
            }
        }

        function validForm() {
            return true;
        }

        function submitAction(v) {
            showLoading();
            $j.ajax({
                type: "POST",
                url: "/Xray_action.asp",
                data: { connect_action: v },
                dataType: "json",
                success: function (response) {
                    alert("操作成功");
                },
                complete: function(xhr, ts) {
                    hideLoading();
                    setTimeout(function() { location.reload(); }, 1000);
                }
            });
        }

        // ========== 节点管理 ==========
        function showNodeList() {
            $j('#node_table').bootstrapTable({
                striped: true,
                pageNumber: 1,
                pagination: true,
                sortable: true,
                sortName: 'index',
                sortOrder: "asc",
                sidePagination: 'client',
                pageSize: 15,
                pageList: [15, 25, 50],
                uniqueId: "index",
                columns: [{
                    field: 'delete',
                    title: '删除',
                    checkbox: true,
                    width: '30px'
                }, {
                    field: 'index',
                    title: '序号',
                    width: '50px',
                    align: 'center',
                    sortable: true
                }, {
                    field: 'alias',
                    title: '别名',
                    align: 'center',
                    valign: 'middle',
                    width: '200px',
                    formatter: function(value, row) {
                        return '<span title="' + value + '">' + value + '</span>';
                    }
                }, {
                    field: 'protocol',
                    title: '协议',
                    align: 'center',
                    width: '80px'
                }, {
                    field: 'server',
                    title: '服务器',
                    align: 'center',
                    width: '150px',
                    formatter: function(value, row) {
                        return value + ':' + row.port;
                    }
                }, {
                    field: 'transport',
                    title: '传输',
                    align: 'center',
                    width: '80px'
                }, {
                    field: 'tls',
                    title: 'TLS',
                    align: 'center',
                    width: '80px',
                    formatter: function(value) {
                        if (value == '0') return '无';
                        if (value == '1') return 'TLS';
                        if (value == '2') return 'Reality';
                        return value;
                    }
                }, {
                    field: 'ping',
                    title: '延迟',
                    align: 'center',
                    width: '80px',
                    formatter: function(value) {
                        return value ? value + 'ms' : '-';
                    }
                }, {
                    field: 'operate',
                    title: '操作',
                    width: '180px',
                    align: 'center',
                    events: window.operateEvents,
                    formatter: actionFormatter
                }]
            });
            loadNodes();
        }

        function loadNodes() {
            var nodes = [];
            var max_nodes = parseInt('<% nvram_get_x("", "xray_node_max"); %>') || 0;
            for (var i = 1; i <= max_nodes; i++) {
                var key = "xray_node_json_" + i;
                var raw = '<% nvram_get_x("xray_node_json_" + i, ""); %>';
                if (raw && raw != '' && raw != 'deleting') {
                    try {
                        var node = JSON.parse(raw);
                        node.index = i;
                        node.ping = node.ping || '-';
                        nodes.push(node);
                    } catch(e) {}
                }
            }
            $j('#node_table').bootstrapTable('load', nodes);

            // 更新主节点下拉框
            var global_server = parseInt('<% nvram_get_x("", "xray_global_server"); %>') || 0;
            var select = document.getElementById('xray_global_server');
            select.options.length = 1;
            for (var i = 0; i < nodes.length; i++) {
                select.options.add(new Option(nodes[i].alias, nodes[i].index));
            }
            if (global_server > 0) select.value = global_server;
        }

        function initNodeParams() {
            document.getElementById('protocol').value = 'vless';
            document.getElementById('alias').value = '';
            document.getElementById('server').value = '';
            document.getElementById('port').value = '443';
            document.getElementById('uuid').value = '';
            document.getElementById('alter_id').value = '0';
            document.getElementById('security').value = 'auto';
            document.getElementById('password').value = '';
            document.getElementById('ss_method').value = 'aes-128-gcm';
            document.getElementById('encryption').value = 'none';
            document.getElementById('flow').value = '';
            document.getElementById('v2_transport').value = 'tcp';
            document.getElementById('v2_tls').value = '0';
            document.getElementById('v2_tls_fp').value = 'chrome';
            document.getElementById('v2_tls_host').value = '';
            document.getElementById('v2_tls_insecure').value = '0';
            document.getElementById('v2_tls_insecure').checked = false;
            document.getElementById('public_key').value = '';
            document.getElementById('short_id').value = '';
            document.getElementById('spider_x').value = '/';
            document.getElementById('ws_host').value = '';
            document.getElementById('ws_path').value = '/';
            document.getElementById('grpc_service').value = '';
            document.getElementById('grpc_mode').value = 'gun';
            document.getElementById('grpc_idle').value = '60';
            document.getElementById('grpc_health').value = '20';
            document.getElementById('h2_host').value = '';
            document.getElementById('h2_path').value = '/';
            document.getElementById('xhttp_host').value = '';
            document.getElementById('xhttp_path').value = '/';
            document.getElementById('xhttp_mode').value = 'auto';
            document.getElementById('kcp_mtu').value = '1350';
            document.getElementById('kcp_tti').value = '50';
            document.getElementById('kcp_uplink').value = '5';
            document.getElementById('kcp_downlink').value = '20';
            document.getElementById('kcp_congestion').value = '0';
            document.getElementById('kcp_readbuf').value = '2';
            document.getElementById('kcp_writebuf').value = '2';
            document.getElementById('kcp_header').value = 'none';
            document.getElementById('tcp_header').value = 'none';
            document.getElementById('tcp_host').value = '';
            document.getElementById('tcp_path').value = '/';
            document.getElementById('quic_security').value = 'none';
            document.getElementById('quic_key').value = '';
            document.getElementById('quic_header').value = 'none';
            document.getElementById('mux').value = '0';
            document.getElementById('mux').checked = false;
            document.getElementById('mux_concurrency').value = '8';
            document.getElementById('mux_xudp_concurrency').value = '16';

            onProtocolChange();
            onTransportChange();
            onTlsChange();
        }

        function showNodeEditor(node) {
            function getProp(obj, prop, def) {
                return obj && obj.hasOwnProperty(prop) ? obj[prop] : def;
            }

            initNodeParams();

            document.getElementById('protocol').value = getProp(node, 'protocol', 'vless');
            document.getElementById('alias').value = getProp(node, 'alias', '');
            document.getElementById('server').value = getProp(node, 'server', '');
            document.getElementById('port').value = getProp(node, 'port', '443');
            document.getElementById('uuid').value = getProp(node, 'uuid', getProp(node, 'vmess_id', ''));
            document.getElementById('alter_id').value = getProp(node, 'alter_id', '0');
            document.getElementById('security').value = getProp(node, 'security', 'auto');
            document.getElementById('password').value = getProp(node, 'password', '');
            document.getElementById('ss_method').value = getProp(node, 'method', 'aes-128-gcm');
            document.getElementById('encryption').value = getProp(node, 'encryption', 'none');
            document.getElementById('flow').value = getProp(node, 'flow', '');
            document.getElementById('v2_transport').value = getProp(node, 'transport', 'tcp');
            document.getElementById('v2_tls').value = getProp(node, 'tls', '0');
            document.getElementById('v2_tls_fp').value = getProp(node, 'fingerprint', 'chrome');
            document.getElementById('v2_tls_host').value = getProp(node, 'tls_host', '');
            document.getElementById('v2_tls_insecure').value = getProp(node, 'insecure', '0');
            document.getElementById('v2_tls_insecure').checked = getProp(node, 'insecure', '0') == '1';
            document.getElementById('public_key').value = getProp(node, 'public_key', '');
            document.getElementById('short_id').value = getProp(node, 'short_id', '');
            document.getElementById('spider_x').value = getProp(node, 'spider_x', '/');
            document.getElementById('ws_host').value = getProp(node, 'ws_host', '');
            document.getElementById('ws_path').value = getProp(node, 'ws_path', '/');
            document.getElementById('grpc_service').value = getProp(node, 'service_name', '');
            document.getElementById('grpc_mode').value = getProp(node, 'multi_mode', 'gun');
            document.getElementById('grpc_idle').value = getProp(node, 'grpc_idle_timeout', '60');
            document.getElementById('grpc_health').value = getProp(node, 'grpc_health_check_timeout', '20');
            document.getElementById('h2_host').value = getProp(node, 'h2_host', '');
            document.getElementById('h2_path').value = getProp(node, 'h2_path', '/');
            document.getElementById('xhttp_host').value = getProp(node, 'xhttp_host', '');
            document.getElementById('xhttp_path').value = getProp(node, 'xhttp_path', '/');
            document.getElementById('xhttp_mode').value = getProp(node, 'xhttp_mode', 'auto');
            document.getElementById('kcp_mtu').value = getProp(node, 'mtu', '1350');
            document.getElementById('kcp_tti').value = getProp(node, 'tti', '50');
            document.getElementById('kcp_uplink').value = getProp(node, 'uplink_capacity', '5');
            document.getElementById('kcp_downlink').value = getProp(node, 'downlink_capacity', '20');
            document.getElementById('kcp_congestion').value = getProp(node, 'congestion', '0');
            document.getElementById('kcp_readbuf').value = getProp(node, 'read_buffer_size', '2');
            document.getElementById('kcp_writebuf').value = getProp(node, 'write_buffer_size', '2');
            document.getElementById('kcp_header').value = getProp(node, 'kcp_guise', 'none');
            document.getElementById('tcp_header').value = getProp(node, 'tcp_guise', 'none');
            document.getElementById('tcp_host').value = getProp(node, 'http_host', '');
            document.getElementById('tcp_path').value = getProp(node, 'http_path', '/');
            document.getElementById('quic_security').value = getProp(node, 'quic_security', 'none');
            document.getElementById('quic_key').value = getProp(node, 'quic_key', '');
            document.getElementById('quic_header').value = getProp(node, 'quic_guise', 'none');
            document.getElementById('mux').value = getProp(node, 'mux', '0');
            document.getElementById('mux').checked = getProp(node, 'mux', '0') == '1';
            document.getElementById('mux_concurrency').value = getProp(node, 'mux_concurrency', '8');
            document.getElementById('mux_xudp_concurrency').value = getProp(node, 'mux_xudp_concurrency', '16');

            onProtocolChange();
            onTransportChange();
            onTlsChange();

            $j("#node_settings").fadeIn(200);
        }

        function saveNode() {
            var proto = document.getElementById('protocol').value;
            var node = {
                protocol: proto,
                alias: document.getElementById('alias').value,
                server: document.getElementById('server').value,
                port: document.getElementById('port').value,
            };

            if (proto == 'vless' || proto == 'vmess') {
                node.uuid = document.getElementById('uuid').value;
            }
            if (proto == 'vmess') {
                node.alter_id = document.getElementById('alter_id').value;
                node.security = document.getElementById('security').value;
            }
            if (proto == 'trojan' || proto == 'shadowsocks' || proto == 'socks') {
                node.password = document.getElementById('password').value;
            }
            if (proto == 'shadowsocks') {
                node.method = document.getElementById('ss_method').value;
            }
            if (proto == 'vless') {
                node.encryption = document.getElementById('encryption').value;
                node.flow = document.getElementById('flow').value;
            }

            node.transport = document.getElementById('v2_transport').value;
            node.tls = document.getElementById('v2_tls').value;
            node.fingerprint = document.getElementById('v2_tls_fp').value;
            node.tls_host = document.getElementById('v2_tls_host').value;
            node.insecure = document.getElementById('v2_tls_insecure').value;

            if (node.tls == '2') {
                node.public_key = document.getElementById('public_key').value;
                node.short_id = document.getElementById('short_id').value;
                node.spider_x = document.getElementById('spider_x').value;
            }

            var transport = node.transport;
            if (transport == 'ws' || transport == 'httpupgrade') {
                node.ws_host = document.getElementById('ws_host').value;
                node.ws_path = document.getElementById('ws_path').value;
            } else if (transport == 'grpc') {
                node.service_name = document.getElementById('grpc_service').value;
                node.multi_mode = document.getElementById('grpc_mode').value;
                node.grpc_idle_timeout = document.getElementById('grpc_idle').value;
                node.grpc_health_check_timeout = document.getElementById('grpc_health').value;
            } else if (transport == 'h2') {
                node.h2_host = document.getElementById('h2_host').value;
                node.h2_path = document.getElementById('h2_path').value;
            } else if (transport == 'xhttp') {
                node.xhttp_host = document.getElementById('xhttp_host').value;
                node.xhttp_path = document.getElementById('xhttp_path').value;
                node.xhttp_mode = document.getElementById('xhttp_mode').value;
            } else if (transport == 'kcp') {
                node.mtu = document.getElementById('kcp_mtu').value;
                node.tti = document.getElementById('kcp_tti').value;
                node.uplink_capacity = document.getElementById('kcp_uplink').value;
                node.downlink_capacity = document.getElementById('kcp_downlink').value;
                node.congestion = document.getElementById('kcp_congestion').value;
                node.read_buffer_size = document.getElementById('kcp_readbuf').value;
                node.write_buffer_size = document.getElementById('kcp_writebuf').value;
                node.kcp_guise = document.getElementById('kcp_header').value;
            } else if (transport == 'tcp') {
                node.tcp_guise = document.getElementById('tcp_header').value;
                node.http_host = document.getElementById('tcp_host').value;
                node.http_path = document.getElementById('tcp_path').value;
            } else if (transport == 'quic') {
                node.quic_security = document.getElementById('quic_security').value;
                node.quic_key = document.getElementById('quic_key').value;
                node.quic_guise = document.getElementById('quic_header').value;
            }

            node.mux = document.getElementById('mux').value;
            node.mux_concurrency = document.getElementById('mux_concurrency').value;
            node.mux_xudp_concurrency = document.getElementById('mux_xudp_concurrency').value;

            var post_dbus = JSON.stringify(node);
            var ids;
            if (editing_node_id == 0) {
                node_global_max += 1;
                ids = node_global_max;
            } else {
                ids = editing_node_id;
            }

            var ns = {};
            ns["xray_node_json_" + ids] = post_dbus;
            ns["xray_node_max"] = node_global_max;
            push_data(ns);
            $j("#node_settings").fadeOut(200);
        }

        function push_data(obj) {
            $j.ajax({
                type: "POST",
                url: '/applydb.cgi?p=xray',
                contentType: "application/x-www-form-urlencoded",
                dataType: 'text',
                data: $j.param(obj),
                success: function (response) {
                    loadNodes();
                }
            });
        }

        function del_nodes() {
            var rows = $j("#node_table").bootstrapTable('getSelections');
            if (rows.length == 0) {
                alert("请选择要删除的节点");
                return;
            }
            if (!confirm('确认删除选中的 ' + rows.length + ' 个节点吗？')) return;

            var ns = {};
            for (var key in rows) {
                ns["xray_node_json_" + rows[key].index] = "deleting";
            }
            push_data(ns);
        }

        function actionFormatter(value, row, index) {
            return [
                '<a class="edit_node" href="javascript:void(0)" title="编辑">编辑</a>',
                '<a class="copy_node" href="javascript:void(0)" title="复制">复制</a>',
                '<a class="del_node" href="javascript:void(0)" title="删除">删除</a>',
                '<a class="ping_node" href="javascript:void(0)" title="测速">测速</a>'
            ].join(' | ');
        }

        window.operateEvents = {
            'click .edit_node': function (e, value, row, index) {
                editing_node_id = row.index;
                document.getElementById("node_title").innerHTML = "编辑节点";
                showNodeEditor(row);
            },
            'click .copy_node': function (e, value, row, index) {
                editing_node_id = 0;
                document.getElementById("node_title").innerHTML = "复制节点";
                showNodeEditor(row);
            },
            'click .del_node': function (e, value, row, index) {
                if (confirm('确认删除 ' + row.alias + ' 吗？')) {
                    var ns = {};
                    ns["xray_node_json_" + row.index] = "deleting";
                    push_data(ns);
                }
            },
            'click .ping_node': function (e, value, row, index) {
                ping_node(row.index);
            }
        };

        function ping_node(id) {
            var ns = {};
            ns[id] = "ping";
            $j.ajax({
                url: "/applydb.cgi?useping=1&p=xray",
                type: 'POST',
                contentType: "application/x-www-form-urlencoded",
                dataType: 'text',
                data: $j.param(ns),
                success: function (response) {
                    setTimeout("loadNodes();", 2000);
                }
            });
        }

        // ========== 订阅功能 ==========
        function update_subscribe() {
            var url = document.getElementById('xray_sub_url').value;
            if (!url) {
                alert("请先填写订阅地址");
                return;
            }
            showLoading();
            document.getElementById("btn_update_sub").value = "正在更新订阅...";
            $j.ajax({
                url: "/applydb.cgi?usedlink=1&p=xray",
                type: 'POST',
                contentType: "application/x-www-form-urlencoded",
                dataType: 'text',
                data: $j.param({ sub_url: url }),
                success: function (response) {
                    setTimeout(function() {
                        document.getElementById("btn_update_sub").value = "更新订阅";
                        loadNodes();
                        hideLoading();
                    }, 1000);
                }
            });
        }

        function clear_subscribe() {
            if (!confirm('确认清空所有订阅节点吗？')) return;
            $j.ajax({
                url: "/applydb.cgi?usddlink=1&p=xray",
                type: 'POST',
                success: function() {
                    node_global_max = 0;
                    loadNodes();
                }
            });
        }

        // ========== 导入链接 ==========
        function import_url() {
            var url = prompt("粘贴配置链接 (vless:// | vmess:// | trojan:// | ss:// | socks:// | reality://)", "");
            if (!url) return;

            initNodeParams();
            var type = url.split('://')[0];

            try {
                if (type == 'vless') {
                    parse_vless(url);
                } else if (type == 'vmess') {
                    parse_vmess(url);
                } else if (type == 'trojan') {
                    parse_trojan(url);
                } else if (type == 'ss') {
                    parse_ss(url);
                } else if (type == 'socks') {
                    parse_socks(url);
                } else if (type == 'reality') {
                    parse_reality(url);
                }
                editing_node_id = 0;
                document.getElementById("node_title").innerHTML = "导入节点";
                $j("#node_settings").fadeIn(200);
            } catch(e) {
                alert("解析失败: " + e.message);
            }
        }

        function b64dec(str) {
            str = str.replace(/-/g, '+').replace(/_/g, '/');
            while (str.length % 4) str += '=';
            return atob(str);
        }

        function b64dec_utf8(str) {
            return decodeURIComponent(escape(b64dec(str)));
        }

        function parse_vless(url) {
            var main = url.split('://')[1];
            var remark_idx = main.indexOf('#');
            var remark = remark_idx > 0 ? decodeURIComponent(main.substr(remark_idx + 1)) : '';
            if (remark_idx > 0) main = main.substr(0, remark_idx);

            var at_idx = main.indexOf('@');
            var uuid = main.substr(0, at_idx);
            var rest = main.substr(at_idx + 1);
            var q_idx = rest.indexOf('?');
            var server_port = q_idx > 0 ? rest.substr(0, q_idx) : rest;
            var params = q_idx > 0 ? rest.substr(q_idx + 1) : '';

            var sp = server_port.split(':');
            var server = sp[0];
            var port = sp[1] || '443';

            var p = {};
            params.split('&').forEach(function(kv) {
                var eq = kv.indexOf('=');
                if (eq > 0) p[decodeURIComponent(kv.substr(0, eq))] = decodeURIComponent(kv.substr(eq + 1));
            });

            document.getElementById('protocol').value = 'vless';
            document.getElementById('alias').value = remark;
            document.getElementById('server').value = server;
            document.getElementById('port').value = port;
            document.getElementById('uuid').value = uuid;
            document.getElementById('encryption').value = p.encryption || 'none';
            document.getElementById('flow').value = p.flow || '';
            document.getElementById('v2_transport').value = p.type == 'http' ? 'h2' : (p.type || 'tcp');
            document.getElementById('v2_tls').value = p.security == 'reality' ? '2' : (p.security == 'tls' ? '1' : '0');
            document.getElementById('v2_tls_fp').value = p.fp || 'chrome';
            document.getElementById('v2_tls_host').value = p.sni || server;
            document.getElementById('public_key').value = p.pbk || '';
            document.getElementById('short_id').value = p.sid || '';
            document.getElementById('spider_x').value = p.spx || '/';

            if (p.type == 'ws') {
                document.getElementById('ws_host').value = p.host || '';
                document.getElementById('ws_path').value = p.path || '/';
            } else if (p.type == 'grpc') {
                document.getElementById('grpc_service').value = p.serviceName || '';
                document.getElementById('grpc_mode').value = p.mode || 'gun';
            } else if (p.type == 'h2') {
                document.getElementById('h2_host').value = p.host || '';
                document.getElementById('h2_path').value = p.path || '/';
            }

            onProtocolChange();
            onTransportChange();
            onTlsChange();
        }

        function parse_vmess(url) {
            var json_str = b64dec_utf8(url.split('://')[1]);
            var cfg = JSON.parse(json_str);

            document.getElementById('protocol').value = 'vmess';
            document.getElementById('alias').value = cfg.ps || '';
            document.getElementById('server').value = cfg.add || '';
            document.getElementById('port').value = cfg.port || '443';
            document.getElementById('uuid').value = cfg.id || '';
            document.getElementById('alter_id').value = cfg.aid || '0';
            document.getElementById('security').value = cfg.scy || 'auto';
            document.getElementById('v2_transport').value = cfg.net || 'tcp';
            document.getElementById('v2_tls').value = cfg.tls == 'tls' ? '1' : '0';
            document.getElementById('v2_tls_host').value = cfg.sni || cfg.host || '';
            document.getElementById('v2_tls_fp').value = 'chrome';

            if (cfg.net == 'ws') {
                document.getElementById('ws_host').value = cfg.host || '';
                document.getElementById('ws_path').value = cfg.path || '/';
            } else if (cfg.net == 'tcp' && cfg.type == 'http') {
                document.getElementById('v2_transport').value = 'h2';
                document.getElementById('h2_host').value = cfg.host || '';
                document.getElementById('h2_path').value = cfg.path || '/';
            } else if (cfg.net == 'tcp') {
                document.getElementById('tcp_header').value = cfg.type || 'none';
                document.getElementById('tcp_host').value = cfg.host || '';
                document.getElementById('tcp_path').value = cfg.path || '/';
            } else if (cfg.net == 'kcp') {
                document.getElementById('kcp_header').value = cfg.type || 'none';
            }

            onProtocolChange();
            onTransportChange();
            onTlsChange();
        }

        function parse_trojan(url) {
            var main = url.split('://')[1];
            var remark_idx = main.indexOf('#');
            var remark = remark_idx > 0 ? decodeURIComponent(main.substr(remark_idx + 1)) : '';
            if (remark_idx > 0) main = main.substr(0, remark_idx);

            var at_idx = main.indexOf('@');
            var password = main.substr(0, at_idx);
            var rest = main.substr(at_idx + 1);
            var q_idx = rest.indexOf('?');
            var server_port = q_idx > 0 ? rest.substr(0, q_idx) : rest;
            var params = q_idx > 0 ? rest.substr(q_idx + 1) : '';

            var sp = server_port.split(':');
            var server = sp[0];
            var port = sp[1] || '443';

            var p = {};
            params.split('&').forEach(function(kv) {
                var eq = kv.indexOf('=');
                if (eq > 0) p[decodeURIComponent(kv.substr(0, eq))] = decodeURIComponent(kv.substr(eq + 1));
            });

            document.getElementById('protocol').value = 'trojan';
            document.getElementById('alias').value = remark;
            document.getElementById('server').value = server;
            document.getElementById('port').value = port;
            document.getElementById('password').value = password;
            document.getElementById('v2_tls').value = '1';
            document.getElementById('v2_tls_host').value = p.sni || server;
            document.getElementById('v2_tls_fp').value = 'chrome';
            document.getElementById('v2_transport').value = 'tcp';

            onProtocolChange();
            onTransportChange();
            onTlsChange();
        }

        function parse_ss(url) {
            var main = url.split('://')[1];
            var remark_idx = main.indexOf('#');
            var remark = remark_idx > 0 ? decodeURIComponent(main.substr(remark_idx + 1)) : '';
            if (remark_idx > 0) main = main.substr(0, remark_idx);

            var at_idx = main.indexOf('@');
            var userinfo = b64dec(main.substr(0, at_idx));
            var server_port = main.substr(at_idx + 1);

            var ui = userinfo.split(':');
            var method = ui[0];
            var password = ui.slice(1).join(':');

            var sp = server_port.split(':');
            var server = sp[0];
            var port = sp[1] || '443';

            document.getElementById('protocol').value = 'shadowsocks';
            document.getElementById('alias').value = remark;
            document.getElementById('server').value = server;
            document.getElementById('port').value = port;
            document.getElementById('ss_method').value = method;
            document.getElementById('password').value = password;

            onProtocolChange();
        }

        function parse_socks(url) {
            var main = url.split('://')[1];
            var remark_idx = main.indexOf('#');
            var remark = remark_idx > 0 ? decodeURIComponent(main.substr(remark_idx + 1)) : '';
            if (remark_idx > 0) main = main.substr(0, remark_idx);

            var at_idx = main.indexOf('@');
            var auth = at_idx > 0 ? main.substr(0, at_idx) : '';
            var server_port = at_idx > 0 ? main.substr(at_idx + 1) : main;

            var sp = server_port.split(':');
            var server = sp[0];
            var port = sp[1] || '1080';

            var username = '', password = '';
            if (auth) {
                var a = b64dec(auth).split(':');
                username = a[0];
                password = a[1] || '';
            }

            document.getElementById('protocol').value = 'socks';
            document.getElementById('alias').value = remark;
            document.getElementById('server').value = server;
            document.getElementById('port').value = port;
            document.getElementById('password').value = password;

            onProtocolChange();
        }

        function parse_reality(url) {
            // reality:// 非标准，按 vless 处理
            parse_vless(url.replace('reality://', 'vless://'));
        }

        // ========== 导出配置 ==========
        function export_config() {
            var nodes = [];
            var max_nodes = parseInt('<% nvram_get_x("", "xray_node_max"); %>') || 0;
            for (var i = 1; i <= max_nodes; i++) {
                var raw = '<% nvram_get_x("xray_node_json_" + i, ""); %>';
                if (raw && raw != '' && raw != 'deleting') {
                    try {
                        nodes.push(JSON.parse(raw));
                    } catch(e) {}
                }
            }

            var config = {
                inbounds: [],
                outbounds: nodes.map(function(n) { return n; }),
                routing: { rules: [] }
            };

            var blob = new Blob([JSON.stringify(config, null, 2)], {type: 'application/json'});
            var url = URL.createObjectURL(blob);
            var a = document.createElement('a');
            a.href = url;
            a.download = 'xray_config_' + Date.now() + '.json';
            a.click();
            URL.revokeObjectURL(url);
        }

        // ========== 重启/测速 ==========
        function restart_xray() {
            submitAction('Restart');
        }

        function test_all_nodes() {
            if (!confirm('测速所有节点可能需要较长时间，继续吗？')) return;
            $j.ajax({
                url: "/applydb.cgi?useping=1&p=xray",
                type: 'POST',
                data: { allping: 1 },
                success: function() {
                    setTimeout("loadNodes();", 5000);
                }
            });
        }
    </script>
</head>

<body onload="initial();" onunLoad="return unload_body();">
    <div class="wrapper">
        <div class="container-fluid" style="padding-right: 0px">
            <div class="row-fluid">
                <div class="span3">
                    <center><div id="logo"></div></center>
                </div>
                <div class="span9">
                    <div id="TopBanner"></div>
                </div>
            </div>
        </div>
        <div id="Loading" class="popup_bg"></div>
        <iframe name="hidden_frame" id="hidden_frame" src="" width="0" height="0" frameborder="0"></iframe>
        <form method="post" name="form" id="ruleForm" action="/start_apply.htm" target="hidden_frame">
            <input type="hidden" name="current_page" value="Xray.asp">
            <input type="hidden" name="next_page" value="">
            <input type="hidden" name="next_host" value="">
            <input type="hidden" name="sid_list" value="XrayList;">
            <input type="hidden" name="group_id" value="XrayList">
            <input type="hidden" name="action_mode" value="">
            <input type="hidden" name="action_script" value="">

            <div class="container-fluid">
                <div class="row-fluid">
                    <div class="span3">
                        <div class="well sidebar-nav side_nav" style="padding: 0px;">
                            <ul id="mainMenu" class="clearfix"></ul>
                            <ul class="clearfix">
                                <li><div id="subMenu" class="accordion"></div></li>
                            </ul>
                        </div>
                    </div>
                    <div class="span9">
                        <div class="row-fluid">
                            <div class="span12">
                                <div class="box well grad_colour_dark_blue">
                                    <h2 class="box_head round_top">Xray 代理客户端</h2>
                                    <div class="round_bottom">
                                        <div>
                                            <ul class="nav nav-tabs" style="margin-bottom: 10px;">
                                                <li class="active"><a id="tab_xray_cfg" href="#cfg">客户端</a></li>
                                                <li><a id="tab_xray_nodes" href="#nodes">节点管理</a></li>
                                                <li><a id="tab_xray_routing" href="#routing">路由规则</a></li>
                                                <li><a id="tab_xray_dns" href="#dns">DNS设置</a></li>
                                                <li><a id="tab_xray_log" href="#log">运行日志</a></li>
                                                <li><a id="tab_xray_help" href="#help">帮助文档</a></li>
                                            </ul>
                                        </div>

                                        <!-- ===== 客户端标签页 ===== -->
                                        <div id="wnd_xray_cfg">
                                            <div class="alert alert-info" style="margin: 10px;">
                                                Xray 独立插件 - 支持 VLESS/VMess/Trojan/Shadowsocks/SOCKS
                                                <br>版本: v26.10.31 | 支持 Reality, xHTTP, gRPC, TUN 等新特性
                                            </div>

                                            <table width="100%" cellpadding="4" cellspacing="0" class="table">
                                                <tr>
                                                    <th>运行状态</th>
                                                    <td id="xray_status"></td>
                                                </tr>
                                                <tr>
                                                    <th>控制</th>
                                                    <td>
                                                        <input type="button" class="btn btn-info" value="重启 Xray" onclick="restart_xray();">
                                                        <input type="button" class="btn btn-warning" value="测速所有节点" onclick="test_all_nodes();">
                                                        <input type="button" class="btn btn-success" value="导出配置" onclick="export_config();">
                                                    </td>
                                                </tr>
                                            </table>

                                            <table class="table">
                                                <tr>
                                                    <th width="30%">总开关</th>
                                                    <td>
                                                        <div class="main_itoggle">
                                                            <div id="xray_enable_on_of">
                                                                <input type="checkbox" id="xray_enable_fake"
                                                                    <% nvram_match_x("", "xray_enable", "1", "value=1 checked"); %><% nvram_match_x("", "xray_enable", "0", "value=0"); %>>
                                                            </div>
                                                        </div>
                                                        <div style="position: absolute; margin-left: -10000px;">
                                                            <input type="radio" value="1" name="xray_enable" id="xray_enable_1" <% nvram_match_x("", "xray_enable", "1", "checked"); %>> 是
                                                            <input type="radio" value="0" name="xray_enable" id="xray_enable_0" <% nvram_match_x("", "xray_enable", "0", "checked"); %>> 否
                                                        </div>
                                                    </td>
                                                </tr>
                                                <tr>
                                                    <th>运行模式</th>
                                                    <td>
                                                        <select name="xray_run_mode" class="input" style="width: 200px;">
                                                            <option value="gfw" <% nvram_match_x("", "xray_run_mode", "gfw", "selected"); %>>GFW列表模式</option>
                                                            <option value="router" <% nvram_match_x("", "xray_run_mode", "router", "selected"); %>>绕过大陆IP模式</option>
                                                            <option value="all" <% nvram_match_x("", "xray_run_mode", "all", "selected"); %>>全局模式</option>
                                                            <option value="oversea" <% nvram_match_x("", "xray_run_mode", "oversea", "selected"); %>>海外回国模式</option>
                                                        </select>
                                                    </td>
                                                </tr>
                                                <tr>
                                                    <th>并发线程数</th>
                                                    <td>
                                                        <select name="xray_threads" class="input" style="width: 200px;">
                                                            <option value="0" <% nvram_match_x("", "xray_threads", "0", "selected"); %>>自动 (CPU核心数)</option>
                                                            <option value="1" <% nvram_match_x("", "xray_threads", "1", "selected"); %>>1 线程</option>
                                                            <option value="2" <% nvram_match_x("", "xray_threads", "2", "selected"); %>>2 线程</option>
                                                            <option value="4" <% nvram_match_x("", "xray_threads", "4", "selected"); %>>4 线程</option>
                                                            <option value="8" <% nvram_match_x("", "xray_threads", "8", "selected"); %>>8 线程</option>
                                                            <option value="16" <% nvram_match_x("", "xray_threads", "16", "selected"); %>>16 线程</option>
                                                        </select>
                                                    </td>
                                                </tr>
                                                <tr>
                                                    <th>透明代理端口</th>
                                                    <td><input type="text" name="xray_local_port" class="input" style="width: 80px;" value="<% nvram_get_x("", "xray_local_port"); %>"> (0=禁用)</td>
                                                </tr>
                                                <tr>
                                                    <th>SOCKS5 端口</th>
                                                    <td><input type="text" name="xray_socks_port" class="input" style="width: 80px;" value="<% nvram_get_x("", "xray_socks_port"); %>"> (0=禁用)</td>
                                                </tr>
                                                <tr>
                                                    <th>HTTP 代理端口</th>
                                                    <td><input type="text" name="xray_http_port" class="input" style="width: 80px;" value="<% nvram_get_x("", "xray_http_port"); %>"> (0=禁用)</td>
                                                </tr>
                                                <tr id="row_xray_tun_enable">
                                                    <th>TUN 透明代理</th>
                                                    <td>
                                                        <div class="main_itoggle">
                                                            <div id="xray_tun_enable_on_of">
                                                                <input type="checkbox" id="xray_tun_enable_fake"
                                                                    <% nvram_match_x("", "xray_tun_enable", "1", "value=1 checked"); %><% nvram_match_x("", "xray_tun_enable", "0", "value=0"); %>>
                                                            </div>
                                                        </div>
                                                        <div style="position: absolute; margin-left: -10000px;">
                                                            <input type="radio" value="1" name="xray_tun_enable" id="xray_tun_enable_1" <% nvram_match_x("", "xray_tun_enable", "1", "checked"); %>> 是
                                                            <input type="radio" value="0" name="xray_tun_enable" id="xray_tun_enable_0" <% nvram_match_x("", "xray_tun_enable", "0", "checked"); %>> 否
                                                        </div>
                                                        <small style="color:#999;">需要内核支持 TUN，xray 26.10+ 新特性</small>
                                                    </td>
                                                </tr>
                                                <tr>
                                                    <th>本机流量代理</th>
                                                    <td>
                                                        <div class="main_itoggle">
                                                            <div id="xray_proxy_local_on_of">
                                                                <input type="checkbox" id="xray_proxy_local_fake"
                                                                    <% nvram_match_x("", "xray_proxy_local", "1", "value=1 checked"); %><% nvram_match_x("", "xray_proxy_local", "0", "value=0"); %>>
                                                            </div>
                                                        </div>
                                                        <div style="position: absolute; margin-left: -10000px;">
                                                            <input type="radio" value="1" name="xray_proxy_local" id="xray_proxy_local_1" <% nvram_match_x("", "xray_proxy_local", "1", "checked"); %>> 是
                                                            <input type="radio" value="0" name="xray_proxy_local" id="xray_proxy_local_0" <% nvram_match_x("", "xray_proxy_local", "0", "checked"); %>> 否
                                                        </div>
                                                    </td>
                                                </tr>
                                                <tr>
                                                    <th>主节点</th>
                                                    <td>
                                                        <select name="xray_global_server" id="xray_global_server" style="width: 250px;">
                                                            <option value="0">停用</option>
                                                        </select>
                                                    </td>
                                                </tr>
                                            </table>

                                            <table class="table">
                                                <tr>
                                                    <td style="border: 0 none; padding: 0px;">
                                                        <center><input name="button" type="button" class="btn btn-primary" style="width: 200px" onclick="applyRule();" value="应用设置" /></center>
                                                    </td>
                                                </tr>
                                            </table>
                                        </div>

                                        <!-- ===== 节点管理标签页 ===== -->
                                        <div id="wnd_xray_nodes" style="display:none;">
                                            <table width="100%" cellpadding="4" cellspacing="0" class="table">
                                                <tr>
                                                    <th colspan="2" style="background-color: #E3E3E3;">
                                                        节点管理 - 支持 VLESS/VMess/Trojan/Shadowsocks/SOCKS/Reality
                                                    </th>
                                                </tr>
                                                <tr>
                                                    <td colspan="2">
                                                        <input type="button" class="btn btn-primary" id="btn_add_node" value="添加节点">
                                                        <input type="button" class="btn btn-danger" id="btn_del_node" value="批量删除">
                                                        <input type="button" class="btn btn-info" value="导入链接" onclick="import_url();">
                                                        <input type="button" class="btn btn-success" value="测速选中" onclick="ping_selected();">
                                                    </td>
                                                </tr>
                                            </table>

                                            <table width="100%" cellpadding="4" cellspacing="0" class="table">
                                                <tr>
                                                    <th>订阅设置</th>
                                                </tr>
                                                <tr>
                                                    <td>
                                                        <div class="input-append" style="width: 100%;">
                                                            <input type="text" name="xray_sub_url" id="xray_sub_url" class="span10" placeholder="订阅地址 (一行一个，支持 base64)">
                                                            <button type="button" class="btn btn-primary" id="btn_update_sub" onclick="update_subscribe();">更新订阅</button>
                                                            <button type="button" class="btn btn-warning" id="btn_rest_sub" onclick="clear_subscribe();">清空订阅</button>
                                                        </div>
                                                        <br><small>关键字过滤 (用 / 分隔): <input type="text" name="xray_sub_keyword" id="xray_sub_keyword" value="<% nvram_get_x("", "xray_sub_keyword"); %>" style="width: 300px;"></small>
                                                        <br><small>更新间隔: <input type="text" name="xray_sub_interval" value="<% nvram_get_x("", "xray_sub_interval"); %>" style="width: 80px;"> 秒</small>
                                                    </td>
                                                </tr>
                                            </table>

                                            <table id="node_table"></table>

                                            <!-- 节点编辑弹窗 -->
                                            <div id="node_settings" class="contentM_qis" style="display:none; width: 700px;">
                                                <h4 id="node_title">添加节点</h4>
                                                <hr>
                                                <table class="table">
                                                    <tr>
                                                        <th width="15%">协议</th>
                                                        <td>
                                                            <select name="protocol" id="protocol" class="input" style="width: 150px;" onchange="onProtocolChange();">
                                                                <option value="vless">VLESS</option>
                                                                <option value="vmess">VMess</option>
                                                                <option value="trojan">Trojan</option>
                                                                <option value="shadowsocks">Shadowsocks</option>
                                                                <option value="socks">SOCKS5</option>
                                                            </select>
                                                        </td>
                                                    </tr>
                                                    <tr>
                                                        <th>别名</th>
                                                        <td><input type="text" name="alias" id="alias" class="input" style="width: 300px;" placeholder="节点显示名称"></td>
                                                    </tr>
                                                    <tr>
                                                        <th>服务器</th>
                                                        <td><input type="text" name="server" id="server" class="input" style="width: 200px;" placeholder="IP 或域名"></td>
                                                    </tr>
                                                    <tr>
                                                        <th>端口</th>
                                                        <td><input type="text" name="port" id="port" class="input" style="width: 80px;" value="443"></td>
                                                    </tr>

                                                    <!-- VLESS/VMess 专用 -->
                                                    <tr id="row_uuid">
                                                        <th>UUID</th>
                                                        <td><input type="text" name="uuid" id="uuid" class="input" style="width: 300px;" placeholder="VLESS/VMess UUID"></td>
                                                    </tr>
                                                    <tr id="row_alterid">
                                                        <th>AlterId</th>
                                                        <td><input type="text" name="alter_id" id="alter_id" class="input" style="width: 80px;" value="0"> (仅 VMess)</td>
                                                    </tr>
                                                    <tr id="row_security">
                                                        <th>加密方式</th>
                                                        <td>
                                                            <select name="security" id="security" class="input" style="width: 150px;">
                                                                <option value="auto">auto</option>
                                                                <option value="aes-128-gcm">aes-128-gcm</option>
                                                                <option value="chacha20-poly1305">chacha20-poly1305</option>
                                                                <option value="none">none</option>
                                                            </select> (仅 VMess)
                                                        </td>
                                                    </tr>
                                                    <tr id="row_encryption">
                                                        <th>加密</th>
                                                        <td>
                                                            <select name="encryption" id="encryption" class="input" style="width: 150px;">
                                                                <option value="none">none</option>
                                                                <option value="aes-128-gcm">aes-128-gcm</option>
                                                            </select> (仅 VLESS)
                                                        </td>
                                                    </tr>
                                                    <tr id="row_flow">
                                                        <th>Flow</th>
                                                        <td>
                                                            <select name="flow" id="flow" class="input" style="width: 250px;">
                                                                <option value="">无 (默认)</option>
                                                                <option value="xtls-rprx-vision">xtls-rprx-vision (推荐)</option>
                                                                <option value="xtls-rprx-vision-udp443">xtls-rprx-vision-udp443</option>
                                                                <option value="xtls-rprx-direct">xtls-rprx-direct</option>
                                                            </select> (仅 VLESS + XTLS/Reality)
                                                        </td>
                                                    </tr>

                                                    <!-- Trojan/SS/SOCKS 专用 -->
                                                    <tr id="row_password">
                                                        <th>密码</th>
                                                        <td><input type="text" name="password" id="password" class="input" style="width: 300px;"></td>
                                                    </tr>
                                                    <tr id="row_ss_method">
                                                        <th>加密方式</th>
                                                        <td>
                                                            <select name="ss_method" id="ss_method" class="input" style="width: 200px;">
                                                                <option value="aes-128-gcm">aes-128-gcm</option>
                                                                <option value="aes-256-gcm">aes-256-gcm</option>
                                                                <option value="chacha20-poly1305">chacha20-poly1305</option>
                                                                <option value="2022-blake3-aes-128-gcm">2022-blake3-aes-128-gcm</option>
                                                                <option value="2022-blake3-aes-256-gcm">2022-blake3-aes-256-gcm</option>
                                                                <option value="2022-blake3-chacha20-poly1305">2022-blake3-chacha20-poly1305</option>
                                                            </select> (仅 Shadowsocks)
                                                        </td>
                                                    </tr>

                                                    <!-- 传输层 -->
                                                    <tr>
                                                        <th>传输协议</th>
                                                        <td>
                                                            <select name="v2_transport" id="v2_transport" class="input" style="width: 150px;" onchange="onTransportChange();">
                                                                <option value="tcp">TCP</option>
                                                                <option value="ws">WebSocket</option>
                                                                <option value="httpupgrade">HTTP/2 Upgrade</option>
                                                                <option value="grpc">gRPC</option>
                                                                <option value="h2">HTTP/2</option>
                                                                <option value="xhttp">xHTTP</option>
                                                                <option value="kcp">mKCP</option>
                                                                <option value="quic">QUIC</option>
                                                            </select>
                                                        </td>
                                                    </tr>

                                                    <!-- TLS -->
                                                    <tr>
                                                        <th>TLS</th>
                                                        <td>
                                                            <select name="v2_tls" id="v2_tls" class="input" style="width: 150px;" onchange="onTlsChange();">
                                                                <option value="0">无</option>
                                                                <option value="1">TLS</option>
                                                                <option value="2">Reality</option>
                                                            </select>
                                                        </td>
                                                    </tr>
                                                    <tr id="row_tls_fp">
                                                        <th>指纹</th>
                                                        <td>
                                                            <select name="v2_tls_fp" id="v2_tls_fp" class="input" style="width: 150px;">
                                                                <option value="chrome">Chrome</option>
                                                                <option value="firefox">Firefox</option>
                                                                <option value="safari">Safari</option>
                                                                <option value="ios">iOS</option>
                                                                <option value="android">Android</option>
                                                                <option value="edge">Edge</option>
                                                                <option value="360">360</option>
                                                                <option value="qq">QQ</option>
                                                                <option value="random">Random</option>
                                                                <option value="randomized">Randomized</option>
                                                            </select>
                                                        </td>
                                                    </tr>
                                                    <tr id="row_tls_host">
                                                        <th>SNI/ServerName</th>
                                                        <td><input type="text" name="v2_tls_host" id="v2_tls_host" class="input" style="width: 300px;" placeholder="通常填域名"></td>
                                                    </tr>
                                                    <tr id="row_tls_insecure">
                                                        <th>允许不安全证书</th>
                                                        <td>
                                                            <div class="main_itoggle">
                                                                <div id="v2_tls_insecure_on_of">
                                                                    <input type="checkbox" id="v2_tls_insecure_fake"
                                                                        <% nvram_match_x("", "xray_tls_insecure", "1", "value=1 checked"); %><% nvram_match_x("", "xray_tls_insecure", "0", "value=0"); %>>
                                                                </div>
                                                            </div>
                                                            <input type="hidden" name="v2_tls_insecure" id="v2_tls_insecure" value="0">
                                                        </td>
                                                    </tr>

                                                    <!-- Reality 专用 -->
                                                    <tr id="row_reality_pubkey">
                                                        <th>Public Key</th>
                                                        <td><input type="text" name="public_key" id="public_key" class="input" style="width: 400px;" placeholder="Reality 公钥"></td>
                                                    </tr>
                                                    <tr id="row_reality_shortid">
                                                        <th>Short IDs</th>
                                                        <td><input type="text" name="short_id" id="short_id" class="input" style="width: 400px;" placeholder="多个用逗号分隔，如: 0123,4567"></td>
                                                    </tr>
                                                    <tr id="row_reality_spiderx">
                                                        <th>SpiderX</th>
                                                        <td><input type="text" name="spider_x" id="spider_x" class="input" style="width: 150px;" value="/"> (通常为 /)</td>
                                                    </tr>

                                                    <!-- WebSocket / HTTP Upgrade -->
                                                    <tr id="row_ws_host">
                                                        <th>Host</th>
                                                        <td><input type="text" name="ws_host" id="ws_host" class="input" style="width: 300px;"></td>
                                                    </tr>
                                                    <tr id="row_ws_path">
                                                        <th>Path</th>
                                                        <td><input type="text" name="ws_path" id="ws_path" class="input" style="width: 300px;" value="/"></td>
                                                    </tr>

                                                    <!-- gRPC -->
                                                    <tr id="row_grpc_service">
                                                        <th>ServiceName</th>
                                                        <td><input type="text" name="grpc_service" id="grpc_service" class="input" style="width: 300px;"></td>
                                                    </tr>
                                                    <tr id="row_grpc_mode">
                                                        <th>MultiMode</th>
                                                        <td>
                                                            <select name="grpc_mode" id="grpc_mode" class="input" style="width: 150px;">
                                                                <option value="gun">gun</option>
                                                                <option value="multi">multi</option>
                                                            </select>
                                                        </td>
                                                    </tr>
                                                    <tr id="row_grpc_idle">
                                                        <th>Idle Timeout</th>
                                                        <td><input type="text" name="grpc_idle" id="grpc_idle" class="input" style="width: 80px;" value="60"> 秒</td>
                                                    </tr>
                                                    <tr id="row_grpc_health">
                                                        <th>Health Check</th>
                                                        <td><input type="text" name="grpc_health" id="grpc_health" class="input" style="width: 80px;" value="20"> 秒</td>
                                                    </tr>

                                                    <!-- HTTP/2 -->
                                                    <tr id="row_h2_host">
                                                        <th>Host</th>
                                                        <td><input type="text" name="h2_host" id="h2_host" class="input" style="width: 300px;"></td>
                                                    </tr>
                                                    <tr id="row_h2_path">
                                                        <th>Path</th>
                                                        <td><input type="text" name="h2_path" id="h2_path" class="input" style="width: 300px;" value="/"></td>
                                                    </tr>

                                                    <!-- xHTTP -->
                                                    <tr id="row_xhttp_host">
                                                        <th>Host</th>
                                                        <td><input type="text" name="xhttp_host" id="xhttp_host" class="input" style="width: 300px;"></td>
                                                    </tr>
                                                    <tr id="row_xhttp_path">
                                                        <th>Path</th>
                                                        <td><input type="text" name="xhttp_path" id="xhttp_path" class="input" style="width: 300px;" value="/"></td>
                                                    </tr>
                                                    <tr id="row_xhttp_mode">
                                                        <th>Mode</th>
                                                        <td>
                                                            <select name="xhttp_mode" id="xhttp_mode" class="input" style="width: 150px;">
                                                                <option value="auto">auto</option>
                                                                <option value="stream">stream</option>
                                                                <option value="packet">packet</option>
                                                            </select>
                                                        </td>
                                                    </tr>

                                                    <!-- mKCP -->
                                                    <tr id="row_kcp_mtu"><th>MTU</th><td><input type="text" name="kcp_mtu" id="kcp_mtu" class="input" style="width: 80px;" value="1350"></td></tr>
                                                    <tr id="row_kcp_tti"><th>TTI</th><td><input type="text" name="kcp_tti" id="kcp_tti" class="input" style="width: 80px;" value="50"> ms</td></tr>
                                                    <tr id="row_kcp_uplink"><th>Uplink Capacity</th><td><input type="text" name="kcp_uplink" id="kcp_uplink" class="input" style="width: 80px;" value="5"> MB/s</td></tr>
                                                    <tr id="row_kcp_downlink"><th>Downlink Capacity</th><td><input type="text" name="kcp_downlink" id="kcp_downlink" class="input" style="width: 80px;" value="20"> MB/s</td></tr>
                                                    <tr id="row_kcp_congestion"><th>Congestion</th><td><input type="checkbox" name="kcp_congestion" id="kcp_congestion" value="1"> 启用</td></tr>
                                                    <tr id="row_kcp_readbuf"><th>Read Buffer</th><td><input type="text" name="kcp_readbuf" id="kcp_readbuf" class="input" style="width: 80px;" value="2"> MB</td></tr>
                                                    <tr id="row_kcp_writebuf"><th>Write Buffer</th><td><input type="text" name="kcp_writebuf" id="kcp_writebuf" class="input" style="width: 80px;" value="2"> MB</td></tr>
                                                    <tr id="row_kcp_header"><th>Header 伪装</th><td><select name="kcp_header" id="kcp_header" class="input" style="width: 150px;"><option value="none">none</option><option value="srtp">srtp</option><option value="utp">utp</option><option value="wechat-video">wechat-video</option><option value="dtls">dtls</option><option value="wireguard">wireguard</option></select></td></tr>

                                                    <!-- TCP HTTP 伪装 -->
                                                    <tr id="row_tcp_header"><th>Header 类型</th><td><select name="tcp_header" id="tcp_header" class="input" style="width: 150px;"><option value="none">none</option><option value="http">HTTP</option></select></td></tr>
                                                    <tr id="row_tcp_host"><th>HTTP Host</th><td><input type="text" name="tcp_host" id="tcp_host" class="input" style="width: 300px;"></td></tr>
                                                    <tr id="row_tcp_path"><th>HTTP Path</th><td><input type="text" name="tcp_path" id="tcp_path" class="input" style="width: 300px;" value="/"></td></tr>

                                                    <!-- QUIC -->
                                                    <tr id="row_quic_security"><th>Security</th><td><select name="quic_security" id="quic_security" class="input" style="width: 150px;"><option value="none">none</option><option value="aes-128-gcm">aes-128-gcm</option><option value="chacha20-poly1305">chacha20-poly1305</option></select></td></tr>
                                                    <tr id="row_quic_key"><th>Key</th><td><input type="text" name="quic_key" id="quic_key" class="input" style="width: 300px;"></td></tr>
                                                    <tr id="row_quic_header"><th>Header</th><td><select name="quic_header" id="quic_header" class="input" style="width: 150px;"><option value="none">none</option><option value="srtp">srtp</option><option value="utp">utp</option></select></td></tr>

                                                    <!-- Mux -->
                                                    <tr>
                                                        <th>多路复用</th>
                                                        <td>
                                                            <div class="main_itoggle">
                                                                <div id="xray_mux_on_of">
                                                                    <input type="checkbox" id="xray_mux_fake" <% nvram_match_x("", "xray_mux", "1", "value=1 checked"); %><% nvram_match_x("", "xray_mux", "0", "value=0"); %>>
                                                                </div>
                                                            </div>
                                                            <input type="hidden" name="mux" id="mux" value="0">
                                                        </td>
                                                    </tr>
                                                    <tr>
                                                        <th>并发数</th>
                                                        <td><input type="text" name="mux_concurrency" id="mux_concurrency" class="input" style="width: 80px;" value="8"> XUDP: <input type="text" name="mux_xudp_concurrency" id="mux_xudp_concurrency" class="input" style="width: 80px;" value="16"></td>
                                                    </tr>

                                                    <tr>
                                                        <td colspan="2" style="text-align:center;">
                                                            <input type="button" class="btn btn-primary" value="保存" onclick="saveNode();">
                                                            <input type="button" class="btn" value="取消" onclick="$j('#node_settings').fadeOut(200);">
                                                        </td>
                                                    </tr>
                                                </table>
                                            </div>
                                        </div>

                                        <!-- ===== 路由规则标签页 ===== -->
                                        <div id="wnd_xray_routing" style="display:none;">
                                            <div class="alert alert-info">
                                                路由规则由运行模式自动生成。如需自定义，请修改 genconfig.lua 中的 build_routing() 函数。
                                            </div>
                                            <table class="table">
                                                <tr><th>当前模式</th><td><% nvram_get_x("", "xray_run_mode"); %></td></tr>
                                                <tr><th>模式说明</th><td>
                                                    <ul>
                                                        <li><strong>GFW列表:</strong> 默认直连，geosite:gfw/geoip:gfw 走代理</li>
                                                        <li><strong>绕过大陆:</strong> 默认代理，geoip:cn/geosite:cn 直连</li>
                                                        <li><strong>全局模式:</strong> 全部流量走代理</li>
                                                        <li><strong>海外模式:</strong> geoip:cn 走代理，其余直连</li>
                                                    </ul>
                                                </td></tr>
                                                <tr><th>Geo 文件自动更新</th><td>
                                                    <div class="main_itoggle">
                                                        <div id="xray_geo_update_on_of">
                                                            <input type="checkbox" id="xray_geo_update_fake" <% nvram_match_x("", "xray_geo_update", "1", "value=1 checked"); %><% nvram_match_x("", "xray_geo_update", "0", "value=0"); %>>
                                                        </div>
                                                    </div>
                                                    <input type="hidden" name="xray_geo_update" value="<% nvram_get_x("", "xray_geo_update"); %>">
                                                    <br><small>更新源: <input type="text" name="xray_geo_update_url" value="<% nvram_get_x("", "xray_geo_update_url"); %>" style="width: 400px;"></small>
                                                    <br><small>间隔: <input type="text" name="xray_geo_update_interval" value="<% nvram_get_x("", "xray_geo_update_interval"); %>" style="width: 80px;"> 秒</small>
                                                </td></tr>
                                            </table>
                                        </div>

                                        <!-- ===== DNS设置标签页 ===== -->
                                        <div id="wnd_xray_dns" style="display:none;">
                                            <table class="table">
                                                <tr>
                                                    <th width="30%">DNS 模式</th>
                                                    <td>
                                                        <select name="xray_dns_mode" class="input" style="width: 200px;">
                                                            <option value="local" <% nvram_match_x("", "xray_dns_mode", "local", "selected"); %>>本地 DNS</option>
                                                            <option value="remote" <% nvram_match_x("", "xray_dns_mode", "remote", "selected"); %>>远程 DNS</option>
                                                            <option value="fakeip" <% nvram_match_x("", "xray_dns_mode", "fakeip", "selected"); %>>FakeIP (需 TUN)</option>
                                                        </select>
                                                    </td>
                                                </tr>
                                                <tr>
                                                    <th>FakeIP 网段</th>
                                                    <td><input type="text" name="xray_fakeip_range" class="input" style="width: 200px;" value="<% nvram_get_x("", "xray_fakeip_range"); %>"></td>
                                                </tr>
                                                <tr>
                                                    <th>本地 DNS 服务器</th>
                                                    <td><input type="text" name="xray_local_dns" class="input" style="width: 400px;" value="<% nvram_get_x("", "xray_local_dns"); %>"> (逗号分隔)</td>
                                                </tr>
                                                <tr>
                                                    <th>远程 DNS 服务器</th>
                                                    <td><input type="text" name="xray_remote_dns" class="input" style="width: 400px;" value="<% nvram_get_x("", "xray_remote_dns"); %>"> (逗号分隔)</td>
                                                </tr>
                                                <tr>
                                                    <th>DoH 服务器</th>
                                                    <td><input type="text" name="xray_doh_dns" class="input" style="width: 400px;" value="<% nvram_get_x("", "xray_doh_dns"); %>"> (逗号分隔)</td>
                                                </tr>
                                                <tr>
                                                    <th>默认指纹</th>
                                                    <td>
                                                        <select name="xray_fingerprint" class="input" style="width: 200px;">
                                                            <option value="chrome" <% nvram_match_x("", "xray_fingerprint", "chrome", "selected"); %>>Chrome</option>
                                                            <option value="firefox" <% nvram_match_x("", "xray_fingerprint", "firefox", "selected"); %>>Firefox</option>
                                                            <option value="safari" <% nvram_match_x("", "xray_fingerprint", "safari", "selected"); %>>Safari</option>
                                                            <option value="ios" <% nvram_match_x("", "xray_fingerprint", "ios", "selected"); %>>iOS</option>
                                                            <option value="android" <% nvram_match_x("", "xray_fingerprint", "android", "selected"); %>>Android</option>
                                                            <option value="edge" <% nvram_match_x("", "xray_fingerprint", "edge", "selected"); %>>Edge</option>
                                                            <option value="360" <% nvram_match_x("", "xray_fingerprint", "360", "selected"); %>>360</option>
                                                            <option value="qq" <% nvram_match_x("", "xray_fingerprint", "qq", "selected"); %>>QQ</option>
                                                            <option value="random" <% nvram_match_x("", "xray_fingerprint", "random", "selected"); %>>Random</option>
                                                            <option value="randomized" <% nvram_match_x("", "xray_fingerprint", "randomized", "selected"); %>>Randomized</option>
                                                        </select>
                                                    </td>
                                                </tr>
                                                <tr>
                                                    <th>Mux 并发</th>
                                                    <td>连接: <input type="text" name="xray_mux_concurrency" class="input" style="width: 60px;" value="<% nvram_get_x("", "xray_mux_concurrency"); %>"> XUDP: <input type="text" name="xray_mux_xudp_concurrency" class="input" style="width: 60px;" value="<% nvram_get_x("", "xray_mux_xudp_concurrency"); %>"></td>
                                                </tr>
                                                <tr>
                                                    <th>日志级别</th>
                                                    <td>
                                                        <select name="xray_log_level" class="input" style="width: 150px;">
                                                            <option value="debug" <% nvram_match_x("", "xray_log_level", "debug", "selected"); %>>Debug</option>
                                                            <option value="info" <% nvram_match_x("", "xray_log_level", "info", "selected"); %>>Info</option>
                                                            <option value="warning" <% nvram_match_x("", "xray_log_level", "warning", "selected"); %>>Warning</option>
                                                            <option value="error" <% nvram_match_x("", "xray_log_level", "error", "selected"); %>>Error</option>
                                                            <option value="none" <% nvram_match_x("", "xray_log_level", "none", "selected"); %>>None</option>
                                                        </select>
                                                    </td>
                                                </tr>
                                            </table>
                                        </div>

                                        <!-- ===== 运行日志标签页 ===== -->
                                        <div id="wnd_xray_log" style="display:none;">
                                            <table class="table">
                                                <tr>
                                                    <th>Xray 运行日志</th>
                                                    <td>
                                                        <input type="button" class="btn btn-info" value="刷新" onclick="location.reload();">
                                                        <input type="button" class="btn btn-warning" value="清空日志" onclick="clear_log();">
                                                    </td>
                                                </tr>
                                            </table>
                                            <textarea rows="25" wrap="off" spellcheck="false" class="span12" style="font-family:'Courier New'; font-size:12px; background:#000; color:#0f0;" readonly>
<% cat /tmp/xray.log 2>/dev/null || echo "暂无日志"; %>
                                            </textarea>
                                        </div>

                                        <!-- ===== 帮助文档标签页 ===== -->
                                        <div id="wnd_xray_help" style="display:none;">
                                            <div class="alert alert-info">
                                                <h4>Xray 独立插件使用说明</h4>
                                                <ul>
                                                    <li><strong>协议支持:</strong> VLESS, VMess, Trojan, Shadowsocks (2022-blake3), SOCKS5</li>
                                                    <li><strong>传输层:</strong> TCP, WebSocket, HTTP/2 Upgrade, gRPC, HTTP/2, xHTTP, mKCP, QUIC</li>
                                                    <li><strong>安全层:</strong> TLS 1.2/1.3, Reality (推荐), 无加密</li>
                                                    <li><strong>新特性 (v26.10+):</strong> TUN 透明代理, xHTTP, 增强 gRPC, 改进 Mux/XUDP</li>
                                                    <li><strong>节点导入:</strong> 支持 vless:// vmess:// trojan:// ss:// socks:// reality:// 链接</li>
                                                    <li><strong>订阅:</strong> 支持 base64 编码的订阅链接，自动解析并去重</li>
                                                    <li><strong>路由:</strong> 内置 geoip:cn/geosite:cn/gfw 分流，支持自定义规则</li>
                                                    <li><strong>DNS:</strong> 支持本地/远程/FakeIP 三种模式，内置 DoH 支持</li>
                                                </ul>
                                                <p>官方文档: <a href="https://xtls.github.io/config" target="_blank">https://xtls.github.io/config</a></p>
                                            </div>
                                        </div>

                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </form>
    </div>
</body>
</html>