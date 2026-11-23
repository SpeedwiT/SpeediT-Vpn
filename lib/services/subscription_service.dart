import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/proxy_server.dart';

/// Fetches a subscription URL and decodes it into a list of [ProxyServer].
///
/// Accepts the three shapes panels return:
///  1. base64 of newline-separated share links (most common),
///  2. plain newline-separated share links,
///  3. a single share link.
class SubscriptionService {
  static Future<List<ProxyServer>> fetch(String url, {String? subscriptionId}) async {
    final res = await http
        .get(Uri.parse(url), headers: {'User-Agent': 'V2hype/1.0'})
        .timeout(const Duration(seconds: 20));
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('HTTP ${res.statusCode}');
    }
    return parseBody(res.body, subscriptionId: subscriptionId);
  }

  /// Parse a raw subscription body (handles base64 or plain text).
  static List<ProxyServer> parseBody(String body, {String? subscriptionId}) {
    final text = _maybeBase64(body.trim());
    final out = <ProxyServer>[];
    for (final line in const LineSplitter().convert(text)) {
      final s = ProxyServer.parse(line.trim(), subscriptionId: subscriptionId);
      if (s != null) out.add(s);
    }
    return out;
  }

  /// If the whole body is base64 (no "://"), decode it; otherwise return as-is.
  static String _maybeBase64(String body) {
    if (body.contains('://')) return body;
    try {
      final mod = body.length % 4;
      final padded = mod == 0 ? body : body + '=' * (4 - mod);
      final decoded = utf8.decode(base64.decode(padded));
      if (decoded.contains('://')) return decoded;
    } catch (_) {}
    return body;
  }
}
