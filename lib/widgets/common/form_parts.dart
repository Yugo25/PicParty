import 'package:flutter/material.dart';
import '../../theme/tokens.dart';

/// Search box used in Explore and Inbox: rounded, with a clear button.
class AppSearchField extends StatefulWidget {
  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onChanged;
  final bool autofocus;
  final FocusNode? focusNode;

  const AppSearchField({super.key, required this.controller, required this.hint, required this.onChanged, this.autofocus = false, this.focusNode});

  @override
  State<AppSearchField> createState() => _AppSearchFieldState();
}

class _AppSearchFieldState extends State<AppSearchField> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_changed);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_changed);
    super.dispose();
  }

  void _changed() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    return TextField(
      controller: widget.controller,
      focusNode: widget.focusNode,
      autofocus: widget.autofocus,
      onChanged: widget.onChanged,
      textInputAction: TextInputAction.search,
      style: const TextStyle(fontSize: 16),
      decoration: InputDecoration(
        hintText: widget.hint,
        filled: dark,
        fillColor: theme.colorScheme.surfaceContainer,
        contentPadding: const EdgeInsets.symmetric(vertical: 13),
        prefixIcon: Icon(Icons.search, color: theme.colorScheme.onSurfaceVariant),
        suffixIcon: widget.controller.text.isEmpty
            ? null
            : IconButton(
                tooltip: 'Clear search',
                icon: const Icon(Icons.close, size: 20),
                onPressed: () {
                  widget.controller.clear();
                  widget.onChanged('');
                },
              ),
      ),
    );
  }
}

/// A form label that stays visible above its input (not a disappearing hint).
class FieldLabel extends StatelessWidget {
  final String text;
  final String? trailing;
  const FieldLabel(this.text, {super.key, this.trailing});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Expanded(child: Text(text, style: theme.textTheme.bodyMedium?.copyWith(fontSize: 15, fontWeight: FontWeight.w500))),
          if (trailing != null) Text(trailing!, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}

/// Inline validation message shown right under the input it belongs to.
class FieldError extends StatelessWidget {
  final String? message;
  const FieldError(this.message, {super.key});

  @override
  Widget build(BuildContext context) {
    if (message == null) return const SizedBox.shrink();
    final color = Theme.of(context).colorScheme.error;
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Semantics(
        liveRegion: true,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.error_outline, size: 16, color: color),
            const SizedBox(width: 6),
            Expanded(child: Text(message!, style: TextStyle(color: color, fontSize: 13))),
          ],
        ),
      ),
    );
  }
}

/// Full-width primary button pinned to the bottom of a flow, above the
/// keyboard and the home indicator.
class BottomActionBar extends StatelessWidget {
  final Widget child;
  final Widget? above;
  const BottomActionBar({super.key, required this.child, this.above});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.only(bottom: 8),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(Tokens.gutter, 8, Tokens.gutter, 4),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            if (above != null) above!,
            SizedBox(height: Tokens.controlHeight + 4, child: child),
          ]),
        ),
      ),
    );
  }
}
