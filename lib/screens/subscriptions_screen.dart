import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/strings.dart';
import '../state/app_state.dart';
import '../theme/app_colors.dart';
import '../widgets/add_menu.dart';
import '../widgets/ui_kit.dart';

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
              IconButton(
                tooltip: s.t('update_all'),
                icon: const Icon(Icons.refresh_rounded),
                onPressed: () {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text(s.t('update_all'))));
                  state.updateAll();
                },
              ),
            IconButton(
              tooltip: s.t('add_sub'),
              icon: const Icon(Icons.add_rounded),
              onPressed: () => showAddMenu(context, state),
            ),
            const SizedBox(width: 4),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => showAddMenu(context, state),
          backgroundColor: c.accent,
          foregroundColor: c.onAccent,
          icon: const Icon(Icons.add_rounded),
          label: Text(s.t('add_sub'), style: const TextStyle(fontWeight: FontWeight.w800)),
        ),
        body: state.subs.isEmpty
            ? _empty(context, s, c, state)
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                itemCount: state.subs.length,
                itemBuilder: (context, i) {
                  final sub = state.subs[i];
                  return FadeSlideIn(
                    delayMs: 30 * (i.clamp(0, 8)),
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

  Widget _empty(BuildContext context, S s, AppColors c, AppState state) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: FadeSlideIn(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.cloud_rounded, size: 60, color: c.textDim),
                const SizedBox(height: 16),
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
