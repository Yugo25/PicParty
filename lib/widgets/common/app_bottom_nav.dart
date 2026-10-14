import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/inbox/inbox_repository.dart';

class _NavItem {
  final String label, path;
  final IconData icon, selectedIcon;
  final bool push;
  const _NavItem(this.label, this.path, this.icon, this.selectedIcon, {this.push = false});
}

const _navItems = [
  _NavItem('Home', '/', Icons.home_outlined, Icons.home),
  _NavItem('Explore', '/discover', Icons.explore_outlined, Icons.explore),
  _NavItem('Create', '/create', Icons.add_circle_outline, Icons.add_circle, push: true),
  _NavItem('Inbox', '/activity', Icons.chat_bubble_outline, Icons.chat_bubble),
  _NavItem('Profile', '/profile', Icons.person_outline, Icons.person),
];

/// Bottom navigation: Home / Explore / Create / Inbox / Profile, above the
/// device's safe area so nothing is hidden behind the home indicator.
/// Create opens as a full-screen flow without this bar.
class AppBottomNav extends StatelessWidget {
  final String currentPath;
  const AppBottomNav({super.key, required this.currentPath});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(color: scheme.surface, border: Border(top: BorderSide(color: scheme.outlineVariant, width: 0.5))),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 56,
          child: Row(
            children: [
              for (final item in _navItems)
                Expanded(child: _NavButton(item: item, selected: !item.push && item.path == currentPath)),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  final _NavItem item;
  final bool selected;
  const _NavButton({required this.item, required this.selected});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = selected ? scheme.onSurface : scheme.onSurfaceVariant;
    final inbox = item.path == '/activity';
    final repo = InboxRepository.instance;
    final icon = Icon(selected ? item.selectedIcon : item.icon, color: selected ? scheme.onSurface : scheme.onSurface.withValues(alpha: 0.85), size: 26);
    return ListenableBuilder(
      // Only the Inbox item shows the unread dot.
      listenable: inbox ? repo : const AlwaysStoppedAnimation(0),
      builder: (context, _) => Semantics(
        button: true,
        selected: selected,
        label: inbox && repo.hasUnread ? '${item.label}, new activity' : item.label,
        child: InkResponse(
          onTap: () => item.push ? context.push(item.path) : context.go(item.path),
          child: ExcludeSemantics(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                inbox ? Badge(isLabelVisible: repo.hasUnread, smallSize: 8, backgroundColor: const Color(0xFFE5484D), child: icon) : icon,
                const SizedBox(height: 2),
                Text(item.label, style: TextStyle(fontSize: 11, color: color, fontWeight: selected ? FontWeight.w600 : FontWeight.w400)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
