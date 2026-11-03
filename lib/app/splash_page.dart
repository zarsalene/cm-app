import 'package:cm_app/app/brand_backdrop.dart';
import 'package:cm_app/app/credit_line.dart';
import 'package:cm_app/app/strings.dart';
import 'package:cm_app/app/theme.dart';
import 'package:flutter/material.dart';

/// How long the splash plays. `SplashGate` holds the route for this time.
const splashDuration = Duration(milliseconds: 3600);

/// Shown while auth is unknown: logo-colour backdrop, logo, title, tagline
/// and a progress bar that fills over [splashDuration].
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with TickerProviderStateMixin {
  late final AnimationController _intro = AnimationController(
    vsync: this,
    duration: splashDuration,
  );
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  );

  Animation<double> _stage(double begin, double end, [Curve? curve]) =>
      CurvedAnimation(
        parent: _intro,
        curve: Interval(begin, end, curve: curve ?? Curves.easeOut),
      );

  late final Animation<double> _logoFade = _stage(0, 0.2);
  late final Animation<double> _logoScale = Tween<double>(
    begin: 0.6,
    end: 1,
  ).animate(_stage(0, 0.3, Curves.easeOutBack));
  late final Animation<double> _titleFade = _stage(0.28, 0.5);
  late final Animation<double> _tagFade = _stage(0.45, 0.65);
  late final Animation<double> _creditFade = _stage(0.6, 0.8);
  late final Animation<double> _progress = _stage(
    0.05,
    1,
    Curves.easeInOutCubic,
  );
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (MediaQuery.disableAnimationsOf(context)) {
      _intro.value = 1;
    } else {
      _intro.forward();
      _pulse.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _intro.dispose();
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return Theme(
      data: AppTheme.light(),
      child: Builder(
        builder: (context) {
          final theme = Theme.of(context);
          final scheme = theme.colorScheme;
          return Scaffold(
            body: BrandBackdrop(
              child: SafeArea(
                child: Column(
                  children: [
                    Expanded(
                      child: Center(
                        child: SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              FadeTransition(
                                opacity: _logoFade,
                                child: ScaleTransition(
                                  scale: _logoScale,
                                  child: AnimatedBuilder(
                                    animation: _pulse,
                                    builder: (context, child) => DecoratedBox(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(32),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Color.lerp(
                                              AppColors.logoTeal,
                                              AppColors.logoOrange,
                                              _pulse.value,
                                            )!.withValues(alpha: 0.28),
                                            blurRadius: 32 + 24 * _pulse.value,
                                            spreadRadius: 2,
                                          ),
                                        ],
                                      ),
                                      child: child,
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(32),
                                      child: Image.asset(
                                        'assets/logo/icon_1024.png',
                                        width: 128,
                                        height: 128,
                                        fit: BoxFit.cover,
                                        semanticLabel: Strings.appName,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xl),
                              FadeTransition(
                                opacity: _titleFade,
                                child: SlideTransition(
                                  position: Tween<Offset>(
                                    begin: const Offset(0, 0.3),
                                    end: Offset.zero,
                                  ).animate(_titleFade),
                                  child: Text(
                                    Strings.appName,
                                    style: theme.textTheme.headlineMedium
                                        ?.copyWith(
                                          color: scheme.primary,
                                          fontSize: 32,
                                          letterSpacing: -0.5,
                                        ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              FadeTransition(
                                opacity: _tagFade,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppSpacing.xl,
                                  ),
                                  child: Text(
                                    Strings.tagline,
                                    textAlign: TextAlign.center,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: scheme.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                              ),
                              if (!reduceMotion) ...[
                                const SizedBox(height: AppSpacing.xl * 1.5),
                                ExcludeSemantics(
                                  child: SizedBox(
                                    width: 200,
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(2),
                                      child: AnimatedBuilder(
                                        animation: _progress,
                                        builder: (context, _) =>
                                            LinearProgressIndicator(
                                              value: _progress.value,
                                              minHeight: 3,
                                              backgroundColor: scheme.primary
                                                  .withValues(alpha: 0.14),
                                              valueColor:
                                                  const AlwaysStoppedAnimation<
                                                    Color
                                                  >(AppColors.logoOrange),
                                            ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                    FadeTransition(
                      opacity: _creditFade,
                      child: const Padding(
                        padding: EdgeInsets.fromLTRB(
                          AppSpacing.pageGutter,
                          0,
                          AppSpacing.pageGutter,
                          AppSpacing.lg,
                        ),
                        child: CreditLine(logoHeight: 24),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
