import 'dart:async';
import 'dart:convert';
import 'package:flutter_v2ray/flutter_v2ray.dart';
import '../../models/proxy_server.dart';
import 'vpn_engine.dart';

/// Android VPN core backed by the Xray engine (flutter_v2ray). Real tunnel via
/// Android VpnService — supports VLESS / VMess / Trojan / Shadowsocks share links.
class AndroidEngine implements VpnEngine {
  late final FlutterV2ray _v2ray;
  void Function(ConnStatus)? _statusCb;
  void Function(VpnStats)? _statsCb;
  bool _inited = false;

  @override
  void onStatus(void Function(ConnStatus) cb) => _statusCb = cb;
  @override
  void onStats(void Function(VpnStats) cb) => _statsCb = cb;

  @override
  Future<void> init() async {
    if (_inited) return;
    _v2ray = FlutterV2ray(onStatusChanged: (status) {
      _statusCb?.call(_map(status.state));
      _statsCb?.call(VpnStats(
        duration: _parseDuration(status.duration),
        uploadSpeed: status.uploadSpeed,
        downloadSpeed: status.downloadSpeed,
      ));
    });
    await _v2ray.initializeV2Ray(
      notificationIconResourceType: 'drawable',
      notificationIconResourceName: 'ic_stat_speedit',
    );
    _inited = true;
  }

  ConnStatus _map(String state) {
    switch (state.toUpperCase()) {
      case 'CONNECTED':
        return ConnStatus.connected;
      case 'CONNECTING':
        return ConnStatus.connecting;
      default:
        return ConnStatus.disconnected;
    }
  }

  Duration _parseDuration(String d) {
    final parts = d.split(':');
    if (parts.length != 3) return Duration.zero;
    return Duration(
      hours: int.tryParse(parts[0]) ?? 0,
      minutes: int.tryParse(parts[1]) ?? 0,
      seconds: int.tryParse(parts[2]) ?? 0,
    );
  }

  @override
  Future<bool> requestPermission() => _v2ray.requestPermission();

  @override
  Future<void> connect(ProxyServer server,
      {bool proxyOnly = false, List<String> blockedApps = const [], int socksPort = 1080}) async {
    final parser = FlutterV2ray.parseFromURL(server.link);
    await _v2ray.startV2Ray(
      remark: parser.remark.isNotEmpty ? parser.remark : server.remark,
      config: _withSocksPort(parser.getFullConfiguration(), socksPort),
      proxyOnly: proxyOnly,
      blockedApps: blockedApps.isEmpty ? null : blockedApps,
      bypassSubnets: const ['0.0.0.0/0', '::/0'], // route all traffic into the tunnel
    );
  }

  /// Rewrite the local SOCKS inbound port in the generated Xray config so the
  /// user-chosen proxy port takes effect (used by apps like Telegram).
  String _withSocksPort(String config, int port) {
    if (port == 1080) return config;
    try {
      final map = jsonDecode(config) as Map<String, dynamic>;
      final inbounds = map['inbounds'];
      if (inbounds is List) {
        for (final ib in inbounds) {
          if (ib is Map && (ib['protocol'] == 'socks' || ib['protocol'] == 'http')) {
            ib['port'] = port;
          }
        }
      }
      return jsonEncode(map);
    } catch (_) {
      return config;
    }
  }

  @override
  Future<void> disconnect() => _v2ray.stopV2Ray();

  @override
  Future<int> ping(ProxyServer server) async {
    try {
      final parser = FlutterV2ray.parseFromURL(server.link);
      return await _v2ray
          .getServerDelay(
            config: parser.getFullConfiguration(),
            url: 'https://www.google.com/generate_204', // ping measured against Google
          )
          .timeout(const Duration(seconds: 8), onTimeout: () => -1);
    } catch (_) {
      return -1;
    }
  }
}
