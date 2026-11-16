import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../l10n/strings.dart';
import '../services/subscription_service.dart';
import '../state/app_state.dart';
import '../theme/app_colors.dart';
import '../widgets/ui_kit.dart';
import 'qr_scan_screen.dart';

class SubscriptionsScreen extends StatelessWidget {
  const SubscriptionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = AppColors.of(context);
    final state = context.watch<AppState>();
    return AnimatedBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(s.t('subscriptions')),
          actions: [
            if (state.subs.isNotEmpty)
              TextButton.icon(
                style: TextButton.styleFrom(foregroundColor: c.text),
                onPressed: () {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text(s.t('update_all'))));
                  state.updateAll();
                },
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: Text(s.t('update_all')),
              ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _showAddSheet(context, s, c, state),
          backgroundColor: c.accent,
          foregroundColor: c.onAccent,
          icon: const Icon(Icons.add_rounded),
          label: Text(s.t('add_sub'), style: const TextStyle(fontWeight: FontWeight.w800)),
        ),
        body: state.subs.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Text(s.t('no_servers_hint'),
                      textAlign: TextAlign.center, style: TextStyle(color: c.textDim)),
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                itemCount: state.subs.length,
                itemBuilder: (context, i) {
                  final sub = state.subs[i];
                  return FadeSlideIn(
                    delayMs: 40 * (i.clamp(0, 10)),
                    child: GlassCard(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          Icon(Icons.cloud_rounded, color: c.text),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(sub.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(fontWeight: FontWeight.w800, color: c.text)),
                                const SizedBox(height: 2),
                                Text(
                                    sub.updatedAt == null
                                        ? s.t('never_updated')
                                        : s.t('servers_count').replaceAll('{n}', '${sub.serverCount}'),
                                    style: TextStyle(color: c.textDim, fontSize: 12.5)),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.refresh_rounded, color: c.text),
                            onPressed: () => state.updateSub(sub),
                          ),
                          IconButton(
                            icon: Icon(Icons.close_rounded, color: c.textDim),
                            onPressed: () => state.deleteSub(sub),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }

  void _showAddSheet(BuildContext context, S s, AppColors c, AppState state) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _opt(ctx, Icons.link_rounded, s.t('add_sub'), () => _addSubDialog(context, s, state)),
            _opt(ctx, Icons.vpn_key_rounded, s.t('add_config'), () => _addConfigDialog(context, s, state)),
            _opt(ctx, Icons.content_paste_rounded, s.t('import_clipboard'),
                () => _importClipboard(context, s, state)),
            if (Platform.isAndroid || Platform.isIOS)
              _opt(ctx, Icons.qr_code_scanner_rounded, s.t('scan_qr'), () async {
                final code = await Navigator.of(context)
                    .push<String>(MaterialPageRoute(builder: (_) => const QrScanScreen()));
                if (code != null && context.mounted) await _handleImported(context, s, state, code);
              }),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _opt(BuildContext ctx, IconData icon, String title, VoidCallback onTap) => ListTile(
        leading: Icon(icon),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        onTap: () {
          Navigator.pop(ctx);
          onTap();
        },
      );

  void _addSubDialog(BuildContext context, S s, AppState state) {
    final name = TextEditingController();
    final url = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.t('add_sub')),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: name, decoration: InputDecoration(labelText: s.t('sub_name'))),
          const SizedBox(height: 12),
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
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s.t('updated'))));
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
    if (context.mounted) await _handleImported(context, s, state, text);
  }

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
