import '../../l10n/l10n.dart';
/// Who can find and open a Party. Stored as its [name] (`public`, `unlisted`,
/// `private`), matching the `privacy` column used by [Party].
enum PartyPrivacy {
  /// Shown in search and discovery.
  public,

  /// Hidden from search and discovery; anyone with the link can open it.
  unlisted,

  /// Only the host and approved / invited members can open it. A link alone
  /// is not enough.
  private;

  String get label => switch (this) {
        PartyPrivacy.public => L10n.current.privacyPublic,
        PartyPrivacy.unlisted => L10n.current.privacyUnlisted,
        PartyPrivacy.private => L10n.current.privacyPrivate,
      };

  String get description => switch (this) {
        PartyPrivacy.public => L10n.current.privacyPublicDescription,
        PartyPrivacy.unlisted => L10n.current.privacyUnlistedDescription,
        PartyPrivacy.private => L10n.current.privacyPrivateDescription,
      };

  static PartyPrivacy parse(String? value) =>
      PartyPrivacy.values.firstWhere((p) => p.name == value, orElse: () => PartyPrivacy.public);
}

/// How the Party timer is drawn on the photo. Stored as its [name] in the
/// Party's `countdown_style`.
enum TimerStyle {
  /// Hours, minutes and seconds: `06:00:00`.
  digital,

  /// Short remaining time: `6h`, `5h 59m`.
  minimal,

  /// A ring showing how much of the Party's duration is left.
  ring;

  String get label => switch (this) {
        TimerStyle.digital => L10n.current.timerDigital,
        TimerStyle.minimal => L10n.current.timerMinimal,
        TimerStyle.ring => L10n.current.timerRing,
      };

  /// Older styles (motor, gothic, …) fall back to digital.
  static TimerStyle parse(String? value) => TimerStyle.values.firstWhere((s) => s.name == value, orElse: () => TimerStyle.digital);
}

/// Party categories. Ids match the values the backend already accepts.
class PartyCategories {
  PartyCategories._();

  static const ids = [
    'travel',
    'food',
    'music',
    'nature',
    'photography',
    'pets',
    'art',
    'sports',
    'fashion',
    'party',
    'lifestyle',
    'other',
  ];

  static String label(String id) {
    final l = L10n.current;
    return switch (id) {
      'travel' => l.categoryTravel,
      'food' => l.categoryFood,
      'music' => l.categoryMusic,
      'nature' => l.categoryNature,
      'photography' => l.categoryPhotography,
      'pets' => l.categoryPets,
      'art' => l.categoryArt,
      'sports' => l.categorySports,
      'fashion' => l.categoryFashion,
      'party' => l.categoryParty,
      'lifestyle' => l.categoryLifestyle,
      'other' => l.categoryOther,
      _ => id.isEmpty ? id : id[0].toUpperCase() + id.substring(1),
    };
  }
}

/// Valid range for a Party's length, shared by the create form and the backend
/// limits (1 minute – 30 days).
class PartyLimits {
  PartyLimits._();

  static const minDuration = Duration(minutes: 1);
  static const maxDuration = Duration(days: 30);
  static const titleMax = 80;
  static const descriptionMax = 500;

  /// How far ahead a Party may be scheduled.
  static const maxScheduleAhead = Duration(days: 365);
}
