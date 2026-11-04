import 'package:flutter/material.dart';

/// A boundary that renders [fallback] when [error] is non-null.
///
/// Use this to wrap route or page content so a failing widget can show a
/// retry UI instead of a red error screen. Errors are set externally (for
/// example by a cubit that catches exceptions), or globally via
/// [installGlobalErrorWidget] in bootstrap.
class ErrorBoundary extends StatefulWidget {
  const ErrorBoundary({
    super.key,
    required this.child,
    required this.fallback,
  });

  final Widget child;
  final Widget Function(Object error, StackTrace stack, VoidCallback onRetry)
      fallback;

  @override
  State<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  Object? _error;
  StackTrace? _stack;

  void setError(Object error, StackTrace stack) {
    _error = error;
    _stack = stack;
    if (mounted) setState(() {});
  }

  void clearError() {
    _error = null;
    _stack = null;
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return widget.fallback(_error!, _stack!, clearError);
    }
    return widget.child;
  }
}

/// Sets a global [ErrorWidget.builder] so unhandled build errors anywhere in
/// the app show a generic fallback instead of a red error screen.
/// Call this once in bootstrap before runApp.
void installGlobalErrorWidget() {
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return Scaffold(
      backgroundColor: const Color(0xFF1C2622),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.redAccent, size: 64),
            const SizedBox(height: 16),
            Text(
              'Une erreur inattendue est survenue.',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () {},
              child: const Text('Fermer'),
            ),
          ],
        ),
      ),
    );
  };
}
