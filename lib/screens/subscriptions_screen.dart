import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../l10n/strings.dart';
import '../models/subscription.dart';
import '../services/subscription_service.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import 'qr_scan_screen.dart';

class SubscriptionsScreen extends StatelessWidget {
  const SubscriptionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final state = context.watch<AppState>();
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(s.t('subscriptions')),
        actions: [
          if (state.subs.isNotEmpty)
            TextButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(content: Text(s.t('update_all'))));
                state.updateAll();
              },
              icon: const Icon(Icons.refresh, size: 18),
              label: Text(s.t('update_all')),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddSheet(context, s, state),
        backgroundColor: AppTheme.brandBlue,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(s.t('add_sub'), style: const TextStyle(color: Colors.white)),
      ),
      body: state.subs.isEmpty
          ? Center(child: Text(s.t('no_servers_hint'), textAlign: TextAlign.center))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: state.subs.length,
              itemBuilder: (context, i) {
                final sub = state.subs[i];
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    leading: const Icon(Icons.cloud_outlined, color: AppTheme.brandBlue),
                    title: Text(sub.name),
                    subtitle: Text(sub.updatedAt == null
                        ? s.t('never_updated')
                        : s.t('servers_count').replaceAll('{n}', '${sub.serverCount}')),
                    trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                      IconButton(
                        icon: const Icon(Icons.refresh),
                        onPressed: () => state.updateSub(sub),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => state.deleteSub(sub),
                      ),
                    ]),
                  ),
                );
              },
            ),
    );
  }

  void _showAddSheet(BuildContext context, S s, AppState state) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.link, color: AppTheme.brandBlue),
              title: Text(s.t('add_sub')),
              onTap: () {
                Navigator.pop(ctx);
                _addSubDialog(context, s, state);
              },
            ),
            ListTile(
              leading: const Icon(Icons.vpn_key_outlined, color: AppTheme.brandBlue),
              title: Text(s.t('add_config')),
              onTap: () {
                Navigator.pop(ctx);
                _addConfigDialog(context, s, state);
              },
            ),
            ListTile(
              leading: const Icon(Icons.content_paste, color: AppTheme.brandBlue),
              title: Text(s.t('import_clipboard')),
              onTap: () async {
                Navigator.pop(ctx);
                await _importClipboard(context, s, state);
              },
            ),
            if (Platform.isAndroid || Platform.isIOS)
              ListTile(
                leading: const Icon(Icons.qr_code_scanner, color: AppTheme.brandBlue),
                title: Text(s.t('scan_qr')),
                onTap: () async {
                  Navigator.pop(ctx);
                  final code = await Navigator.of(context)
                      .push<String>(MaterialPageRoute(builder: (_) => const QrScanScreen()));
                  if (code != null) await _handleImported(context, s, state, code);
                },
              ),
          ],
        ),
      ),
    );
  }

  void _addSubDialog(BuildContext context, S s, AppState state) {
    final name = TextEditingController();
    final url = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.t('add_sub')),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: name, decoration: InputDecoration(labelText: s.t('sub_name'))),
          const SizedBox(height: 10),
          TextField(controller: url, decoration: InputDecoration(labelText: s.t('sub_url'))),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(s.t('cancel'))),
          FilledButton(
            onPressed: () async {
              if (url.text.trim().isEmpty) return;
              Navigator.pop(ctx);
              await state.addSub(
                  name.text.trim().isEmpty ? 'Subscription' : name.text.trim(), url.text.trim());
              if (context.mounted) {
                ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(content: Text(s.t('updated'))));
              }
            },
            child: Text(s.t('save')),
          ),
        ],
      ),
    );
  }

  void _addConfigDialog(BuildContext context, S s, AppState state) {
    final link = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.t('add_config')),
        content: TextField(
          controller: link,
          maxLines: 3,
          decoration: InputDecoration(labelText: s.t('config_link')),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(s.t('cancel'))),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _handleImported(context, s, state, link.text);
            },
            child: Text(s.t('save')),
          ),
        ],
      ),
    );
  }

  Future<void> _importClipboard(BuildContext context, S s, AppState state) async {
    final data = await Clipboard.getData('text/plain');
    final text = data?.text ?? '';
    if (text.trim().isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s.t('clipboard_empty'))));
      }
      return;
    }
    await _handleImported(context, s, state, text);
  }

  /// Accepts a single share link or a whole subscription body (multi-line / base64).
  Future<void> _handleImported(BuildContext context, S s, AppState state, String text) async {
    final servers = SubscriptionService.parseBody(text);
    String msg;
    if (servers.isEmpty) {
      msg = s.t('nothing_found');
    } else if (servers.length == 1) {
      final err = await state.addConfig(servers.first.link);
      msg = err == null ? s.t('added') : s.t(err);
    } else {
      for (final sv in servers) {
        await state.addConfig(sv.link);
      }
      msg = '${servers.length} ${s.t('added')}';
    }
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }
}
