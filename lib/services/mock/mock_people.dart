import '../../models/feed/feed_author.dart';

/// Demo people shared by the mock feed, explore, inbox and profile data.
/// Nothing here is real user data.
class MockPeople {
  MockPeople._();

  /// The signed-in demo account. Matches the id returned by
  /// `ProfileRepository.current()` in demo mode.
  static const meId = 'demo-user';
  static const me = FeedAuthor(id: meId, username: 'picparty_demo', displayName: 'PicParty Demo');

  static const sarah = FeedAuthor(id: 'u1', username: 'sarah.k', displayName: 'Sarah Kim', avatarUrl: 'https://picsum.photos/id/64/96/96');
  static const kenji = FeedAuthor(id: 'u2', username: 'kenji.mori', displayName: 'Kenji Mori', avatarUrl: 'https://picsum.photos/id/91/96/96');
  static const maya = FeedAuthor(id: 'u3', username: 'maya.lee', displayName: 'Maya Lee', avatarUrl: 'https://picsum.photos/id/65/96/96');
  static const alex = FeedAuthor(id: 'u4', username: 'alex.chen', displayName: 'Alex Chen', avatarUrl: 'https://picsum.photos/id/338/96/96');
  static const aiko = FeedAuthor(id: 'u5', username: 'aiko_t', displayName: 'Aiko Tanaka', avatarUrl: 'https://picsum.photos/id/1027/96/96');
  static const daniel = FeedAuthor(id: 'u6', username: 'daniel.park', displayName: 'Daniel Park', avatarUrl: 'https://picsum.photos/id/1005/96/96');
  static const lena = FeedAuthor(id: 'u7', username: 'lena', displayName: 'Lena Vogel');
  static const priya = FeedAuthor(id: 'u8', username: 'priya.shah', displayName: 'Priya Shah');
  static const theo = FeedAuthor(id: 'u9', username: 'theo', displayName: 'Theo Martin');
  static const yuto = FeedAuthor(id: 'u10', username: 'yuto.m', displayName: 'Yuto Mori');

  /// Everyone except [me], in a stable order.
  static const others = [sarah, kenji, maya, alex, aiko, daniel, lena, priya, theo, yuto];

  /// Short bios for profile pages.
  static const bios = {
    'u1': 'Collecting moments, together.',
    'u2': 'Street, light, and long walks.',
    'u3': 'Hosting small Parties for big evenings.',
    'u4': 'Weekend trails and coffee.',
    'u5': 'Film photos from Kyoto.',
    'u6': 'Sunsets, mostly.',
  };

  static FeedAuthor? byId(String id) {
    if (id == meId) return me;
    for (final p in others) {
      if (p.id == id) return p;
    }
    return null;
  }
}
