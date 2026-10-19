# Supabase（サーバー）を準備する手順

今の PicParty は「デモモード」で動いていて、データはその端末の中だけにあります。
再読み込みすると消えますし、友達と写真を共有することもできません。

**Supabase（スパベース）** は、アカウント・データ・写真をインターネット上に保存してくれる無料サービスです。
この手順では、PicParty 用の Supabase を用意して、アプリとつなぐための「URL」と「キー」を手に入れます。

> この手順では、アプリの見た目はまだ変わりません。アプリと実際につなぐのは次のステップ（ログイン画面づくり）です。

所要時間：15〜20 分くらい

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

## 3. データの「表」と「ルール」を作る（SQL を 2 回実行）

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

> `109_moderation.sql` 〜 `113_share_deeplink.sql` はメモ書きだけのファイルなので、実行しなくて大丈夫です。

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

## ここまでできたら

「Supabase の準備ができた」と教えてください。次のステップで、

- 新しいデザインのログイン／新規登録画面を作り、
- `.env` のキーを使ってアプリを Supabase につなぎます。

キーを入れない状態で起動すれば、これまで通りデモモードで動きます。

---

## 困ったとき

| 症状 | 対処 |
|---|---|
| SQL の実行で `already exists` と出た | 同じ SQL を 2 回実行しただけなら問題ありません。 |
| 2 つ目の SQL で `relation "public.parties" does not exist` と出た | 1 つ目（`000_core.sql`）がまだ成功していません。3-1 からやり直してください。 |
| 貼り付けたら途中で切れている気がする | `pbcopy` のコマンドをもう一度実行してから、入力欄を全部消して貼り直してください。 |
| プロジェクトがしばらく使われず「Paused」になった | 無料プランは 1 週間ほど使わないと一時停止します。ダッシュボードで「Restore」を押せば戻ります。 |
| その他のエラー | 赤い文字のエラーメッセージをそのままコピーして教えてください。 |
