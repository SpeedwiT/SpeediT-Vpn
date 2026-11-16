import 'dart:async';
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
    await _v2ray.initializeV2Ray();
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
      {bool proxyOnly = false, List<String> blockedApps = const []}) async {
    final parser = FlutterV2ray.parseFromURL(server.link);
    await _v2ray.startV2Ray(
      remark: parser.remark.isNotEmpty ? parser.remark : server.remark,
      config: parser.getFullConfiguration(),
      proxyOnly: proxyOnly,
      blockedApps: blockedApps.isEmpty ? null : blockedApps,
      bypassSubnets: null,
    );
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
            url: 'https://cp.cloudflare.com/generate_204', // fast, reachable probe
          )
          .timeout(const Duration(seconds: 6), onTimeout: () => -1);
    } catch (_) {
      return -1;
    }
  }
}
