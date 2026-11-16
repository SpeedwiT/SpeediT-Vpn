import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/strings.dart';
import '../state/app_state.dart';
import '../theme/app_colors.dart';
import '../widgets/ui_kit.dart';
import 'about_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = AppColors.of(context);
    final state = context.watch<AppState>();
    return AnimatedBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(title: Text(s.t('settings'))),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            FadeSlideIn(
              delayMs: 40,
              child: _group(c, s.t('theme'), [
                _radio<ThemeMode>(c, s.t('theme_dark'), ThemeMode.dark, state.themeMode, (v) => state.setTheme(v)),
                _radio<ThemeMode>(c, s.t('theme_light'), ThemeMode.light, state.themeMode, (v) => state.setTheme(v)),
                _radio<ThemeMode>(c, s.t('theme_system'), ThemeMode.system, state.themeMode, (v) => state.setTheme(v)),
              ]),
            ),
            const SizedBox(height: 16),
            FadeSlideIn(
              delayMs: 90,
              child: _group(c, s.t('language'), [
                _radio<String>(c, 'فارسی', 'fa', state.lang, (v) => state.setLang(v)),
                _radio<String>(c, 'English', 'en', state.lang, (v) => state.setLang(v)),
              ]),
            ),
            const SizedBox(height: 16),
            FadeSlideIn(
              delayMs: 140,
              child: _group(c, s.t('settings'), [
                _switch(c, s.t('auto_ping'), state.autoPing, (v) => state.setAutoPing(v),
                    subtitle: s.t('auto_ping_hint')),
                _switch(c, s.t('kill_switch'), state.killSwitch, (v) => state.setKillSwitch(v)),
                _switch(c, s.t('proxy_only'), state.proxyOnly, (v) => state.setProxyOnly(v)),
                if (Platform.isAndroid)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.apps_rounded, color: c.text),
                    title: Text(s.t('per_app'), style: TextStyle(color: c.text, fontWeight: FontWeight.w600)),
                    subtitle: Text(s.t('per_app_hint'), style: TextStyle(color: c.textDim)),
                  ),
              ]),
            ),
            const SizedBox(height: 16),
            FadeSlideIn(
              delayMs: 190,
              child: GlassCard(
                onTap: () => Navigator.of(context).push(FadeScaleRoute(const AboutScreen())),
                child: Row(children: [
                  Icon(Icons.info_outline_rounded, color: c.text),
                  const SizedBox(width: 14),
                  Expanded(child: Text(s.t('about'), style: TextStyle(color: c.text, fontWeight: FontWeight.w700))),
                  Icon(Icons.chevron_right_rounded, color: c.textDim),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _group(AppColors c, String title, List<Widget> children) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8, right: 6, left: 6),
            child: Text(title.toUpperCase(),
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: c.textDim, letterSpacing: 1)),
          ),
          GlassCard(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4), child: Column(children: children)),
        ],
      );

  Widget _radio<T>(AppColors c, String label, T value, T group, void Function(T) onChanged) => RadioListTile<T>(
        value: value,
        groupValue: group,
        onChanged: (v) => onChanged(v as T),
        activeColor: c.accent,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10),
        title: Text(label, style: TextStyle(color: c.text, fontWeight: FontWeight.w600)),
      );

  Widget _switch(AppColors c, String label, bool value, void Function(bool) onChanged,
          {String? subtitle}) =>
      SwitchListTile(
        value: value,
        onChanged: onChanged,
        activeColor: c.onAccent,
        activeTrackColor: c.accent,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10),
        title: Text(label, style: TextStyle(color: c.text, fontWeight: FontWeight.w600)),
        subtitle: subtitle == null
            ? null
            : Text(subtitle, style: TextStyle(color: c.textDim, fontSize: 12)),
      );
}
