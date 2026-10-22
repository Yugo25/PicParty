import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../config/app_config.dart';
import '../config/supabase_config.dart';
import '../models/party.dart';
import '../services/demo_service.dart';

class PartyRepository {
  SupabaseClient get _client => SupabaseConfig.client;
  Future<List<Party>> live({int limit=20}) async {
    if (AppConfig.demoMode) return DemoService.parties.take(limit).toList();
    final rows = await _client.rpc('get_discover_live', params:{'p_limit':limit,'p_before':null});
    return List<Map<String,dynamic>>.from(rows).map(Party.fromMap).toList();
  }
  Future<Party> create({required String title, String? description, String? category, required String language, required String style, required String privacy, required DateTime startAt, required int durationMinutes, String? coverStoragePath}) async {
    if (AppConfig.demoMode) {
      final s=startAt.toUtc(); return Party(id:'demo-${const Uuid().v4()}',ownerId:'demo-user',title:title,description:description,category:category,contentLanguage:language,countdownStyle:style,privacy:privacy,startAt:s,endAt:s.add(Duration(minutes:durationMinutes)),status:s.isAfter(DateTime.now().toUtc())?'scheduled':'live',createdAt:DateTime.now().toUtc(),lastActivityAt:DateTime.now().toUtc());
    }
    final row=await _client.rpc('create_party',params:{'p_title':title,'p_description':description,'p_category':category,'p_content_language':language,'p_cover_storage_path':coverStoragePath,'p_countdown_style':style,'p_privacy':privacy,'p_start_at':startAt.toUtc().toIso8601String(),'p_duration_minutes':durationMinutes,'p_client_request_id':const Uuid().v4()});
    return Party.fromMap(Map<String,dynamic>.from(row is List ? row.first : row));
  }
}
