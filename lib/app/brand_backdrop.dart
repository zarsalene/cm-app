import 'package:cm_app/app/theme.dart';
import 'package:flutter/material.dart';

/// Page background with two soft glows in the logo colours (orange, teal).
class BrandBackdrop extends StatelessWidget {
  const BrandBackdrop({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        ColoredBox(color: context.scheme.surface),
        const Positioned(
          top: -120,
          right: -100,
          child: _Glow(AppColors.logoOrange, 320),
        ),
        const Positioned(
          bottom: -140,
          left: -120,
          child: _Glow(AppColors.logoTeal, 380),
        ),
        child,
      ],
    );
  }
}

class _Glow extends StatelessWidget {
  const _Glow(this.color, this.size);

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color.withValues(alpha: 0.2), color.withValues(alpha: 0)],
          ),
        ),
        child: SizedBox.square(dimension: size),
      ),
    );
  }
}
