import 'package:flutter/material.dart';
import '../../theme/tokens.dart';

/// Keeps the app at phone width on tablets and desktop browsers instead of
/// stretching it: content is centred at [Tokens.maxContentWidth] and every
/// screen below sees that width as the screen size.
class MobileFrame extends StatelessWidget {
  final Widget child;
  const MobileFrame({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    if (mq.size.width <= Tokens.maxContentWidth) return child;
    final theme = Theme.of(context);
    return ColoredBox(
      color: theme.brightness == Brightness.light ? const Color(0xFFF4F4F4) : const Color(0xFF000000),
      child: Center(
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border.symmetric(vertical: BorderSide(color: theme.colorScheme.outlineVariant, width: 0.5)),
          ),
          child: SizedBox(
            width: Tokens.maxContentWidth,
            child: MediaQuery(data: mq.copyWith(size: Size(Tokens.maxContentWidth, mq.size.height)), child: child),
          ),
        ),
      ),
    );
  }
}
