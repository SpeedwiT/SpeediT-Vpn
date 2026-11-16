import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/proxy_server.dart';
import '../models/subscription.dart';

/// Thin persistence layer over SharedPreferences (servers, subscriptions, settings).
class Storage {
  static const _kServers = 'servers';
  static const _kSubs = 'subscriptions';
  static const _kSelected = 'selected_server';
  static const _kSettings = 'settings';

  final SharedPreferences _p;
  Storage(this._p);

  static Future<Storage> open() async => Storage(await SharedPreferences.getInstance());

  List<ProxyServer> loadServers() {
    final raw = _p.getString(_kServers);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List;
    return list.map((e) => ProxyServer.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> saveServers(List<ProxyServer> s) =>
      _p.setString(_kServers, jsonEncode(s.map((e) => e.toJson()).toList()));

  List<Subscription> loadSubs() {
    final raw = _p.getString(_kSubs);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List;
    return list.map((e) => Subscription.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> saveSubs(List<Subscription> s) =>
      _p.setString(_kSubs, jsonEncode(s.map((e) => e.toJson()).toList()));

  String? loadSelected() => _p.getString(_kSelected);
  Future<void> saveSelected(String? id) =>
      id == null ? _p.remove(_kSelected) : _p.setString(_kSelected, id);

  Map<String, dynamic> loadSettings() {
    final raw = _p.getString(_kSettings);
    if (raw == null) return {};
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  Future<void> saveSettings(Map<String, dynamic> s) => _p.setString(_kSettings, jsonEncode(s));
}
