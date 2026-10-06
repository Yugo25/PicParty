# 图趴 PicParty 1.0.0 商店发布清单

源码已经包含 Flutter、Android、iOS、Supabase、Edge Functions、数据库 migration 和 7 语言资源。

## 必须由发布方注入的项目级信息
- Apple Team ID / Bundle ID / Signing Certificate / Provisioning Profile
- Google Play application signing / upload key
- Supabase project URL / anon key / database secrets
- APNs key + Firebase Android credentials
- Production storage bucket and RLS policies
- Privacy Policy URL / Terms URL / support URL
- App Store Connect / Google Play listing metadata and screenshots

## 建议发布命令
```bash
flutter clean
flutter pub get
flutter gen-l10n
flutter analyze
flutter test
flutter build appbundle --release --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...
flutter build ipa --release --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...
```

注意：本环境没有 Flutter SDK，因此这里无法声称已经完成真实 iOS/Android 编译、签名和商店审核。
