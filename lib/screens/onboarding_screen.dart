import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/strings.dart';
import '../state/app_state.dart';
import '../theme/app_colors.dart';
import '../widgets/ui_kit.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  String _lang = 'fa';

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final state = context.read<AppState>();
    // onboarding shows both languages; labels are intentionally bilingual-neutral.
    return Directionality(
      textDirection: _lang == 'fa' ? TextDirection.rtl : TextDirection.ltr,
      child: AnimatedBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                children: [
                  const Spacer(),
                  FadeSlideIn(
                    child: Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        gradient: c.orbGradient,
                        borderRadius: BorderRadius.circular(26),
                        boxShadow: c.lift,
                      ),
                      child: Icon(Icons.bolt, color: c.onAccent, size: 54),
                    ),
                  ),
                  const SizedBox(height: 22),
                  Text('V2hype',
                      style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: c.text, letterSpacing: -1)),
                  const SizedBox(height: 28),
                  Text(_lang == 'fa' ? 'زبان را انتخاب کنید' : 'Choose your language',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: c.text)),
                  const SizedBox(height: 6),
                  Text(
                      _lang == 'fa'
                          ? 'می‌توانید بعداً از تنظیمات تغییر دهید.'
                          : 'You can change it later in Settings.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: c.textDim)),
                  const SizedBox(height: 28),
                  _langTile(c, 'fa', 'فارسی', '🇮🇷'),
                  const SizedBox(height: 12),
                  _langTile(c, 'en', 'English', '🇬🇧'),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () => state.completeOnboarding(_lang),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: Text(_lang == 'fa' ? 'ادامه' : 'Continue',
                          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _langTile(AppColors c, String code, String label, String flag) {
    final selected = _lang == code;
    return GestureDetector(
      onTap: () => setState(() => _lang = code),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        decoration: BoxDecoration(
          color: selected ? c.accent : c.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: selected ? c.accent : c.line, width: 1.5),
          boxShadow: selected ? c.lift : null,
        ),
        child: Row(
          children: [
            Text(flag, style: const TextStyle(fontSize: 26)),
            const SizedBox(width: 14),
            Expanded(
              child: Text(label,
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: selected ? c.onAccent : c.text)),
            ),
            Icon(selected ? Icons.check_circle_rounded : Icons.circle_outlined,
                color: selected ? c.onAccent : c.textDim),
          ],
        ),
      ),
    );
  }
}
