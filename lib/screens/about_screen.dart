import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../l10n/strings.dart';
import '../theme/app_theme.dart';

const String kChannel = '@Speedw_IT';
const String kChannelUrl = 'https://t.me/Speedw_IT';
const String kDeveloper = 'Speed iT';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(s.t('about'))),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                gradient: AppTheme.gradient,
                borderRadius: BorderRadius.circular(26),
                boxShadow: [BoxShadow(color: AppTheme.brandBlue.withValues(alpha: 0.5), blurRadius: 30)],
              ),
              child: const Icon(Icons.bolt, color: Colors.white, size: 54),
            ),
          ),
          const SizedBox(height: 16),
          const Center(
            child: Text('SpeediT', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900)),
          ),
          const SizedBox(height: 6),
          Center(child: Text(s.t('about_desc'), textAlign: TextAlign.center)),
          const SizedBox(height: 28),
          Card(
            child: Column(children: [
              FutureBuilder<PackageInfo>(
                future: PackageInfo.fromPlatform(),
                builder: (context, snap) => ListTile(
                  leading: const Icon(Icons.verified_outlined, color: AppTheme.brandBlue),
                  title: Text(s.t('version')),
                  trailing: Text(snap.hasData ? '${snap.data!.version} (${snap.data!.buildNumber})' : '…'),
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.person_outline, color: AppTheme.brandBlue),
                title: Text(s.t('developer')),
                trailing: const Text(kDeveloper),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.send, color: AppTheme.brandBlue),
                title: Text(s.t('channel')),
                subtitle: const Text(kChannel),
                trailing: const Icon(Icons.open_in_new, size: 18),
                onTap: () => launchUrl(Uri.parse(kChannelUrl), mode: LaunchMode.externalApplication),
              ),
            ]),
          ),
          const SizedBox(height: 20),
          Center(
            child: FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: AppTheme.brandBlue),
              onPressed: () => launchUrl(Uri.parse(kChannelUrl), mode: LaunchMode.externalApplication),
              icon: const Icon(Icons.telegram),
              label: Text(s.t('open_channel')),
            ),
          ),
        ],
      ),
    );
  }
}
