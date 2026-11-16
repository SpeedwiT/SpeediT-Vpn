import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/strings.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';

class ServersScreen extends StatelessWidget {
  const ServersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final state = context.watch<AppState>();
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(s.t('servers')),
        actions: [
          TextButton.icon(
            onPressed: state.servers.isEmpty
                ? null
                : () {
                    ScaffoldMessenger.of(context)
                        .showSnackBar(SnackBar(content: Text(s.t('ping_all'))));
                    state.pingAll();
                  },
            icon: const Icon(Icons.speed, size: 18),
            label: Text(s.t('ping_all')),
          ),
        ],
      ),
      body: state.servers.isEmpty
          ? _empty(context, s)
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: state.servers.length,
              itemBuilder: (context, i) {
                final sv = state.servers[i];
                final selected = sv.id == state.selectedId;
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    onTap: () => state.selectServer(sv.id),
                    leading: Icon(
                      selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                      color: selected ? AppTheme.brandBlue : Colors.grey,
                    ),
                    title: Text(sv.remark, maxLines: 1, overflow: TextOverflow.ellipsis),
                    subtitle: Text('${sv.protocol} · ${sv.address}:${sv.port}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (sv.pingMs != null)
                          Text(
                            sv.pingMs! >= 0 ? '${sv.pingMs} ${s.t('ms')}' : s.t('timeout'),
                            style: TextStyle(
                              color: sv.pingMs! < 0
                                  ? AppTheme.danger
                                  : (sv.pingMs! < 300 ? AppTheme.good : Colors.orange),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 20),
                          onPressed: () => state.deleteServer(sv.id),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _empty(BuildContext context, S s) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.dns_outlined, size: 64, color: AppTheme.brandBlue),
              const SizedBox(height: 16),
              Text(s.t('no_servers'),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              Text(s.t('no_servers_hint'), textAlign: TextAlign.center),
            ],
          ),
        ),
      );
}
