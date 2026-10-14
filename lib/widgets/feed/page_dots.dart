import 'package:flutter/material.dart';
import '../../config/feed_config.dart';

/// Page indicator that never shows more than [maxDots] dots: a window slides
/// with the current page, and dots at a cut-off edge are drawn smaller.
class PageDots extends StatelessWidget {
  final int count, index;
  final int maxDots;
  const PageDots({super.key, required this.count, required this.index, this.maxDots = FeedConfig.maxVisibleDots});

  @override
  Widget build(BuildContext context) {
    if (count <= 1) return const SizedBox.shrink();
    final visible = count < maxDots ? count : maxDots;
    final start = (index - visible ~/ 2).clamp(0, count - visible);
    final end = start + visible; // exclusive
    return ExcludeSemantics(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = start; i < end; i++)
            _Dot(
              selected: i == index,
              small: (i == start && start > 0) || (i == end - 1 && end < count),
            ),
        ],
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  final bool selected, small;
  const _Dot({required this.selected, required this.small});

  @override
  Widget build(BuildContext context) {
    final size = small ? 5.0 : 7.0;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      margin: const EdgeInsets.symmetric(horizontal: 3),
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected ? Colors.white : Colors.transparent,
        border: Border.all(color: Colors.white.withValues(alpha: selected ? 1 : 0.85), width: 1.2),
      ),
    );
  }
}
