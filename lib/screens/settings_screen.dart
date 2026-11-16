import 'package:flutter/material.dart';
import 'dart:io';
import 'package:provider/provider.dart';
import '../l10n/strings.dart';
import '../state/app_state.dart';
import 'about_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final state = context.watch<AppState>();
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: Text(s.t('settings'))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _section(s.t('theme')),
          Card(
            child: Column(children: [
              RadioListTile<ThemeMode>(
                value: ThemeMode.dark,
                groupValue: state.themeMode,
                onChanged: (v) => state.setTheme(v!),
                title: Text(s.t('theme_dark')),
              ),
              RadioListTile<ThemeMode>(
                value: ThemeMode.light,
                groupValue: state.themeMode,
                onChanged: (v) => state.setTheme(v!),
                title: Text(s.t('theme_light')),
              ),
              RadioListTile<ThemeMode>(
                value: ThemeMode.system,
                groupValue: state.themeMode,
                onChanged: (v) => state.setTheme(v!),
                title: Text(s.t('theme_system')),
              ),
            ]),
          ),
          const SizedBox(height: 16),
          _section(s.t('language')),
          Card(
            child: Column(children: [
              RadioListTile<String>(
                value: 'fa',
                groupValue: state.lang,
                onChanged: (v) => state.setLang(v!),
                title: const Text('فارسی'),
              ),
              RadioListTile<String>(
                value: 'en',
                groupValue: state.lang,
                onChanged: (v) => state.setLang(v!),
                title: const Text('English'),
              ),
            ]),
          ),
          const SizedBox(height: 16),
          _section(s.t('settings')),
          Card(
            child: Column(children: [
              SwitchListTile(
                value: state.killSwitch,
                onChanged: (v) => state.setKillSwitch(v),
                title: Text(s.t('kill_switch')),
              ),
              SwitchListTile(
                value: state.proxyOnly,
                onChanged: (v) => state.setProxyOnly(v),
                title: Text(s.t('proxy_only')),
              ),
              if (Platform.isAndroid)
                ListTile(
                  leading: const Icon(Icons.apps),
                  title: Text(s.t('per_app')),
                  subtitle: Text(s.t('per_app_hint')),
                ),
            ]),
          ),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: const Icon(Icons.info_outline),
              title: Text(s.t('about')),
              trailing: const Icon(Icons.chevron_left),
              onTap: () => Navigator.of(context)
                  .push(MaterialPageRoute(builder: (_) => const AboutScreen())),
            ),
          ),
        ],
      ),
    );
  }

  Widget _section(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 8, right: 4, left: 4),
        child: Text(t, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
      );
}
