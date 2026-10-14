/// Who can find and open a Party. Stored as its [name] (`public`, `unlisted`,
/// `private`), matching the `privacy` column used by [Party].
enum PartyPrivacy {
  /// Shown in search and discovery.
  public('Public', 'Discoverable by everyone'),

  /// Hidden from search and discovery; anyone with the link can open it.
  unlisted('Unlisted', 'Anyone with the link'),

  /// Only the host and approved / invited members can open it. A link alone
  /// is not enough.
  private('Private', 'Approved members only');

  final String label, description;
  const PartyPrivacy(this.label, this.description);

  static PartyPrivacy parse(String? value) =>
      PartyPrivacy.values.firstWhere((p) => p.name == value, orElse: () => PartyPrivacy.public);
}

/// How the Party timer is drawn on the photo. Stored as its [name] in the
/// Party's `countdown_style`.
enum TimerStyle {
  /// Hours, minutes and seconds: `06:00:00`.
  digital('Digital'),

  /// Short remaining time: `6h`, `5h 59m`.
  minimal('Minimal'),

  /// A ring showing how much of the Party's duration is left.
  ring('Ring');

  final String label;
  const TimerStyle(this.label);

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

  static String label(String id) => id.isEmpty ? id : id[0].toUpperCase() + id.substring(1);
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
