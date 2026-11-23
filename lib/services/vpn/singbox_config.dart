import 'dart:convert';

/// Converts a proxy share link into a sing-box outbound JSON object.
/// Supports vless / vmess / trojan / shadowsocks with TLS/Reality and
/// ws/grpc/tcp transports. Used by the Windows (desktop) sidecar engine.
class SingboxConfig {
  /// Build a full sing-box config (TUN in, proxy out) for [link].
  static Map<String, dynamic> build(String link, {String? interfaceName}) {
    final proxy = outbound(link);
    return {
      'log': {'level': 'warn'},
      'dns': {
        'servers': [
          {'tag': 'remote', 'address': 'tls://1.1.1.1', 'detour': 'proxy'},
          {'tag': 'local', 'address': '223.5.5.5', 'detour': 'direct'},
        ],
        'rules': [
          {'outbound': 'any', 'server': 'local'},
        ],
        'final': 'remote',
        'strategy': 'prefer_ipv4',
      },
      'inbounds': [
        {
          'type': 'tun',
          'tag': 'tun-in',
          'interface_name': interfaceName ?? 'speedit',
          'address': ['172.19.0.1/30'],
          'auto_route': true,
          'strict_route': true,
          'stack': 'mixed',
          'sniff': true,
        }
      ],
      'outbounds': [
        proxy,
        {'type': 'direct', 'tag': 'direct'},
        {'type': 'block', 'tag': 'block'},
        {'type': 'dns', 'tag': 'dns-out'},
      ],
      'route': {
        'rules': [
          {'protocol': 'dns', 'outbound': 'dns-out'},
          {'ip_is_private': true, 'outbound': 'direct'},
        ],
        'final': 'proxy',
        'auto_detect_interface': true,
      },
    };
  }

  /// Build a proxy-only config: a local SOCKS5 inbound (no TUN), so apps can
  /// point at 127.0.0.1:[socksPort] explicitly. Used on desktop when the user
  /// enables "Proxy only" (avoids needing admin elevation for a TUN device).
  static Map<String, dynamic> buildProxyOnly(String link, {int socksPort = 1080}) {
    final proxy = outbound(link);
    return {
      'log': {'level': 'warn'},
      'dns': {
        'servers': [
          {'tag': 'remote', 'address': 'tls://1.1.1.1', 'detour': 'proxy'},
          {'tag': 'local', 'address': '223.5.5.5', 'detour': 'direct'},
        ],
        'final': 'remote',
        'strategy': 'prefer_ipv4',
      },
      'inbounds': [
        {
          'type': 'socks',
          'tag': 'socks-in',
          'listen': '127.0.0.1',
          'listen_port': socksPort,
          'sniff': true,
        }
      ],
      'outbounds': [
        proxy,
        {'type': 'direct', 'tag': 'direct'},
        {'type': 'dns', 'tag': 'dns-out'},
      ],
      'route': {
        'rules': [
          {'protocol': 'dns', 'outbound': 'dns-out'},
          {'ip_is_private': true, 'outbound': 'direct'},
        ],
        'final': 'proxy',
        'auto_detect_interface': true,
      },
    };
  }

  /// Build only the proxy outbound (tag "proxy") for [link].
  static Map<String, dynamic> outbound(String link) {
    link = link.trim();
    final scheme = link.substring(0, link.indexOf('://')).toLowerCase();
    switch (scheme) {
      case 'vless':
        return _vless(link);
      case 'vmess':
        return _vmess(link);
      case 'trojan':
        return _trojan(link);
      case 'ss':
        return _ss(link);
      default:
        throw UnsupportedError('Unsupported protocol for sing-box: $scheme');
    }
  }

  static Map<String, dynamic> _tlsFromQuery(Uri u, {String? sniFallback}) {
    final q = u.queryParameters;
    final security = q['security'] ?? 'none';
    if (security == 'none') return {};
    final tls = <String, dynamic>{
      'enabled': true,
      'server_name': q['sni'] ?? q['host'] ?? sniFallback ?? u.host,
      'insecure': q['allowInsecure'] == '1' || q['allowInsecure'] == 'true',
    };
    if (q['alpn'] != null) tls['alpn'] = q['alpn']!.split(',');
    if (q['fp'] != null) tls['utls'] = {'enabled': true, 'fingerprint': q['fp']};
    if (security == 'reality') {
      tls['reality'] = {
        'enabled': true,
        if (q['pbk'] != null) 'public_key': q['pbk'],
        if (q['sid'] != null) 'short_id': q['sid'],
      };
      tls['utls'] = {'enabled': true, 'fingerprint': q['fp'] ?? 'chrome'};
    }
    return {'tls': tls};
  }

  static Map<String, dynamic>? _transportFromQuery(Uri u) {
    final q = u.queryParameters;
    final type = q['type'] ?? 'tcp';
    switch (type) {
      case 'ws':
        return {
          'type': 'ws',
          'path': q['path'] ?? '/',
          if (q['host'] != null) 'headers': {'Host': q['host']},
        };
      case 'grpc':
        return {'type': 'grpc', 'service_name': q['serviceName'] ?? q['path'] ?? ''};
      default:
        return null;
    }
  }

  static Map<String, dynamic> _vless(String link) {
    final u = Uri.parse(link);
    final q = u.queryParameters;
    final o = <String, dynamic>{
      'type': 'vless',
      'tag': 'proxy',
      'server': u.host,
      'server_port': u.hasPort ? u.port : 443,
      'uuid': u.userInfo,
      if (q['flow'] != null && q['flow']!.isNotEmpty) 'flow': q['flow'],
    };
    o.addAll(_tlsFromQuery(u));
    final t = _transportFromQuery(u);
    if (t != null) o['transport'] = t;
    return o;
  }

  static Map<String, dynamic> _vmess(String link) {
    final m = jsonDecode(utf8.decode(base64.decode(_pad(link.substring('vmess://'.length)))))
        as Map<String, dynamic>;
    final o = <String, dynamic>{
      'type': 'vmess',
      'tag': 'proxy',
      'server': m['add'].toString(),
      'server_port': int.tryParse(m['port'].toString()) ?? 443,
      'uuid': m['id'].toString(),
      'security': 'auto',
      'alter_id': int.tryParse((m['aid'] ?? 0).toString()) ?? 0,
    };
    if ((m['tls'] ?? '').toString().isNotEmpty && m['tls'] != 'none') {
      o['tls'] = {
        'enabled': true,
        'server_name': (m['sni'] ?? m['host'] ?? m['add']).toString(),
        'insecure': false,
      };
    }
    final net = (m['net'] ?? 'tcp').toString();
    if (net == 'ws') {
      o['transport'] = {
        'type': 'ws',
        'path': (m['path'] ?? '/').toString(),
        if ((m['host'] ?? '').toString().isNotEmpty) 'headers': {'Host': m['host'].toString()},
      };
    } else if (net == 'grpc') {
      o['transport'] = {'type': 'grpc', 'service_name': (m['path'] ?? '').toString()};
    }
    return o;
  }

  static Map<String, dynamic> _trojan(String link) {
    final u = Uri.parse(link);
    final o = <String, dynamic>{
      'type': 'trojan',
      'tag': 'proxy',
      'server': u.host,
      'server_port': u.hasPort ? u.port : 443,
      'password': u.userInfo,
    };
    final tls = _tlsFromQuery(u);
    o.addAll(tls.isEmpty ? {'tls': {'enabled': true, 'server_name': u.host, 'insecure': false}} : tls);
    final t = _transportFromQuery(u);
    if (t != null) o['transport'] = t;
    return o;
  }

  static Map<String, dynamic> _ss(String link) {
    // ss://base64(method:password)@host:port#remark  OR  ss://base64(method:password@host:port)#remark
    var body = link.substring('ss://'.length);
    final hash = body.indexOf('#');
    if (hash >= 0) body = body.substring(0, hash);
    String method, password, host;
    int port;
    if (body.contains('@')) {
      final at = body.lastIndexOf('@');
      final userPart = body.substring(0, at);
      final hostPart = body.substring(at + 1);
      final decoded = _tryB64(userPart) ?? userPart;
      final c = decoded.indexOf(':');
      method = decoded.substring(0, c);
      password = decoded.substring(c + 1);
      final hp = hostPart.split(':');
      host = hp[0];
      port = int.tryParse(hp.length > 1 ? hp[1] : '443') ?? 443;
    } else {
      final decoded = utf8.decode(base64.decode(_pad(body)));
      final at = decoded.lastIndexOf('@');
      final cred = decoded.substring(0, at);
      final hostPart = decoded.substring(at + 1);
      final c = cred.indexOf(':');
      method = cred.substring(0, c);
      password = cred.substring(c + 1);
      final hp = hostPart.split(':');
      host = hp[0];
      port = int.tryParse(hp.length > 1 ? hp[1] : '443') ?? 443;
    }
    return {
      'type': 'shadowsocks',
      'tag': 'proxy',
      'server': host,
      'server_port': port,
      'method': method,
      'password': password,
    };
  }

  static String? _tryB64(String s) {
    try {
      return utf8.decode(base64.decode(_pad(s)));
    } catch (_) {
      return null;
    }
  }

  static String _pad(String s) {
    s = s.replaceAll('-', '+').replaceAll('_', '/');
    final mod = s.length % 4;
    return mod == 0 ? s : s + '=' * (4 - mod);
  }
}
