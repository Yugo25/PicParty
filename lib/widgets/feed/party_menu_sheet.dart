import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/feed/feed_party.dart';

/// Copies a Party link and confirms it. Used for "Share" and "Copy link"
/// (there is no native share sheet in this demo).
Future<void> copyPartyLink(BuildContext context, FeedParty party) async {
  final messenger = ScaffoldMessenger.of(context);
  await Clipboard.setData(ClipboardData(text: party.shareUrl));
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(const SnackBar(content: Text('Link copied'), duration: Duration(seconds: 2)));
}

/// The "…" menu of a Party. Features not built yet are shown disabled and
/// labelled, so they are never mistaken for working ones.
Future<void> showPartyMenu(BuildContext context, {required FeedParty party, required VoidCallback onViewParty}) {
  return showModalBottomSheet<void>(
    context: context,
    useSafeArea: true,
    useRootNavigator: true,
    builder: (sheetContext) {
      void close(VoidCallback action) {
        Navigator.of(sheetContext).pop();
        action();
      }

      return SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(leading: const Icon(Icons.open_in_new), title: const Text('View Party'), onTap: () => close(onViewParty)),
            ListTile(leading: const Icon(Icons.link), title: const Text('Copy link'), onTap: () => close(() => copyPartyLink(context, party))),
            const ListTile(enabled: false, leading: Icon(Icons.notifications_none), title: Text('Remind me'), trailing: Text('Coming soon')),
            const ListTile(enabled: false, leading: Icon(Icons.flag_outlined), title: Text('Report'), trailing: Text('Coming soon')),
            const SizedBox(height: 8),
          ],
        ),
      );
    },
  );
}
