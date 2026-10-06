import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../config/app_config.dart';
import '../config/supabase_config.dart';
class PushService { PushService._(); static final instance=PushService._(); Future<void> init() async { if(kIsWeb||AppConfig.demoMode)return; try { await Firebase.initializeApp(); final m=FirebaseMessaging.instance; await m.requestPermission(alert:true,badge:true,sound:true); final token=await m.getToken(); if(token!=null && SupabaseConfig.client.auth.currentUser!=null){await SupabaseConfig.client.from('user_devices').upsert({'user_id':SupabaseConfig.client.auth.currentUser!.id,'platform':defaultTargetPlatform==TargetPlatform.iOS?'ios':'android','push_token':token,'updated_at':DateTime.now().toUtc().toIso8601String()});}} catch (_) {} }}
