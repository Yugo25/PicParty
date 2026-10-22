import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../l10n/l10n.dart';

/// Back arrow that also works when a page was opened directly from a link
/// (nothing to go back to): it then returns to Home.
class AppBackButton extends StatelessWidget {
  const AppBackButton({super.key});

  @override
  Widget build(BuildContext context) => IconButton(
        icon: const Icon(Icons.arrow_back),
        tooltip: context.l10n.back,
        onPressed: () => context.canPop() ? context.pop() : context.go('/'),
      );
}
