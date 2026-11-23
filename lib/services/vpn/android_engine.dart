import 'dart:async';
import 'dart:convert';
import 'package:flutter_v2ray/flutter_v2ray.dart';
import '../../models/proxy_server.dart';
import 'vpn_engine.dart';

/// Android VPN core backed by the Xray engine (flutter_v2ray). Supports full-VPN
/// (VpnService TUN) and proxy-only mode (local SOCKS5 for apps like Telegram).
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
    final p = d.split(':');
    if (p.length != 3) return Duration.zero;
    return Duration(
        hours: int.tryParse(p[0]) ?? 0,
        minutes: int.tryParse(p[1]) ?? 0,
        seconds: int.tryParse(p[2]) ?? 0);
  }

  @override
  Future<bool> requestPermission() => _v2ray.requestPermission();

  @override
  Future<void> connect(ProxyServer server,
      {bool proxyOnly = false, List<String> blockedApps = const [], int socksPort = 1080}) async {
    final parser = FlutterV2ray.parseFromURL(server.link);
    await _v2ray.startV2Ray(
      remark: parser.remark.isNotEmpty ? parser.remark : server.remark,
      config: _prepareConfig(parser.getFullConfiguration(), socksPort),
      proxyOnly: proxyOnly,
      blockedApps: blockedApps.isEmpty ? null : blockedApps,
      // bypassSubnets = subnets that go DIRECT (bypass the VPN tunnel).
      // Passing null routes all traffic through the TUN interface (full tunnel).
      // IPv6 flapping is handled at the Xray layer: _prepareConfig forces
      // UseIPv4 for DNS and the freedom outbound, so the core never attempts
      // an IPv6 connection regardless of what the TUN routes.
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
            url: 'https://www.google.com/generate_204',
          )
          .timeout(const Duration(seconds: 8), onTimeout: () => -1);
    } catch (_) {
      return -1;
    }
  }

  /// Normalise the generated Xray config before launch:
  ///  • rewrite the local SOCKS/HTTP inbound port to the user-chosen value
  ///    (so apps like Telegram can point at 127.0.0.1:<port> in proxy mode), and
  ///  • force IPv4 resolution/egress so the core never stalls on a failing IPv6
  ///    lookup or connection (a common "connected but no traffic" / timeout
  ///    symptom when the server has no working IPv6).
  String _prepareConfig(String config, int port) {
    try {
      final map = jsonDecode(config) as Map<String, dynamic>;

      // 1) Local inbound port.
      final inbounds = map['inbounds'];
      if (inbounds is List) {
        for (final ib in inbounds) {
          if (ib is Map && (ib['protocol'] == 'socks' || ib['protocol'] == 'http')) {
            ib['port'] = port;
          }
        }
      }

      // 2) Prefer IPv4 at the DNS layer.
      final dns = map['dns'];
      if (dns is Map) {
        dns['queryStrategy'] = 'UseIPv4';
      } else {
        map['dns'] = {'queryStrategy': 'UseIPv4'};
      }

      // 3) Prefer IPv4 on the direct (freedom) outbound.
      final outbounds = map['outbounds'];
      if (outbounds is List) {
        for (final ob in outbounds) {
          if (ob is Map && ob['protocol'] == 'freedom') {
            final settings = (ob['settings'] is Map)
                ? ob['settings'] as Map
                : (ob['settings'] = <String, dynamic>{});
            settings['domainStrategy'] = 'UseIPv4';
          }
        }
      }

      return jsonEncode(map);
    } catch (_) {
      return config;
    }
  }
}
