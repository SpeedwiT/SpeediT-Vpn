import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../l10n/strings.dart';
import '../models/proxy_server.dart';
import '../models/subscription.dart';
import '../services/storage.dart';
import '../services/subscription_service.dart';
import '../services/vpn/vpn_engine.dart';

class AppState extends ChangeNotifier {
  final Storage storage;
  final VpnEngine engine;

  List<ProxyServer> servers = [];
  List<Subscription> subs = [];
  String? selectedId;
  ConnStatus status = ConnStatus.disconnected;
  VpnStats stats = const VpnStats();

  // settings
  ThemeMode themeMode = ThemeMode.dark;
  String lang = 'fa';
  bool proxyOnly = false;
  bool killSwitch = false;
  bool autoPing = false;
  bool onboarded = false;
  bool isPinging = false;
  Timer? _pingTimer;

  AppState(this.storage, this.engine);

  ProxyServer? get selected {
    if (selectedId == null) return null;
    for (final s in servers) {
      if (s.id == selectedId) return s;
    }
    return null;
  }

  bool get isConnected => status == ConnStatus.connected;
  bool get isConnecting => status == ConnStatus.connecting;

  Future<void> init() async {
    servers = storage.loadServers();
    subs = storage.loadSubs();
    selectedId = storage.loadSelected();
    final st = storage.loadSettings();
    themeMode = _themeFromString(st['theme'] as String?);
    lang = st['lang'] as String? ?? 'fa';
    proxyOnly = st['proxyOnly'] as bool? ?? false;
    killSwitch = st['killSwitch'] as bool? ?? false;
    autoPing = st['autoPing'] as bool? ?? false;
    onboarded = st['onboarded'] as bool? ?? false;
    S.set(lang);
    if (autoPing) _startAutoPing();

    engine.onStatus((s) {
      status = s;
      notifyListeners();
    });
    engine.onStats((s) {
      stats = s;
      notifyListeners();
    });
    await engine.init();
    notifyListeners();
  }

  // ---- connection ----
  Future<String?> connect() async {
    final server = selected;
    if (server == null) return 'no_server';
    // Android 13+: the VPN runs as a foreground service that needs a notification;
    // without this permission some OEMs (e.g. MIUI) kill the service right after it starts.
    if (Platform.isAndroid) {
      try {
        if (!await Permission.notification.isGranted) {
          await Permission.notification.request();
        }
      } catch (_) {}
    }
    final ok = await engine.requestPermission();
    if (!ok) return 'permission_needed';
    status = ConnStatus.connecting;
    notifyListeners();
    await engine.connect(server, proxyOnly: proxyOnly);
    return null;
  }

  Future<void> disconnect() => engine.disconnect();

  /// Returns an error key (for S.t) when starting fails, else null.
  Future<String?> toggle() async {
    if (isConnected || isConnecting) {
      await disconnect();
      return null;
    }
    return await connect();
  }

  // ---- servers ----
  Future<void> selectServer(String id) async {
    selectedId = id;
    await storage.saveSelected(id);
    notifyListeners();
  }

  Future<String?> addConfig(String link) async {
    final s = ProxyServer.parse(link.trim());
    if (s == null) return 'invalid_link';
    servers = [...servers, s];
    selectedId ??= s.id;
    await _persistServers();
    return null;
  }

  Future<void> deleteServer(String id) async {
    servers = servers.where((s) => s.id != id).toList();
    if (selectedId == id) {
      selectedId = servers.isNotEmpty ? servers.first.id : null;
      await storage.saveSelected(selectedId);
    }
    await _persistServers();
  }

  Future<void> pingAll() async {
    if (isPinging || servers.isEmpty) return;
    isPinging = true;
    notifyListeners();
    final futures = servers.map((s) async {
      s.pingMs = await engine.ping(s);
      notifyListeners(); // update each result as it lands (feels faster)
    });
    await Future.wait(futures);
    isPinging = false;
    notifyListeners();
  }

  // ---- auto ping ----
  void _startAutoPing() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(const Duration(minutes: 5), (_) => pingAll());
  }

  void _stopAutoPing() {
    _pingTimer?.cancel();
    _pingTimer = null;
  }

  Future<void> setAutoPing(bool v) async {
    autoPing = v;
    if (v) {
      _startAutoPing();
      pingAll();
    } else {
      _stopAutoPing();
    }
    await _persistSettings();
  }

  Future<void> completeOnboarding(String language) async {
    lang = language;
    onboarded = true;
    S.set(language);
    await _persistSettings();
  }

  // ---- subscriptions ----
  Future<void> addSub(String name, String url) async {
    final sub = Subscription(
        id: DateTime.now().microsecondsSinceEpoch.toString(), name: name, url: url);
    subs = [...subs, sub];
    await storage.saveSubs(subs);
    await updateSub(sub);
  }

  Future<String?> updateSub(Subscription sub) async {
    try {
      final fetched = await SubscriptionService.fetch(sub.url, subscriptionId: sub.id);
      // replace this sub's servers
      servers = servers.where((s) => s.subscriptionId != sub.id).toList()..addAll(fetched);
      sub.serverCount = fetched.length;
      sub.updatedAt = DateTime.now();
      selectedId ??= servers.isNotEmpty ? servers.first.id : null;
      await _persistServers();
      await storage.saveSubs(subs);
      notifyListeners();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<void> updateAll() async {
    for (final s in subs) {
      await updateSub(s);
    }
  }

  Future<void> deleteSub(Subscription sub) async {
    subs = subs.where((s) => s.id != sub.id).toList();
    servers = servers.where((s) => s.subscriptionId != sub.id).toList();
    await storage.saveSubs(subs);
    await _persistServers();
  }

  // ---- settings ----
  Future<void> setTheme(ThemeMode m) async {
    themeMode = m;
    await _persistSettings();
  }

  Future<void> setLang(String l) async {
    lang = l;
    S.set(l);
    await _persistSettings();
  }

  Future<void> setProxyOnly(bool v) async {
    proxyOnly = v;
    await _persistSettings();
  }

  Future<void> setKillSwitch(bool v) async {
    killSwitch = v;
    await _persistSettings();
  }

  Future<void> _persistServers() async {
    await storage.saveServers(servers);
    notifyListeners();
  }

  Future<void> _persistSettings() async {
    await storage.saveSettings({
      'theme': _themeToString(themeMode),
      'lang': lang,
      'proxyOnly': proxyOnly,
      'killSwitch': killSwitch,
      'autoPing': autoPing,
      'onboarded': onboarded,
    });
    notifyListeners();
  }

  static ThemeMode _themeFromString(String? s) {
    switch (s) {
      case 'light':
        return ThemeMode.light;
      case 'system':
        return ThemeMode.system;
      default:
        return ThemeMode.dark;
    }
  }

  static String _themeToString(ThemeMode m) =>
      m == ThemeMode.light ? 'light' : (m == ThemeMode.system ? 'system' : 'dark');
}
