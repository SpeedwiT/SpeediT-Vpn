import 'dart:async';
import 'dart:convert';
import 'dart:io';
import '../../models/proxy_server.dart';
import 'singbox_config.dart';
import 'vpn_engine.dart';

/// Windows/desktop VPN core: drives a bundled `sing-box` sidecar.
///
/// The executable ships next to the app (data/flutter_assets/core/ or app dir).
/// We write a generated config to a temp file and run `sing-box run -c <cfg>`;
/// TUN mode needs the app to run as administrator (installer sets this up).
class DesktopEngine implements VpnEngine {
  Process? _proc;
  void Function(ConnStatus)? _statusCb;
  void Function(VpnStats)? _statsCb;
  Timer? _ticker;
  DateTime? _since;

  @override
  void onStatus(void Function(ConnStatus) cb) => _statusCb = cb;
  @override
  void onStats(void Function(VpnStats) cb) => _statsCb = cb;

  @override
  Future<void> init() async {}

  @override
  Future<bool> requestPermission() async => true; // handled by admin elevation

  String _corePath() {
    final exeDir = File(Platform.resolvedExecutable).parent.path;
    final name = Platform.isWindows ? 'sing-box.exe' : 'sing-box';
    final candidates = [
      '$exeDir${Platform.pathSeparator}core${Platform.pathSeparator}$name',
      '$exeDir${Platform.pathSeparator}data${Platform.pathSeparator}flutter_assets${Platform.pathSeparator}core${Platform.pathSeparator}$name',
      '$exeDir${Platform.pathSeparator}$name',
    ];
    for (final c in candidates) {
      if (File(c).existsSync()) return c;
    }
    return candidates.first;
  }

  @override
  Future<void> connect(ProxyServer server,
      {bool proxyOnly = false, List<String> blockedApps = const [], int socksPort = 1080}) async {
    _statusCb?.call(ConnStatus.connecting);
    final Map<String, dynamic> cfg;
    if (proxyOnly) {
      // Proxy-only mode: expose a local SOCKS5 inbound at socksPort, no TUN.
      cfg = SingboxConfig.buildProxyOnly(server.link, socksPort: socksPort);
    } else {
      cfg = SingboxConfig.build(server.link);
    }
    final dir = await Directory.systemTemp.createTemp('speedit_');
    final cfgFile = File('${dir.path}${Platform.pathSeparator}config.json');
    await cfgFile.writeAsString(const JsonEncoder.withIndent('  ').convert(cfg));

    _proc = await Process.start(_corePath(), ['run', '-c', cfgFile.path],
        mode: ProcessStartMode.normal);
    _since = DateTime.now();
    _statusCb?.call(ConnStatus.connected);
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      _statsCb?.call(VpnStats(duration: DateTime.now().difference(_since!)));
    });
    _proc!.exitCode.then((_) {
      _ticker?.cancel();
      _statusCb?.call(ConnStatus.disconnected);
    });
  }

  @override
  Future<void> disconnect() async {
    _ticker?.cancel();
    _proc?.kill();
    // Give the process up to 3 s to exit cleanly before we move on.
    await _proc?.exitCode.timeout(const Duration(seconds: 3), onTimeout: () => -1);
    _proc = null;
    _statusCb?.call(ConnStatus.disconnected);
  }

  @override
  Future<int> ping(ProxyServer server) async {
    // TCP connect latency to the server endpoint (core-agnostic).
    final sw = Stopwatch()..start();
    try {
      final socket = await Socket.connect(server.address, server.port,
          timeout: const Duration(seconds: 5));
      sw.stop();
      socket.destroy();
      return sw.elapsedMilliseconds;
    } catch (_) {
      return -1;
    }
  }
}
