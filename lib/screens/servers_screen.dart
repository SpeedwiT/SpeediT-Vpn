import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/strings.dart';
import '../state/app_state.dart';
import '../theme/app_colors.dart';
import '../widgets/add_menu.dart';
import '../widgets/ui_kit.dart';

class ServersScreen extends StatelessWidget {
  const ServersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = AppColors.of(context);
    final state = context.watch<AppState>();
    return AnimatedBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(s.t('servers')),
          actions: [
            if (state.servers.isNotEmpty)
              IconButton(
                tooltip: s.t('ping_all'),
                icon: const Icon(Icons.speed_rounded),
                onPressed: () {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text(s.t('ping_all'))));
                  state.pingAll();
                },
              ),
            IconButton(
              tooltip: s.t('add_config'),
              icon: const Icon(Icons.add_rounded),
              onPressed: () => showAddMenu(context, state),
            ),
            const SizedBox(width: 4),
          ],
        ),
        body: state.servers.isEmpty
            ? _empty(context, s, c, state)
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                itemCount: state.servers.length,
                itemBuilder: (context, i) {
                  final sv = state.servers[i];
                  final selected = sv.id == state.selectedId;
                  return FadeSlideIn(
                    delayMs: 40 * (i.clamp(0, 10)),
                    child: GlassCard(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      onTap: () => state.selectServer(sv.id),
                      child: Row(
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 220),
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: selected ? c.accent : Colors.transparent,
                              border: Border.all(color: selected ? c.accent : c.textDim, width: 2),
                            ),
                            child: selected
                                ? Icon(Icons.check, size: 14, color: c.onAccent)
                                : null,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(sv.remark,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(fontWeight: FontWeight.w800, color: c.text)),
                                const SizedBox(height: 2),
                                Text('${sv.protocol} · ${sv.address}:${sv.port}',
                                    maxLines: 1, overflow: TextOverflow.ellipsis,
                                    style: TextStyle(color: c.textDim, fontSize: 12.5)),
                              ],
                            ),
                          ),
                          if (sv.pingMs != null)
                            Text(
                              sv.pingMs! >= 0 ? '${sv.pingMs} ${s.t('ms')}' : s.t('timeout'),
                              style: TextStyle(
                                color: sv.pingMs! < 0 ? c.textDim : c.text,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          IconButton(
                            icon: Icon(Icons.close_rounded, size: 18, color: c.textDim),
                            onPressed: () => state.deleteServer(sv.id),
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

  Widget _empty(BuildContext context, S s, AppColors c, AppState state) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: FadeSlideIn(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.dns_rounded, size: 60, color: c.textDim),
                const SizedBox(height: 16),
                Text(s.t('no_servers'),
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: c.text)),
                const SizedBox(height: 8),
                Text(s.t('no_servers_hint'), textAlign: TextAlign.center, style: TextStyle(color: c.textDim)),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: () => showAddMenu(context, state),
                  icon: const Icon(Icons.add_rounded),
                  label: Text(s.t('add_sub')),
                ),
              ],
            ),
          ),
        ),
      );
}
