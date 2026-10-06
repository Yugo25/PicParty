# 图趴 PicParty 1.0.0

正式产品名：**图趴 PicParty**。这是 Flutter + Supabase 的 iOS / Android 生产源代码工程。

## 运行
```bash
flutter pub get
flutter gen-l10n
flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...
```
未提供 Supabase 参数时进入 Demo Mode。

## 后端
执行 `supabase/migrations/` 中的 migration，并部署 `supabase/functions/`。

## 发布
详见 `docs/APP_STORE_RELEASE.md`。
