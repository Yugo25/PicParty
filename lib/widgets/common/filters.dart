import 'package:flutter/material.dart';
import '../../theme/tokens.dart';

/// A horizontally scrolling row of pill buttons; the selected one is inverted
/// (black on light, white on dark) and scrolled into view when it changes.
class PillFilters<T> extends StatefulWidget {
  final List<T> values;
  final T selected;
  final String Function(T value) labelOf;
  final ValueChanged<T> onSelected;
  final EdgeInsetsGeometry padding;

  /// Stretch the pills to fill the row instead of scrolling.
  final bool expand;

  const PillFilters({
    super.key,
    required this.values,
    required this.selected,
    required this.labelOf,
    required this.onSelected,
    this.padding = Tokens.pagePadding,
    this.expand = false,
  });

  @override
  State<PillFilters<T>> createState() => _PillFiltersState<T>();
}

class _PillFiltersState<T> extends State<PillFilters<T>> with _RevealSelected<T, PillFilters<T>> {
  @override
  T get selected => widget.selected;

  @override
  Widget build(BuildContext context) {
    final pills = [
      for (final v in widget.values)
        Pill(key: keyFor(v), label: widget.labelOf(v), selected: v == widget.selected, onTap: () => widget.onSelected(v)),
    ];
    if (widget.expand) {
      return Padding(
        padding: widget.padding,
        child: Row(children: [
          for (var i = 0; i < pills.length; i++) ...[if (i > 0) const SizedBox(width: 8), Expanded(flex: widget.labelOf(widget.values[i]).length + 6, child: pills[i])],
        ]),
      );
    }
    return SizedBox(
      height: Tokens.pillHeight + 8,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: widget.padding,
        child: Row(children: [
          for (var i = 0; i < pills.length; i++) ...[if (i > 0) const SizedBox(width: 8), pills[i]],
        ]),
      ),
    );
  }
}

/// Scrolls the selected item of a horizontal filter row into view whenever the
/// selection changes from outside (e.g. the filter sheet).
mixin _RevealSelected<T, W extends StatefulWidget> on State<W> {
  final _keys = <Object?, GlobalKey>{};
  T get selected;

  GlobalKey keyFor(T value) => _keys.putIfAbsent(value, GlobalKey.new);

  @override
  void didUpdateWidget(W oldWidget) {
    super.didUpdateWidget(oldWidget);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _keys[selected]?.currentContext;
      if (ctx != null && mounted) {
        Scrollable.ensureVisible(ctx, alignment: 0.5, duration: const Duration(milliseconds: 200), alignmentPolicy: ScrollPositionAlignmentPolicy.explicit);
      }
    });
  }
}

class Pill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const Pill({super.key, required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected ? scheme.onSurface : Colors.transparent,
        shape: StadiumBorder(side: BorderSide(color: selected ? scheme.onSurface : scheme.outline.withValues(alpha: 0.45))),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: Tokens.pillHeight, minWidth: 56),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                widthFactor: 1,
                child: Text(label,
                    overflow: TextOverflow.fade,
                    softWrap: false,
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                      color: selected ? scheme.surface : scheme.onSurface,
                    )),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A quieter, text-only filter row (categories): the selected item is bold
/// and full-contrast, the rest grey.
class TextFilters<T> extends StatefulWidget {
  final List<T> values;
  final T selected;
  final String Function(T value) labelOf;
  final ValueChanged<T> onSelected;

  const TextFilters({super.key, required this.values, required this.selected, required this.labelOf, required this.onSelected});

  @override
  State<TextFilters<T>> createState() => _TextFiltersState<T>();
}

class _TextFiltersState<T> extends State<TextFilters<T>> with _RevealSelected<T, TextFilters<T>> {
  @override
  T get selected => widget.selected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: 40,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: Tokens.gutter - 8),
        child: Row(children: [
          for (final v in widget.values)
            Semantics(
              key: keyFor(v),
              button: true,
              selected: v == widget.selected,
              child: InkWell(
                onTap: () => widget.onSelected(v),
                borderRadius: BorderRadius.circular(Tokens.radiusSmall),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                  child: Text(widget.labelOf(v),
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: v == widget.selected ? FontWeight.w700 : FontWeight.w400,
                        color: v == widget.selected ? scheme.onSurface : scheme.onSurfaceVariant,
                      )),
                ),
              ),
            ),
        ]),
      ),
    );
  }
}

/// Two or more equal segments in a bordered box; the selected one is inverted.
/// Used for "Now / Schedule" and the duration presets.
class SegmentedChoice<T> extends StatelessWidget {
  final List<T> values;
  final T selected;
  final String Function(T value) labelOf;
  final ValueChanged<T> onSelected;

  /// Draw each segment as its own box with gaps (duration presets) instead of
  /// one joined control.
  final bool separated;

  const SegmentedChoice({super.key, required this.values, required this.selected, required this.labelOf, required this.onSelected, this.separated = false});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final border = scheme.outline.withValues(alpha: 0.45);
    Widget segment(T v) {
      final sel = v == selected;
      return Semantics(
        button: true,
        selected: sel,
        inMutuallyExclusiveGroup: true,
        child: Material(
          color: sel ? scheme.onSurface : (separated ? Colors.transparent : Colors.transparent),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Tokens.radius - 2),
            side: separated ? BorderSide(color: sel ? scheme.onSurface : border) : BorderSide.none,
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(Tokens.radius - 2),
            onTap: () => onSelected(v),
            child: SizedBox(
              height: separated ? 44 : 40,
              child: Center(
                child: Text(labelOf(v),
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: sel ? FontWeight.w600 : FontWeight.w400,
                      color: sel ? scheme.surface : scheme.onSurface,
                    )),
              ),
            ),
          ),
        ),
      );
    }

    if (separated) {
      return Row(children: [
        for (var i = 0; i < values.length; i++) ...[if (i > 0) const SizedBox(width: 8), Expanded(child: segment(values[i]))],
      ]);
    }
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainer,
        borderRadius: BorderRadius.circular(Tokens.radius),
        border: Border.all(color: border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(2),
        child: Row(children: [for (final v in values) Expanded(child: segment(v))]),
      ),
    );
  }
}
