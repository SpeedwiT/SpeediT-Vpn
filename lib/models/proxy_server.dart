import 'dart:convert';

/// A single proxy server parsed from a share link (vless/vmess/trojan/ss…).
///
/// The raw [link] is kept verbatim — on Android it is handed to the Xray core
/// (flutter_v2ray) which parses it itself; on Windows it is converted to a
/// sing-box outbound. The decoded fields are only for display, grouping and ping.
class ProxyServer {
  final String id;
  final String remark;
  final String link;
  final String protocol; // vless | vmess | trojan | ss | ...
  final String address;
  final int port;
  final String? subscriptionId; // null = added manually
  int? pingMs; // last measured latency (null = unknown)

  ProxyServer({
    required this.id,
    required this.remark,
    required this.link,
    required this.protocol,
    required this.address,
    required this.port,
    this.subscriptionId,
    this.pingMs,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'remark': remark,
        'link': link,
        'protocol': protocol,
        'address': address,
        'port': port,
        'subscriptionId': subscriptionId,
      };

  factory ProxyServer.fromJson(Map<String, dynamic> j) => ProxyServer(
        id: j['id'] as String,
        remark: j['remark'] as String? ?? 'Server',
        link: j['link'] as String,
        protocol: j['protocol'] as String? ?? 'unknown',
        address: j['address'] as String? ?? '',
        port: (j['port'] as num?)?.toInt() ?? 0,
        subscriptionId: j['subscriptionId'] as String?,
      );

  /// Parse a single share link into a [ProxyServer]. Returns null if unsupported.
  static ProxyServer? parse(String raw, {String? subscriptionId}) {
    raw = raw.trim();
    if (raw.isEmpty) return null;
    final schemeIdx = raw.indexOf('://');
    if (schemeIdx <= 0) return null;
    final scheme = raw.substring(0, schemeIdx).toLowerCase();
    try {
      switch (scheme) {
        case 'vmess':
          return _parseVmess(raw, subscriptionId);
        case 'vless':
        case 'trojan':
          return _parseUriLike(raw, scheme, subscriptionId);
        case 'ss':
          return _parseSs(raw, subscriptionId);
        default:
          return null; // hysteria2/tuic etc. still stored by caller as raw-only
      }
    } catch (_) {
      return null;
    }
  }

  static String _id() =>
      DateTime.now().microsecondsSinceEpoch.toString() +
      (_counter++).toString();
  static int _counter = 0;

  static ProxyServer _parseUriLike(String raw, String scheme, String? sub) {
    final u = Uri.parse(raw);
    final remark = u.fragment.isNotEmpty ? Uri.decodeComponent(u.fragment) : '$scheme server';
    return ProxyServer(
      id: _id(),
      remark: remark,
      link: raw,
      protocol: scheme,
      address: u.host,
      port: u.hasPort ? u.port : 443,
      subscriptionId: sub,
    );
  }

  static ProxyServer _parseVmess(String raw, String? sub) {
    final b = raw.substring('vmess://'.length);
    final decoded = utf8.decode(base64.decode(_pad(b)));
    final m = jsonDecode(decoded) as Map<String, dynamic>;
    return ProxyServer(
      id: _id(),
      remark: (m['ps'] ?? 'vmess server').toString(),
      link: raw,
      protocol: 'vmess',
      address: (m['add'] ?? '').toString(),
      port: int.tryParse((m['port'] ?? '0').toString()) ?? 0,
      subscriptionId: sub,
    );
  }

  static ProxyServer _parseSs(String raw, String? sub) {
    final u = Uri.parse(raw);
    final remark = u.fragment.isNotEmpty ? Uri.decodeComponent(u.fragment) : 'shadowsocks';
    return ProxyServer(
      id: _id(),
      remark: remark,
      link: raw,
      protocol: 'ss',
      address: u.host,
      port: u.hasPort ? u.port : 443,
      subscriptionId: sub,
    );
  }

  static String _pad(String s) {
    final mod = s.length % 4;
    return mod == 0 ? s : s + '=' * (4 - mod);
  }
}
