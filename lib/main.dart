import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'l10n/strings.dart';
import 'services/storage.dart';
import 'services/vpn/vpn_engine.dart';
import 'state/app_state.dart';
import 'theme/app_theme.dart';
import 'screens/home_screen.dart';
import 'screens/servers_screen.dart';
import 'screens/subscriptions_screen.dart';
import 'screens/settings_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  S.set('fa');
  final storage = await Storage.open();
  final state = AppState(storage, VpnEngine.create());
  await state.init();
  runApp(ChangeNotifierProvider.value(value: state, child: const SpeediTApp()));
}

class SpeediTApp extends StatelessWidget {
  const SpeediTApp({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return MaterialApp(
      title: 'SpeediT',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: state.themeMode,
      locale: Locale(state.lang),
      builder: (context, child) => Directionality(
        textDirection: state.lang == 'fa' ? TextDirection.rtl : TextDirection.ltr,
        child: child!,
      ),
      home: const RootShell(),
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

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    const pages = [HomeScreen(), ServersScreen(), SubscriptionsScreen(), SettingsScreen()];
    return Scaffold(
      body: SafeArea(child: pages[_index]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: [
          NavigationDestination(icon: const Icon(Icons.power_settings_new), label: s.t('tab_home')),
          NavigationDestination(icon: const Icon(Icons.dns_outlined), label: s.t('tab_servers')),
          NavigationDestination(icon: const Icon(Icons.cloud_download_outlined), label: s.t('tab_subs')),
          NavigationDestination(icon: const Icon(Icons.settings_outlined), label: s.t('tab_settings')),
        ],
      ),
    );
  }
}
