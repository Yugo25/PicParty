import 'package:flutter/material.dart';
import '../../l10n/l10n.dart';

/// Short, centred message for an empty list.
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? message;
  final Widget? action;

  const EmptyState({super.key, required this.icon, required this.title, this.message, this.action});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 36, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(height: 12),
          Text(title, textAlign: TextAlign.center, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
          if (message != null) ...[
            const SizedBox(height: 6),
            Text(message!, textAlign: TextAlign.center, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          ],
          if (action != null) ...[const SizedBox(height: 16), action!],
        ],
      ),
    );
  }
}

/// Small spinner for first loads and "loading more".
class LoadingState extends StatelessWidget {
  final double padding;
  const LoadingState({super.key, this.padding = 40});

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.all(padding),
        child: Center(
          child: SizedBox.square(dimension: 22, child: CircularProgressIndicator(strokeWidth: 2, semanticsLabel: context.l10n.loading)),
        ),
      );
}

/// A failed load, with a retry button.
class ErrorState extends StatelessWidget {
  final String? message;
  final VoidCallback onRetry;
  const ErrorState({super.key, this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) => EmptyState(
        icon: Icons.cloud_off_outlined,
        title: context.l10n.somethingWentWrong,
        message: message ?? context.l10n.loadFailedDefault,
        action: OutlinedButton(onPressed: onRetry, child: Text(context.l10n.tryAgain)),
      );
}

/// Footer of a paged list: spinner while loading, retry on failure, nothing at the end.
class PagingFooter extends StatelessWidget {
  final bool loading, failed;
  final VoidCallback onRetry;
  const PagingFooter({super.key, required this.loading, required this.failed, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    if (failed) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Center(child: TextButton(onPressed: onRetry, child: Text(context.l10n.loadMoreFailed))),
      );
    }
    if (loading) return const LoadingState(padding: 20);
    return const SizedBox(height: 16);
  }
}
