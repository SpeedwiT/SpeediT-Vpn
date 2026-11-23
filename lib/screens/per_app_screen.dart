import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:installed_apps/app_info.dart';
import 'package:installed_apps/installed_apps.dart';
import 'package:provider/provider.dart';
import '../l10n/strings.dart';
import '../state/app_state.dart';
import '../theme/app_colors.dart';
import '../widgets/ui_kit.dart';

/// Screen to pick which apps bypass the VPN tunnel (split tunnel / per-app VPN).
/// The selected packages are passed to flutter_v2ray as [blockedApps] so those
/// apps connect directly, outside the tunnel.
class PerAppScreen extends StatefulWidget {
  const PerAppScreen({super.key});

  @override
  State<PerAppScreen> createState() => _PerAppScreenState();
}

class _PerAppScreenState extends State<PerAppScreen> {
  List<AppInfo> _apps = [];
  Set<String> _selected = {};
  bool _loading = true;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final state = context.read<AppState>();
    _selected = state.blockedApps.toSet();
    final apps = await InstalledApps.getInstalledApps(
      withIcon: true,
      excludeSystemApps: true,
      detectPlatformType: false,
    );
    apps.sort((a, b) => (a.name ?? '').compareTo(b.name ?? ''));
    if (mounted) setState(() { _apps = apps; _loading = false; });
  }

  List<AppInfo> get _filtered {
    if (_search.isEmpty) return _apps;
    final q = _search.toLowerCase();
    return _apps
        .where((a) =>
            (a.name ?? '').toLowerCase().contains(q) ||
            (a.packageName ?? '').toLowerCase().contains(q))
        .toList();
  }

  Future<void> _save() async {
    final state = context.read<AppState>();
    await state.setBlockedApps(_selected.toList());
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = AppColors.of(context);
    final filtered = _filtered;

    return AnimatedBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(s.t('per_app')),
          actions: [
            TextButton(
              onPressed: _loading ? null : _save,
              child: Text(s.t('save'),
                  style: TextStyle(
                      color: c.accent, fontWeight: FontWeight.w800, fontSize: 15)),
            ),
            const SizedBox(width: 6),
          ],
        ),
        body: _loading
            ? Center(child: CircularProgressIndicator(color: c.accent))
            : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: s.t('search_apps'),
                        prefixIcon: const Icon(Icons.search_rounded),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: c.glass,
                        contentPadding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      onChanged: (v) => setState(() => _search = v),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 6, 20, 8),
                    child: Text(
                      s.t('per_app_hint_detail'),
                      style: TextStyle(color: c.textDim, fontSize: 12.5, height: 1.5),
                    ),
                  ),
                  if (filtered.isEmpty)
                    Expanded(
                      child: Center(
                        child: Text(s.t('nothing_found'), style: TextStyle(color: c.textDim)),
                      ),
                    )
                  else
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                        itemCount: filtered.length,
                        itemBuilder: (context, i) {
                          final app = filtered[i];
                          final pkg = app.packageName ?? '';
                          final checked = _selected.contains(pkg);
                          return _AppTile(
                            name: app.name ?? pkg,
                            pkg: pkg,
                            icon: app.icon,
                            checked: checked,
                            accent: c.accent,
                            onAccent: c.onAccent,
                            onChanged: (v) {
                              setState(() {
                                if (v) {
                                  _selected.add(pkg);
                                } else {
                                  _selected.remove(pkg);
                                }
                              });
                            },
                          );
                        },
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}

class _AppTile extends StatelessWidget {
  final String name;
  final String pkg;
  final Uint8List? icon;
  final bool checked;
  final Color accent;
  final Color onAccent;
  final void Function(bool) onChanged;

  const _AppTile({
    required this.name,
    required this.pkg,
    required this.icon,
    required this.checked,
    required this.accent,
    required this.onAccent,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!checked),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: checked
              ? accent.withValues(alpha: 0.08)
              : Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: checked ? accent.withValues(alpha: 0.5) : Colors.white.withValues(alpha: 0.08),
          ),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: icon != null
                  ? Image.memory(icon!, width: 42, height: 42, fit: BoxFit.cover)
                  : Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.apps_rounded, size: 24),
                    ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  Text(pkg,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 11.5,
                          color: Colors.grey.withValues(alpha: 0.6))),
                ],
              ),
            ),
            const SizedBox(width: 10),
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: checked ? accent : Colors.transparent,
                border: Border.all(
                  color: checked ? accent : Colors.grey.withValues(alpha: 0.4),
                  width: 2,
                ),
              ),
              child: checked
                  ? Icon(Icons.check, size: 14, color: onAccent)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
