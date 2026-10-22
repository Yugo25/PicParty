import 'package:flutter/material.dart';

/// Equal-width text tabs with an underline under the selected one, followed by
/// a hairline divider. Used by Home, Explore, Create, Inbox and Profile.
///
/// Tabs switch on tap only, so they never compete with horizontal swipes in
/// the content below.
class UnderlineTabs<T> extends StatelessWidget {
  final List<T> values;
  final T selected;
  final String Function(T value) labelOf;
  final ValueChanged<T> onSelected;
  final double height;
  final double fontSize;

  /// Horizontal inset of the underline inside each tab.
  final double indicatorInset;

  const UnderlineTabs({
    super.key,
    required this.values,
    required this.selected,
    required this.labelOf,
    required this.onSelected,
    this.height = 44,
    this.fontSize = 15,
    this.indicatorInset = 16,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            for (final v in values)
              Expanded(
                child: _Tab(
                  label: labelOf(v),
                  selected: v == selected,
                  height: height,
                  fontSize: fontSize,
                  inset: indicatorInset,
                  onTap: () => onSelected(v),
                ),
              ),
          ],
        ),
        const Divider(),
      ],
    );
  }
}

class _Tab extends StatelessWidget {
  final String label;
  final bool selected;
  final double height, fontSize, inset;
  final VoidCallback onTap;
  const _Tab({required this.label, required this.selected, required this.height, required this.fontSize, required this.inset, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      selected: selected,
      button: true,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: height,
          child: Stack(
            children: [
              Center(
                child: Text(label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: fontSize,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                      color: selected ? scheme.onSurface : scheme.onSurfaceVariant,
                    )),
              ),
              if (selected) Positioned(left: inset, right: inset, bottom: 0, child: Container(height: 2, color: scheme.onSurface)),
            ],
          ),
        ),
      ),
    );
  }
}
