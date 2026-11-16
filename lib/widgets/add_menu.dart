import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../l10n/strings.dart';
import '../screens/qr_scan_screen.dart';
import '../services/subscription_service.dart';
import '../state/app_state.dart';

/// Opens the "add" bottom sheet (subscription / config / clipboard / QR).
/// Shared by the Subscriptions and Servers screens so adding is always reachable.
Future<void> showAddMenu(BuildContext context, AppState state) async {
  final s = S.of(context);
  await showModalBottomSheet(
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
