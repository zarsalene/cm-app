import 'dart:async';

import 'package:cm_app/app/credit_line.dart';
import 'package:cm_app/app/strings.dart';
import 'package:cm_app/app/theme.dart';
import 'package:material_ui/material_ui.dart';

/// Shown while auth is unknown. White: the logos have white backgrounds.
class SplashPage extends StatefulWidget {
  const new({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );
  // Icon: first 600 ms. Wordmark: last 300 ms.
  late final _scale = Tween<double>(begin: 0.8, end: 1).animate(
    CurvedAnimation(
      parent: _controller,
      curve: const Interval(0, 2 / 3, curve: Curves.easeOutBack),
    ),
  );
  late final _iconFade = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0, 2 / 3, curve: Curves.easeOut),
  );
  late final _wordmarkFade = CurvedAnimation(
    parent: _controller,
    curve: const Interval(2 / 3, 1, curve: Curves.easeOut),
  );
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = 1;
    } else {
      unawaited(_controller.forward());
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Light theme in dark mode too: text must read on the white page.
    return Theme(
      data: AppTheme.light,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        FadeTransition(
                          opacity: _iconFade,
                          child: ScaleTransition(
                            scale: _scale,
                            child: Image.asset(
                              'assets/logo/icon_1024.png',
                              width: 160,
                              semanticLabel: Strings.appName,
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        FadeTransition(
                          opacity: _wordmarkFade,
                          child: Image.asset(
                            'assets/logo/wordmark.png',
                            width: 240,
                            excludeFromSemantics: true,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(bottom: AppSpacing.lg),
                child: CreditLine(logoHeight: 56),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
