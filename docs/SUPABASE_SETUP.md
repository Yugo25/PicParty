# Supabase（サーバー）を準備する手順

今の PicParty は「デモモード」で動いていて、データはその端末の中だけにあります。
再読み込みすると消えますし、友達と写真を共有することもできません。

**Supabase（スパベース）** は、アカウント・データ・写真をインターネット上に保存してくれる無料サービスです。
この手順では、PicParty 用の Supabase を用意して、アプリとつなぎ、**自分のアカウントを作れるように** します。

所要時間：20〜30 分くらい

---

## 1. Supabase に無料登録する（最初の 1 回だけ）

1. Mac のブラウザで https://supabase.com を開きます。
2. 右上の「**Start your project**」（または「Sign in」）を押します。
3. 「**Continue with GitHub**」を選び、GitHub アカウント（Yugo25）でログインするのが一番簡単です。
4. 「組織（Organization）」の名前を聞かれたら、`Yugo25` など好きな名前で大丈夫です。
   プランは **Free（無料）** のままにします。クレジットカードは不要です。

---

## 2. プロジェクトを作る

1. 「**New project**」を押します。
2. 次のように入力します。

   | 項目 | 入力するもの |
   |---|---|
   | Project name | `picparty` |
   | Database Password | 「Generate a password」で自動作成 → **必ずメモ**（パスワード管理アプリなどに保存） |
   | Region | **Northeast Asia (Tokyo)**（日本・アジアから速い場所） |

3. 「**Create new project**」を押します。
4. 準備に 1〜2 分かかります。画面が切り替わるまで待ってください。

> Database Password は普段は使いませんが、あとで必要になることがあるので、なくさないようにしてください。

---

## 3. データの「表」と「ルール」を作る（SQL を 5 回実行）

PicParty に必要な表（ユーザー、パーティ、写真、いいね、コメント…）とルールは、もうファイルに書いてあります。
それを Supabase に貼り付けて実行するだけです。

### 3-1. 1 つ目：`000_core.sql`

1. Mac の「ターミナル」で次を実行します。ファイルの中身がコピーされます（画面には何も出ません）。
   ```bash
   pbcopy < ~/PicParty/supabase/migrations/000_core.sql
   ```
2. Supabase の左側のメニューから「**SQL Editor**」（`>_` のようなアイコン）を開きます。
3. 「**+ New query**」（または「New SQL snippet」）を押します。
4. 白い入力欄をクリックして、`command + V` で貼り付けます。
5. 右下の「**Run**」を押します（`command + Enter` でも OK）。
6. 「This query has destructive operations」のような確認が出たら、「**Run this query**」を押して大丈夫です。
   （古い設定を消してから作り直す命令が含まれているため出る注意です）
7. 下に「**Success. No rows returned**」と出れば成功です。

### 3-2. 2 つ目：`114_new_ui.sql`

新しい画面に合わせた修正です。**必ず 1 つ目のあとに**実行してください。

1. ターミナルで：
   ```bash
   pbcopy < ~/PicParty/supabase/migrations/114_new_ui.sql
   ```
2. SQL Editor でもう一度「**+ New query**」を押し、貼り付けて「**Run**」。
3. 「**Success. No rows returned**」と出れば成功です。

### 3-3. 3 つ目：`115_signup.sql`

アプリから新規登録するための追加です。**必ず 2 つ目のあとに**実行してください。

1. ターミナルで：
   ```bash
   pbcopy < ~/PicParty/supabase/migrations/115_signup.sql
   ```
2. SQL Editor でもう一度「**+ New query**」を押し、貼り付けて「**Run**」。
3. 「**Success. No rows returned**」と出れば成功です。

### 3-4. 4 つ目：`116_sharing.sql`

パーティ・写真・いいね・コメント・フォローをみんなで共有するための追加です。**必ず 3 つ目のあとに**実行してください。

1. ターミナルで：
   ```bash
   pbcopy < ~/PicParty/supabase/migrations/116_sharing.sql
   ```
2. SQL Editor でもう一度「**+ New query**」を押し、貼り付けて「**Run**」。
3. 「**Success. No rows returned**」と出れば成功です。

### 3-5. 5 つ目：`117_avatars.sql`

プロフィール写真（アイコン）を設定できるようにする追加です。**必ず 4 つ目のあとに**実行してください。

1. ターミナルで：
   ```bash
   pbcopy < ~/PicParty/supabase/migrations/117_avatars.sql
   ```
2. SQL Editor でもう一度「**+ New query**」を押し、貼り付けて「**Run**」。
3. 「**Success. No rows returned**」と出れば成功です。

> `109_moderation.sql` 〜 `113_share_deeplink.sql` はメモ書きだけのファイルなので、実行しなくて大丈夫です。
> すでに途中まで終わっている人は、まだ実行していないものだけ実行すれば大丈夫です（例：3-4 まで終わっていれば 3-5 だけ）。

---

## 4. できたか確認する

1. 左メニューの「**Table Editor**」を開きます。
   `profiles`、`parties`、`party_members`、`media_posts`、`likes`、`comments`、`follows`、`messages` などの表が並んでいれば OK です（中身はまだ空です）。
2. 左メニューの「**Storage**」を開きます。
   `party-media` と `profile-media` の 2 つが並んでいれば OK です（写真の置き場所です）。

---

## 5. メール確認をオフにする（テスト中だけ）

最初の設定では、新規登録するたびに確認メールが届き、メール内のリンクを押すまでログインできません。
さらに無料プランでは送れるメールの数がとても少ないため、テスト中はオフにしておくのがおすすめです。

1. 左メニューの「**Authentication**」を開きます。
2. 「**Sign In / Providers**」（または「Providers」→「Email」）を開きます。
3. 「**Confirm email**」をオフにして、「**Save**」を押します。

> 一般の人に公開する前には、またオンに戻します（そのときにお知らせします）。

---

## 6. 「URL」と「キー」をメモする

アプリが Supabase とつながるために、次の 2 つが必要です。

1. 左下の歯車「**Project Settings**」を開きます。
2. 「**Data API**」（または「API」）を開き、**Project URL** をコピーします。
   `https://abcdefghijk.supabase.co` のような形です。
3. 「**API Keys**」を開き、**Publishable key**（`sb_publishable_` で始まる）をコピーします。
   画面によっては「**anon public**」という名前のキー（`eyJ` で始まる長い文字）になっています。どちらでも使えます。

> ⚠️ **「secret」や「service_role」と書かれたキーは絶対に使わないでください。**
> それは管理者用の合鍵です。アプリに入れたり、人に見せたり、GitHub に載せたりしてはいけません。
> 一方、Publishable key / anon key はアプリに入れて公開する前提のキーなので、使って大丈夫です。

### キーを `.env` ファイルに保存する

1. ターミナルで次を実行します（見本ファイルをコピーして、テキストエディットで開きます）。
   ```bash
   cd ~/PicParty
   cp .env.example .env
   open -e .env
   ```
2. 開いたファイルを次のように書き換えて保存します（`command + S`）。
   ```
   SUPABASE_URL=https://（あなたのProject URL）.supabase.co
   SUPABASE_ANON_KEY=（コピーしたPublishable key または anon key）
   ```
   `=` の前後にスペースは入れません。

> `.env` は `.gitignore` に入っているので、GitHub には上がりません。

---

## 7. アプリをつないで、アカウントを作ってみる

`.env` のキーを使ってアプリを起動します。Mac の Chrome で試すのが一番かんたんです。

1. ターミナルで次を実行します（初回は 1 分ほどかかります）。
   ```bash
   cd ~/PicParty
   flutter run -d chrome --dart-define-from-file=.env
   ```
   `--dart-define-from-file=.env` が「`.env` のキーを使ってね」という意味です。
2. Chrome が開き、**ログイン画面** が出れば、Supabase とつながっています。
   （キーなしで起動すると、これまで通りログインなしのデモモードになります）
3. 「**Create account**」タブを押し、次の 4 つを入力して、下の「**Create account**」ボタンを押します。

   | 項目 | 入力するもの |
   |---|---|
   | Name | 表示される名前（例：`Yugo`） |
   | Username | `@` のあとの名前。半角の小文字・数字・`.`・`_` で 3〜30 文字（例：`yugo25`） |
   | Email | 自分のメールアドレス |
   | Password | 8 文字以上 |

4. ホーム画面に切り替われば、アカウント作成成功です 🎉
   下の「プロフィール」タブを開くと、名前と `@ユーザー名` が表示されます。
5. 確認：Supabase の「**Table Editor**」→「**profiles**」を開くと、今作ったアカウントの行が増えています。
   「**Authentication**」→「**Users**」にもメールアドレスが並んでいます。
6. ログアウトしたいとき：プロフィール右上の歯車（設定）→ 一番下の「**Sign out**」。
7. 終わったら、ターミナルで `q` を押すとアプリが止まります。

> 一度ログインすると、Chrome を閉じて開き直してもログインしたままです。

### iPhone で使う（Web 版を公開する）

`docs/WEB_DEPLOY.md` の手順でビルドするときに、コマンドを次のように変えるだけです。

```bash
flutter build web --release --dart-define-from-file=.env
```

これでできた `build/web` を Netlify にアップロードすれば、iPhone からも新規登録・ログインできます。

> ⚠️ メッセージ（受信箱）と通知、非公開パーティへの招待はまだつながっていません（次のステップ）。
> 投稿できるのは写真だけです（動画はあとで対応します）。

---

## 8. 2 人で共有を試してみる

友達がいなくても、**アカウントを 2 つ作れば** 1 人で試せます。
Chrome の「シークレットウィンドウ」は別の人としてログインできるので便利です。

1. いつもの Chrome で `flutter run -d chrome --dart-define-from-file=.env` を実行し、**アカウント A** でログインします。
2. アドレスバーの URL（`http://localhost:xxxxx/` のような形）をコピーします。
3. Chrome のメニュー →「**新しいシークレット ウィンドウ**」（`command + shift + N`）を開き、その URL を貼り付けて開きます。
   こちらでは **アカウント B** を新規登録します（別のメールアドレスが必要です。Gmail なら `自分の名前+test@gmail.com` のように `+` を付けると別のアドレスとして使えます）。
4. **A** で、下の「Create」からパーティを作ります（カバー写真も付けてみてください）。「Start now（今すぐ開始）」にすると、すぐ写真を投稿できます。
5. **B** で、ホームを **下に引っ張って更新** します。A のパーティが出てくれば共有できています 🎉
   探索（Explore）にも出ます（公開パーティの場合）。
6. **B** で、そのパーティを開いて「**Add photo**」→ 写真を選びます。
7. **A** で、同じパーティを開いて下に引っ張って更新 → B の写真が見えます。
8. いいね（♡）やコメントも試してみてください。相手の画面で引っ張って更新すると数字が増えています。
9. **B** で A のプロフィールを開いて「**Follow**」→ ホームの「**Following**」タブに A のパーティが出ます。

> 相手の画面は自動では変わりません。**下に引っ張って更新** すると最新になります。

### ちゃんと保存されているか確認する（任意）

Supabase の画面で次を開くと、データが入っているのが見えます。
- 「**Table Editor**」→ `parties`（パーティ）、`media_posts`（写真）、`likes`（いいね）、`comments`（コメント）、`follows`（フォロー）
- 「**Storage**」→ `party-media`（写真のファイル本体）

---

## 困ったとき

| 症状 | 対処 |
|---|---|
| SQL の実行で `already exists` と出た | 同じ SQL を 2 回実行しただけなら問題ありません。 |
| 2 つ目の SQL で `relation "public.parties" does not exist` と出た | 1 つ目（`000_core.sql`）がまだ成功していません。3-1 からやり直してください。 |
| アプリを起動してもログイン画面が出ない（デモモードのまま） | `--dart-define-from-file=.env` を付け忘れているか、`.env` の中身が空です。6. を確認してください。 |
| 新規登録で「Something went wrong」と出る | 3-3（`115_signup.sql`）を実行したか確認してください。 |
| ホームがずっと読み込み中、または「Couldn't load」と出る | 3-4（`116_sharing.sql`）を実行したか確認してください。 |
| 写真を投稿すると「Couldn't post your photo」と出る | パーティの時間が終わっていないか、まだ始まっていないかを確認してください。それでもだめなら 3-2（`114_new_ui.sql`）と 3-4 を実行し直してください。 |
| プロフィール写真を選ぶと「Couldn't update your photo」と出る | 3-5（`117_avatars.sql`）を実行したか確認してください。 |
| 相手のパーティや写真が出てこない | 下に引っ張って更新してください。「非公開（Private）」のパーティは主催者にしか見えません。 |
| 新規登録すると「We sent a link to …」と出てログインできない | 5. の「Confirm email」がオンのままです。オフにするか、届いたメールのリンクを押してからログインしてください。 |
| 貼り付けたら途中で切れている気がする | `pbcopy` のコマンドをもう一度実行してから、入力欄を全部消して貼り直してください。 |
| プロジェクトがしばらく使われず「Paused」になった | 無料プランは 1 週間ほど使わないと一時停止します。ダッシュボードで「Restore」を押せば戻ります。 |
| その他のエラー | 赤い文字のエラーメッセージをそのままコピーして教えてください。 |
