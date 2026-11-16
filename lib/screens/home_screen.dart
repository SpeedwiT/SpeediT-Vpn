import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/strings.dart';
import '../services/vpn/vpn_engine.dart';
import '../state/app_state.dart';
import '../theme/app_colors.dart';
import '../widgets/brand_mark.dart';
import '../widgets/connect_orb.dart';
import '../widgets/ui_kit.dart';
import 'about_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = AppColors.of(context);
    final state = context.watch<AppState>();
    return AnimatedBackground(
      child: Column(
        children: [
          _topBar(context, c),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FadeSlideIn(delayMs: 60, child: _statusChip(context, s, c, state)),
                const SizedBox(height: 30),
                FadeSlideIn(
                  delayMs: 120,
                  offsetY: 0,
                  child: ConnectOrb(
                    status: state.status,
                    onTap: () async {
                      final err = await state.toggle();
                      if (err != null && context.mounted) {
                        ScaffoldMessenger.of(context)
                            .showSnackBar(SnackBar(content: Text(s.t(err))));
                      }
                    },
                  ),
                ),
                const SizedBox(height: 34),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: state.isConnected
                      ? _statsRow(context, c, state)
                      : const SizedBox(height: 20),
                ),
                const SizedBox(height: 22),
                FadeSlideIn(delayMs: 200, child: _serverCard(context, s, c, state)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _topBar(BuildContext context, AppColors c) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 12, 0),
        child: Row(
          children: [
            const BrandMark(size: 42),
            const SizedBox(width: 10),
            Text('SpeediT',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: c.text, letterSpacing: -0.5)),
            const Spacer(),
            IconButton(
              icon: Icon(Icons.info_outline_rounded, color: c.text),
              onPressed: () => Navigator.of(context).push(FadeScaleRoute(const AboutScreen())),
            ),
          ],
        ),
      );

  Widget _statusChip(BuildContext context, S s, AppColors c, AppState state) {
    final label = switch (state.status) {
      ConnStatus.connected => s.t('connected'),
      ConnStatus.connecting => s.t('connecting'),
      ConnStatus.disconnected => s.t('disconnected'),
    };
    final filled = state.status == ConnStatus.connected;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
      decoration: BoxDecoration(
        color: filled ? c.accent : Colors.transparent,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: filled ? c.accent : c.line),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: filled ? c.onAccent : c.textDim,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(label,
            style: TextStyle(
                color: filled ? c.onAccent : c.textDim, fontWeight: FontWeight.w800, letterSpacing: 0.3)),
      ]),
    );
  }

  Widget _statsRow(BuildContext context, AppColors c, AppState state) {
    String fmt(int b) {
      if (b > 1024 * 1024) return '${(b / 1024 / 1024).toStringAsFixed(1)} MB/s';
      if (b > 1024) return '${(b / 1024).toStringAsFixed(0)} KB/s';
      return '$b B/s';
    }

    final d = state.stats.duration;
    final dur = '${d.inHours.toString().padLeft(2, '0')}:'
        '${(d.inMinutes % 60).toString().padLeft(2, '0')}:'
        '${(d.inSeconds % 60).toString().padLeft(2, '0')}';
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _stat(c, Icons.schedule_rounded, dur),
        _dot(c),
        _stat(c, Icons.south_rounded, fmt(state.stats.downloadSpeed)),
        _dot(c),
        _stat(c, Icons.north_rounded, fmt(state.stats.uploadSpeed)),
      ],
    );
  }

  Widget _dot(AppColors c) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Container(width: 4, height: 4, decoration: BoxDecoration(color: c.textDim, shape: BoxShape.circle)),
      );

  Widget _stat(AppColors c, IconData i, String v) => Row(children: [
        Icon(i, size: 17, color: c.textDim),
        const SizedBox(width: 6),
        Text(v, style: TextStyle(fontWeight: FontWeight.w800, color: c.text)),
      ]);

  Widget _serverCard(BuildContext context, S s, AppColors c, AppState state) {
    final sv = state.selected;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: c.accent.withValues(alpha: c.isDark ? 0.12 : 0.06),
                borderRadius: BorderRadius.circular(13),
                border: Border.all(color: c.line),
              ),
              child: Icon(Icons.dns_rounded, color: c.text, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(sv?.remark ?? s.t('no_server'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontWeight: FontWeight.w800, color: c.text)),
                  const SizedBox(height: 2),
                  Text(sv != null ? '${sv.protocol} · ${sv.address}' : s.t('tap_to_connect'),
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: c.textDim, fontSize: 12.5)),
                ],
              ),
            ),
            if (sv?.pingMs != null && sv!.pingMs! >= 0)
              Text('${sv.pingMs} ${s.t('ms')}',
                  style: TextStyle(color: c.text, fontWeight: FontWeight.w800)),
          ],
        ),
      ),
    );
  }
}
