import '../models/party.dart';

class DemoService {
  static final now = DateTime.now().toUtc();
  static final parties = List.generate(8, (i) {
    final start = now.subtract(Duration(minutes: i * 8));
    return Party(id:'demo-$i', ownerId:'demo-owner-$i', title:['Tokyo Street Night','Montreal Summer','Food Around Us','Weekend Pets','Urban Photography','Music Together','Sunset Walk','Travel Moments'][i], description:'A live PicParty demo theme. Add your photo and join the party.', category:['travel','photography','food','pets','art','music','nature','travel'][i], contentLanguage:'en', countdownStyle:['digital','motor','rock','gothic','sweet','cartoon','dream','cinema'][i], privacy:'public', startAt:start, endAt:start.add(const Duration(hours:2)), status:'live', createdAt:start, lastActivityAt:now.subtract(Duration(minutes:i)));
  });
}
