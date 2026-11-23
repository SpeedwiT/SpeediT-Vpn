import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'l10n/strings.dart';
import 'services/storage.dart';
import 'services/vpn/vpn_engine.dart';
import 'state/app_state.dart';
import 'theme/app_colors.dart';
import 'theme/app_theme.dart';
import 'screens/home_screen.dart';
import 'screens/servers_screen.dart';
import 'screens/subscriptions_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/onboarding_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  S.set('fa');
  final storage = await Storage.open();
  final state = AppState(storage, VpnEngine.create());
  await state.init();
  runApp(ChangeNotifierProvider.value(value: state, child: const V2hypeApp()));
}

class V2hypeApp extends StatelessWidget {
  const V2hypeApp({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return MaterialApp(
      title: 'V2hype',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: state.themeMode,
      locale: Locale(state.lang),
      builder: (context, child) => Directionality(
        textDirection: state.lang == 'fa' ? TextDirection.rtl : TextDirection.ltr,
        child: child!,
      ),
      home: state.onboarded ? const RootShell() : const OnboardingScreen(),
    );
  }
}

class RootShell extends StatefulWidget {
  const RootShell({super.key});
  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  int _index = 0;
  static const _pages = [HomeScreen(), ServersScreen(), SubscriptionsScreen(), SettingsScreen()];

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = AppColors.of(context);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: c.isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        body: SafeArea(
          bottom: false,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 320),
            switchInCurve: Curves.easeOutCubic,
            transitionBuilder: (child, anim) => FadeTransition(
              opacity: anim,
              child: SlideTransition(
                position: Tween<Offset>(begin: const Offset(0, 0.02), end: Offset.zero).animate(anim),
                child: child,
              ),
            ),
            child: KeyedSubtree(key: ValueKey(_index), child: _pages[_index]),
          ),
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (i) => setState(() => _index = i),
          destinations: [
            NavigationDestination(
                icon: const Icon(Icons.power_settings_new_rounded), label: s.t('tab_home')),
            NavigationDestination(icon: const Icon(Icons.dns_rounded), label: s.t('tab_servers')),
            NavigationDestination(
                icon: const Icon(Icons.cloud_rounded), label: s.t('tab_subs')),
            NavigationDestination(icon: const Icon(Icons.settings_rounded), label: s.t('tab_settings')),
          ],
        ),
      ),
    );
  }
}
