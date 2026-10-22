import 'package:flutter/material.dart';
import '../../models/feed/feed_party.dart';
import '../party/party_grid_card.dart';
import '../party/party_image.dart';
import '../../l10n/l10n.dart';

/// Thumbnail, Party name, contributor count and the menu button.
class PartyHeaderRow extends StatelessWidget {
  final FeedParty party;
  final VoidCallback onOpenParty;
  final VoidCallback onMenu;
  const PartyHeaderRow({super.key, required this.party, required this.onOpenParty, required this.onMenu});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 4, 10),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: onOpenParty,
              child: Row(
                children: [
                  PartyThumbnail(party: party, size: 44),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(party.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600, fontSize: 16)),
                        const SizedBox(height: 1),
                        PartyAudienceText(party: party),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          IconButton(onPressed: onMenu, icon: const Icon(Icons.more_horiz), tooltip: context.l10n.more),
        ],
      ),
    );
  }
}

/// Small square Party thumbnail with slightly rounded corners.
class PartyThumbnail extends StatelessWidget {
  final FeedParty party;
  final double size;
  const PartyThumbnail({super.key, required this.party, required this.size});

  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: SizedBox.square(dimension: size, child: PartyImage(party: party)),
      );
}
