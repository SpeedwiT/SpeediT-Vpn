import 'dart:io';
import '../../models/proxy_server.dart';
import 'android_engine.dart';
import 'desktop_engine.dart';

enum ConnStatus { disconnected, connecting, connected }

class VpnStats {
  final Duration duration;
  final int uploadSpeed;
  final int downloadSpeed;
  const VpnStats({this.duration = Duration.zero, this.uploadSpeed = 0, this.downloadSpeed = 0});
}

/// Platform-agnostic VPN core. Android uses the Xray core (flutter_v2ray);
/// Windows/desktop uses a bundled sing-box sidecar.
abstract class VpnEngine {
  void onStatus(void Function(ConnStatus) cb);
  void onStats(void Function(VpnStats) cb);

  Future<void> init();

  /// Ask the OS for VPN permission (Android). Returns true if granted.
  Future<bool> requestPermission();

  Future<void> connect(ProxyServer server,
      {bool proxyOnly = false, List<String> blockedApps = const [], int socksPort = 1080});
  Future<void> disconnect();

  /// Measure latency to a server, in ms. Returns -1 on failure/timeout.
  Future<int> ping(ProxyServer server);

  static VpnEngine create() {
    if (Platform.isAndroid) return AndroidEngine();
    return DesktopEngine();
  }
}
