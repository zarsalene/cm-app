import 'package:cm_app/app/strings.dart';
import 'package:flutter/material.dart';

/// Soft pulsing dot: shows that the list refreshes by itself.
class LiveDot extends StatefulWidget {
  const LiveDot({required this.color, this.size = 8, super.key});

  final Color color;
  final double size;

  @override
  State<LiveDot> createState() => _LiveDotState();
}

class _LiveDotState extends State<LiveDot> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final box = widget.size * 2.6;
    return Semantics(
      label: Strings.liveLabel,
      excludeSemantics: true,
      child: SizedBox.square(
        dimension: box,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final ring = widget.size + (box - widget.size) * _controller.value;
            return Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: ring,
                  height: ring,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: widget.color.withValues(
                      alpha: 0.35 * (1 - _controller.value),
                    ),
                  ),
                ),
                Container(
                  width: widget.size,
                  height: widget.size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: widget.color,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Refresh button that spins one turn on each tap.
class SpinRefreshButton extends StatefulWidget {
  const SpinRefreshButton({required this.onPressed, super.key});

  final VoidCallback onPressed;

  @override
  State<SpinRefreshButton> createState() => _SpinRefreshButtonState();
}

class _SpinRefreshButtonState extends State<SpinRefreshButton> {
  int _turns = 0;

  @override
  Widget build(BuildContext context) {
    final still = MediaQuery.disableAnimationsOf(context);
    return IconButton(
      tooltip: Strings.refresh,
      icon: AnimatedRotation(
        turns: _turns.toDouble(),
        duration: still ? Duration.zero : const Duration(milliseconds: 600),
        curve: Curves.easeOutCubic,
        child: const Icon(Icons.refresh),
      ),
      onPressed: () {
        setState(() => _turns++);
        widget.onPressed();
      },
    );
  }
}
