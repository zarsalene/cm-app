import 'package:cm_app/app/credit_line.dart';
import 'package:cm_app/app/strings.dart';
import 'package:cm_app/app/theme.dart';
import 'package:flutter/material.dart';

/// Shown while auth is unknown. White: the logos have white backgrounds.
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );
  late final Animation<double> _scale = Tween<double>(begin: 0.8, end: 1)
      .animate(
        CurvedAnimation(
          parent: _controller,
          curve: const Interval(0, 2 / 3, curve: Curves.easeOutBack),
        ),
      );
  late final Animation<double> _wordmarkOpacity = CurvedAnimation(
    parent: _controller,
    curve: const Interval(2 / 3, 1, curve: Curves.easeOut),
  );
  late final Animation<double> _wordmarkSlide = Tween<double>(begin: 12, end: 0)
      .animate(
        CurvedAnimation(
          parent: _controller,
          curve: const Interval(2 / 3, 1, curve: Curves.easeOut),
        ),
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
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppTheme.light(),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: Stack(
                  children: [
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: 200,
                        decoration: BoxDecoration(
                          gradient: RadialGradient(
                            center: Alignment.bottomCenter,
                            radius: 0.9,
                            colors: [
                              AppColors.deepTeal.withValues(alpha: 0.04),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                    Center(
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ScaleTransition(
                              scale: _scale,
                              child: Image.asset(
                                'assets/logo/icon_1024.png',
                                width: 110,
                                semanticLabel: Strings.appName,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            SlideTransition(
                              position: Tween<Offset>(
                                begin: const Offset(0, 0.2),
                                end: Offset.zero,
                              ).animate(_wordmarkSlide),
                              child: FadeTransition(
                                opacity: _wordmarkOpacity,
                                child: Image.asset(
                                  'assets/logo/wordmark.png',
                                  width: 240,
                                  excludeFromSemantics: true,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (!MediaQuery.disableAnimationsOf(context))
                      Positioned(
                        bottom: 130,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: SizedBox(
                            width: 200,
                            height: 3,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(2),
                              child: LinearProgressIndicator(
                                minHeight: 3,
                                backgroundColor: AppColors.deepTeal.withValues(
                                  alpha: 0.12,
                                ),
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  AppColors.lightAccent,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(bottom: AppSpacing.lg),
                child: CreditLine(logoHeight: 24),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
