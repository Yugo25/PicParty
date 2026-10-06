import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/media_post.dart';
import '../models/party.dart';
import '../models/comment.dart';

class DemoStore extends ChangeNotifier {
  DemoStore._(); static final DemoStore instance=DemoStore._();
  final uuid=const Uuid();
  final List<Party> parties=[]; final Map<String,List<MediaPost>> media={}; final Map<String,List<Comment>> comments={};
  final Set<String> likedMedia={}; final Set<String> following={};
  bool initialized=false;
  void init(){if(initialized)return; initialized=true; final now=DateTime.now().toUtc(); final titles=['Tokyo Street Night','Montreal Summer','Food Around Us','Weekend Pets','Urban Photography','Music Together','Sunset Walk','Travel Moments']; for(var i=0;i<titles.length;i++){final s=now.subtract(Duration(minutes:i*8)); final p=Party(id:'demo-$i',ownerId:'demo-owner-$i',title:titles[i],description:'A live PicParty theme. Everyone can join and share a moment.',category:['travel','photography','food','pets','art','music','nature','travel'][i],contentLanguage:'en',countdownStyle:['digital','motor','rock','gothic','sweet','cartoon','dream','cinema'][i],privacy:'public',startAt:s,endAt:s.add(const Duration(hours:2)),status:'live',createdAt:s,lastActivityAt:now.subtract(Duration(minutes:i))); parties.add(p); media[p.id]=[]; comments[p.id]=[];}}
  Party? getParty(String id)=>parties.cast<Party?>().firstWhere((p)=>p?.id==id,orElse:()=>null);
  void addParty(Party p){parties.insert(0,p);media[p.id]=[];comments[p.id]=[];notifyListeners();}
  void addMedia(MediaPost m){media[m.partyId]!.insert(0,m);notifyListeners();}
  void toggleLike(MediaPost m){m.liked=!m.liked;m.likeCount+=(m.liked?1:-1);notifyListeners();}
  void addComment(String partyId,Comment c){comments[partyId]!.add(c);notifyListeners();}
  void toggleFollow(String id){following.contains(id)?following.remove(id):following.add(id);notifyListeners();}
}
