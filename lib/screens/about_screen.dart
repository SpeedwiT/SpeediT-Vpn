import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../l10n/strings.dart';
import '../theme/app_colors.dart';
import '../widgets/ui_kit.dart';

const String kChannel = '@v2hype';
const String kChannelUrl = 'https://t.me/v2hype';
const String kDeveloper = 'V2hype';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = AppColors.of(context);
    return AnimatedBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(title: Text(s.t('about'))),
        body: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const SizedBox(height: 10),
            FadeSlideIn(
              child: Center(
                child: Container(
                  width: 104,
                  height: 104,
                  decoration: BoxDecoration(
                    gradient: c.orbGradient,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: c.lift,
                  ),
                  child: Icon(Icons.bolt, color: c.onAccent, size: 58),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Text('V2hype',
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: c.text, letterSpacing: -1)),
            ),
            const SizedBox(height: 6),
            Center(child: Text(s.t('about_desc'), textAlign: TextAlign.center, style: TextStyle(color: c.textDim))),
            const SizedBox(height: 28),
            FadeSlideIn(
              delayMs: 120,
              child: GlassCard(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                child: Column(children: [
                  FutureBuilder<PackageInfo>(
                    future: PackageInfo.fromPlatform(),
                    builder: (context, snap) => _row(c, Icons.verified_rounded, s.t('version'),
                        snap.hasData ? '${snap.data!.version} (${snap.data!.buildNumber})' : '…'),
                  ),
                  Divider(height: 1, color: c.line),
                  _row(c, Icons.person_rounded, s.t('developer'), kDeveloper),
                  Divider(height: 1, color: c.line),
                  _row(c, Icons.send_rounded, s.t('channel'), kChannel,
                      onTap: () => launchUrl(Uri.parse(kChannelUrl), mode: LaunchMode.externalApplication)),
                ]),
              ),
            ),
            const SizedBox(height: 22),
            FadeSlideIn(
              delayMs: 200,
              child: Center(
                child: FilledButton.icon(
                  onPressed: () => launchUrl(Uri.parse(kChannelUrl), mode: LaunchMode.externalApplication),
                  icon: const Icon(Icons.telegram_rounded),
                  label: Text(s.t('open_channel')),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Center(child: Text(s.t('copyright'), style: TextStyle(color: c.textDim, fontSize: 12))),
          ],
        ),
      ),
    );
  }

  Widget _row(AppColors c, IconData icon, String title, String value, {VoidCallback? onTap}) => ListTile(
        onTap: onTap,
        leading: Icon(icon, color: c.text),
        title: Text(title, style: TextStyle(color: c.text, fontWeight: FontWeight.w700)),
        trailing: Directionality(
          textDirection: TextDirection.ltr,
          child: Text(value,
              style: TextStyle(color: c.text, fontWeight: FontWeight.w700, fontSize: 14)),
        ),
      );
}
