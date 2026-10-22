import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/feed/feed_party.dart';
import '../../l10n/l10n.dart';

/// Copies a Party link and confirms it. Used for "Share" and "Copy link"
/// (there is no native share sheet in this demo).
Future<void> copyPartyLink(BuildContext context, FeedParty party) async {
  final messenger = ScaffoldMessenger.of(context);
  final copied = context.l10n.linkCopied;
  await Clipboard.setData(ClipboardData(text: party.shareUrl));
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(copied), duration: const Duration(seconds: 2)));
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
            ListTile(leading: const Icon(Icons.open_in_new), title: Text(context.l10n.viewParty), onTap: () => close(onViewParty)),
            ListTile(leading: const Icon(Icons.link), title: Text(context.l10n.copyLink), onTap: () => close(() => copyPartyLink(context, party))),
            ListTile(enabled: false, leading: const Icon(Icons.notifications_none), title: Text(context.l10n.remindMe), trailing: Text(context.l10n.comingSoon)),
            ListTile(enabled: false, leading: const Icon(Icons.flag_outlined), title: Text(context.l10n.report), trailing: Text(context.l10n.comingSoon)),
            const SizedBox(height: 8),
          ],
        ),
      );
    },
  );
}
