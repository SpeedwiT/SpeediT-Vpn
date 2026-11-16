import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/strings.dart';
import '../services/vpn/vpn_engine.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import 'about_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final state = context.watch<AppState>();
    return Column(
      children: [
        _topBar(context, s),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _statusText(context, s, state),
              const SizedBox(height: 28),
              _ConnectButton(
                status: state.status,
                onTap: () async {
                  final err = await state.toggle();
                  if (err != null && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(s.t(err))),
                    );
                  }
                },
              ),
              const SizedBox(height: 36),
              if (state.isConnected) _statsRow(context, state),
              const SizedBox(height: 24),
              _serverCard(context, s, state),
            ],
          ),
        ),
      ],
    );
  }

  Widget _topBar(BuildContext context, S s) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                gradient: AppTheme.gradient,
                borderRadius: BorderRadius.circular(11),
              ),
              child: const Icon(Icons.bolt, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 10),
            const Text('SpeediT', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.info_outline),
              onPressed: () => Navigator.of(context)
                  .push(MaterialPageRoute(builder: (_) => const AboutScreen())),
            ),
          ],
        ),
      );

  Widget _statusText(BuildContext context, S s, AppState state) {
    final (label, color) = switch (state.status) {
      ConnStatus.connected => (s.t('connected'), AppTheme.good),
      ConnStatus.connecting => (s.t('connecting'), AppTheme.brandBlue),
      ConnStatus.disconnected => (s.t('disconnected'), Colors.grey),
    };
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: color.withValues(alpha: 0.5)),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 9, height: 9, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w700)),
          ]),
        ),
      ],
    );
  }

  Widget _statsRow(BuildContext context, AppState state) {
    String fmt(int bytes) {
      if (bytes > 1024 * 1024) return '${(bytes / 1024 / 1024).toStringAsFixed(1)} MB/s';
      if (bytes > 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB/s';
      return '$bytes B/s';
    }

    final d = state.stats.duration;
    final dur = '${d.inHours.toString().padLeft(2, '0')}:'
        '${(d.inMinutes % 60).toString().padLeft(2, '0')}:'
        '${(d.inSeconds % 60).toString().padLeft(2, '0')}';
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _stat(Icons.timer_outlined, dur),
        const SizedBox(width: 20),
        _stat(Icons.download, fmt(state.stats.downloadSpeed)),
        const SizedBox(width: 20),
        _stat(Icons.upload, fmt(state.stats.uploadSpeed)),
      ],
    );
  }

  Widget _stat(IconData i, String v) => Row(children: [
        Icon(i, size: 18, color: AppTheme.brandBlue),
        const SizedBox(width: 6),
        Text(v, style: const TextStyle(fontWeight: FontWeight.w700)),
      ]);

  Widget _serverCard(BuildContext context, S s, AppState state) {
    final sv = state.selected;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Card(
        child: ListTile(
          leading: const Icon(Icons.dns_outlined, color: AppTheme.brandBlue),
          title: Text(sv?.remark ?? s.t('no_server'),
              maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: sv != null ? Text('${sv.protocol} · ${sv.address}') : Text(s.t('tap_to_connect')),
          trailing: sv?.pingMs != null && sv!.pingMs! >= 0
              ? Text('${sv.pingMs} ${s.t('ms')}', style: const TextStyle(color: AppTheme.good))
              : const Icon(Icons.chevron_left),
        ),
      ),
    );
  }
}

class _ConnectButton extends StatefulWidget {
  final ConnStatus status;
  final VoidCallback onTap;
  const _ConnectButton({required this.status, required this.onTap});
  @override
  State<_ConnectButton> createState() => _ConnectButtonState();
}

class _ConnectButtonState extends State<_ConnectButton> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final active = widget.status != ConnStatus.disconnected;
    final color = widget.status == ConnStatus.connected
        ? AppTheme.good
        : (widget.status == ConnStatus.connecting ? AppTheme.brandBlue : AppTheme.brandViolet);
    return GestureDetector(
      onTap: widget.onTap,
      child: SizedBox(
        width: 230,
        height: 230,
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, _) {
            return Stack(
              alignment: Alignment.center,
              children: [
                if (active)
                  Container(
                    width: 180 + _c.value * 50,
                    height: 180 + _c.value * 50,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: color.withValues(alpha: (1 - _c.value) * 0.5)),
                    ),
                  ),
                Container(
                  width: 170,
                  height: 170,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [color.withValues(alpha: 0.9), color.withValues(alpha: 0.55)],
                    ),
                    boxShadow: [
                      BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 40, spreadRadius: 4),
                    ],
                  ),
                  child: Icon(
                    widget.status == ConnStatus.connecting ? Icons.sync : Icons.power_settings_new,
                    size: 72,
                    color: Colors.white,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
