import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/app_config.dart';
import '../config/supabase_config.dart';
import '../models/profile.dart';
class ProfileRepository {
  SupabaseClient get _client=>SupabaseConfig.client;
  Future<Profile?> current() async { if(AppConfig.demoMode)return const Profile(id:'demo-user',username:'picparty_demo',displayName:'PicParty Demo',bio:'Testing 图趴 PicParty 1.0',preferredLanguage:'en',preferredTimezone:'America/Toronto',onboardingCompleted:true); final u=_client.auth.currentUser; if(u==null)return null; final row=await _client.from('profiles').select().eq('id',u.id).maybeSingle(); return row==null?null:Profile.fromMap(row); }
  Future<void> update({required String username, String? displayName, String? bio, required String language, required String timezone}) async { if(AppConfig.demoMode)return; await _client.rpc('update_my_profile',params:{'p_username':username,'p_display_name':displayName,'p_bio':bio,'p_website_url':null,'p_location_text':null,'p_preferred_language':language,'p_preferred_timezone':timezone}); }
}
