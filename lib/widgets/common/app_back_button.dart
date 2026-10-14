import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Back arrow that also works when a page was opened directly from a link
/// (nothing to go back to): it then returns to Home.
class AppBackButton extends StatelessWidget {
  const AppBackButton({super.key});

  @override
  Widget build(BuildContext context) => IconButton(
        icon: const Icon(Icons.arrow_back),
        tooltip: 'Back',
        onPressed: () => context.canPop() ? context.pop() : context.go('/'),
      );
}
