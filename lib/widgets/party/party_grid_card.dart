import 'package:flutter/material.dart';
import '../../core/time_format.dart';
import '../../models/countdown.dart';
import '../../models/feed/feed_party.dart';
import '../../models/feed/party_options.dart';
import '../../theme/tokens.dart';
import '../countdown/clock_builder.dart';
import '../countdown/phase_builder.dart';
import 'party_image.dart';
import '../../l10n/l10n.dart';

const _shadow = [Shadow(color: Color(0x73000000), blurRadius: 6)];
const _tabular = [FontFeature.tabularFigures()];

/// Bottom-up dark gradient behind white text on photos.
const photoScrim = DecoratedBox(
  decoration: BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      stops: [0.35, 1],
      colors: [Color(0x00000000), Color(0xA6000000)],
    ),
  ),
);

/// Party card for 2-column grids (Explore, Profile): the photo with the timer
/// on it, then the name and how many people are in.
class PartyGridCard extends StatelessWidget {
  final FeedParty party;
  final VoidCallback onTap;
  final VoidCallback? onMenu;

  const PartyGridCard({super.key, required this.party, required this.onTap, this.onMenu});

  /// Height of one card in a grid column [width] wide (photo is 4:3).
  static double extentFor(BuildContext context, double width) => width * 3 / 4 + MediaQuery.textScalerOf(context).scale(52) + 6;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      container: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Tokens.radius),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AspectRatio(
              aspectRatio: 4 / 3,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(Tokens.radius),
                child: Stack(fit: StackFit.expand, children: [
                  PartyImage(party: party),
                  const IgnorePointer(child: photoScrim),
                  if (party.category != null) Positioned(top: 8, left: 8, child: CategoryTag(PartyCategories.label(party.category!))),
                  Positioned(left: 10, right: 10, bottom: 8, child: CardCountdown(startAt: party.startAt, endAt: party.endAt)),
                ]),
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: Text(party.title,
                      maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.titleMedium?.copyWith(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
                if (onMenu != null)
                  SizedBox.square(
                    dimension: 32,
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      onPressed: onMenu,
                      icon: const Icon(Icons.more_horiz, size: 20),
                      tooltip: context.l10n.moreOptionsFor(party.title),
                    ),
                  ),
              ],
            ),
            PartyAudienceText(party: party),
          ],
        ),
      ),
    );
  }
}

/// Small translucent category label on a photo.
class CategoryTag extends StatelessWidget {
  final String label;
  const CategoryTag(this.label, {super.key});

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(color: const Color(0x8C000000), borderRadius: BorderRadius.circular(Tokens.radiusSmall)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
          child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500)),
        ),
      );
}

/// Compact timer for cards: `LEFT 01:59:34`, `STARTS IN 02:00:00`, or
/// `Uploads closed · View memories` once ended. Only this text rebuilds per tick.
class CardCountdown extends StatelessWidget {
  final DateTime startAt, endAt;
  const CardCountdown({super.key, required this.startAt, required this.endAt});

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: ClockBuilder(builder: (context, now) {
        final snap = CountdownSnapshot.at(start: startAt, end: endAt, now: now);
        if (snap.phase == CountdownPhase.closed) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(context.l10n.uploadsClosed, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700, shadows: _shadow)),
              ),
              const SizedBox(height: 2),
              Row(mainAxisSize: MainAxisSize.min, children: [
                Text(context.l10n.viewMemories, style: const TextStyle(color: Colors.white, fontSize: 13, shadows: _shadow)),
                const SizedBox(width: 4),
                const Icon(Icons.arrow_forward, size: 14, color: Colors.white),
              ]),
            ],
          );
        }
        final label = snap.phase == CountdownPhase.upcoming ? context.l10n.cardStartsIn : context.l10n.cardLeft;
        final time = CountdownSnapshot.formatCompact(snap.remaining);
        return Semantics(
          label: snap.phase == CountdownPhase.upcoming ? context.l10n.startsInSemantics(time) : context.l10n.timeLeftSemantics(time),
          child: ExcludeSemantics(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(label, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.6, shadows: _shadow)),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(time,
                      maxLines: 1,
                      style: const TextStyle(
                          color: Colors.white, fontSize: 30, height: 1.1, fontWeight: FontWeight.w700, fontFeatures: _tabular, shadows: _shadow)),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}

/// "128 contributors" once people are posting; "42 members" before the start
/// (or while nobody has posted), so people who haven't contributed are never
/// counted as contributors.
class PartyAudienceText extends StatelessWidget {
  final FeedParty party;
  final TextStyle? style;
  const PartyAudienceText({super.key, required this.party, this.style});

  static String label(FeedParty party, CountdownPhase phase) {
    final l = L10n.current;
    if (phase == CountdownPhase.upcoming || party.contributorCount == 0) return l.memberCount(party.memberCount);
    return l.contributorCount(party.contributorCount);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PhaseBuilder(
      startAt: party.startAt,
      endAt: party.endAt,
      builder: (context, phase) => Text(
        label(party, phase),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: style ?? theme.textTheme.bodySmall?.copyWith(fontSize: 13, color: theme.colorScheme.onSurfaceVariant),
      ),
    );
  }
}

/// An ended Party, kept as a memory: photo, name and end date. No countdown.
class MemoryCard extends StatelessWidget {
  final FeedParty party;
  final VoidCallback onTap;
  final double aspectRatio;
  const MemoryCard({super.key, required this.party, required this.onTap, this.aspectRatio = 4 / 3});

  static double extentFor(BuildContext context, double width, {double aspectRatio = 4 / 3}) =>
      width / aspectRatio + MediaQuery.textScalerOf(context).scale(46) + 8;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final n = party.posts.length;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(Tokens.radius),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AspectRatio(
            aspectRatio: aspectRatio,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(Tokens.radius),
              child: Stack(fit: StackFit.expand, children: [
                PartyImage(party: party),
                const IgnorePointer(child: photoScrim),
                Positioned(
                  left: 10,
                  bottom: 8,
                  child: Text(context.l10n.uploadsClosed, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600, shadows: _shadow)),
                ),
              ]),
            ),
          ),
          const SizedBox(height: 6),
          Text(party.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.titleMedium?.copyWith(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text('${TimeFormat.date(party.endAt)} · ${context.l10n.memoryCount(n)}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(fontSize: 13, color: theme.colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}
