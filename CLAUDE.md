# CLAUDE.md

このファイルは、リポジトリ内で作業する Claude Code (claude.ai/code) へのガイダンスを提供します。

## プロジェクト概要

プログラマー向け学習教材評価サービス。ユーザーが「学習開始時のレベル（1〜5段階）」と「教材の難易度評価（1〜5段階）」を投稿し、レベル別に教材を探せるようにする Rails アプリケーション。

## 開発コマンド

開発は Docker コンテナ内で行う。

### 開発サーバー起動

```bash
docker compose up
```

`web` コンテナ起動時に `bundle install → yarn install → rails db:prepare → tmp/pids/server.pid 削除 → bin/dev`（JS/CSS ウォッチャー込み）が自動実行される。`tmp/pids/server.pid` の削除はコンテナ再起動時の起動失敗を防ぐため。アプリは http://localhost:3000 で起動。

### コンテナ内でのコマンド実行

```bash
docker compose exec web bundle exec rails db:migrate           # マイグレーション実行
docker compose exec web bundle exec rails db:prepare           # DB 準備（未作成なら作成+schema+seed、既存ならマイグレーションのみ）
docker compose exec web bundle exec rails db:seed              # 初期データ投入（seed）
docker compose exec web bundle exec rails db:schema:load       # schema.rb から全テーブルを再構築（DB は drop せずデータは消える）
docker compose exec web bundle exec rails db:drop              # DB 削除（破壊的・接続中だと失敗するため注意）
docker compose exec web bundle exec rails console              # Rails コンソール
docker compose exec web bundle exec rspec                      # テスト実行（RSpec）
docker compose exec web bundle exec rubocop                    # Ruby Lint
docker compose exec web bundle exec brakeman                   # セキュリティ脆弱性スキャン
```

### seed（初期データ）

`db/seeds.rb` は 3 部構成。

- **Topic マスタ**（全環境）：ruby / rails などの分野マスタを `Topic.find_or_create_from_input` で冪等に投入。同名の TopicGroup も同時に作られる。
- **分野のグループ化の宣言**（全環境）：`TOPIC_GROUPINGS` に「どの表記を同一視するか」を書き、`TopicGroup.assign_topics!` で適用する。最後に `TopicGroup.delete_unused!` で、属する分野が 0 件になったグループを削除する（**必ず割り当ての後に呼ぶ**）。
- **開発用サンプルデータ**（`if Rails.env.development?` ガード内）：おすすめ機能（`MaterialRecommender`）の動作確認用に user / 教材 / レビュー（topic 付き）を投入。本番では実行されず、冪等なので何度 `db:seed` しても重複しない。

`docker compose up` 時に走る `db:prepare` は、**DB が新規作成された場合のみ** seed を実行する（既存 DB ではマイグレーションのみ）。

本番（Render）の `bin/render-build.sh` は `db:migrate` の後に `db:seed` を実行する。**分野のグループ化の宣言を本番へ反映する手段がこれしかない**（無料プランではシェルが使えず `rails console` を開けない）。開発用サンプルデータは `Rails.env.development?` ガードの内側にあるため、本番には入らない。

### Docker 構成メモ

- docker compose の構成ファイル: `compose.yml`（`docker-compose.yml` ではない）
- `Dockerfile.dev`: Ruby 3.3.6 ベース、Node 20 + Yarn をインストール
- ソースコードは `.:/app` でマウント（ホストの変更がリアルタイムに反映）
- Gem は `bundle_data` volume にキャッシュ（コンテナ再起動時の再インストール不要）
- `node_modules` は専用 volume（ホストの node_modules と分離）
- `db` コンテナのヘルスチェック（`pg_isready`）成功後に `web` が起動

## アーキテクチャ

### ドメインモデル

6 つのモデルが中心。

- **User**（Devise）— display_name（最大 50 文字）を持つ
- **Material** — title（最大 100 文字）、URL（http/https のみ）、description（最大 5000 文字）
- **Review** — User → Material の評価。`start_level`（学習開始レベル 1〜5）と `difficulty_rating`（難易度評価 1〜5）を持つ enum。同一ユーザーと教材の組み合わせは一意制約あり。`has_many :topics, through: :review_topics` で分野（topic）を多対多で持ち、フォーム入力用の仮想属性 `topic_names`（カンマ区切り文字列）を持つ。レビューの編集・削除は作成者本人のみ可（`ReviewsController#set_own_review` が `current_user.reviews.find` で自分のレビューに限定し、他人の id は `RecordNotFound`＝404）
- **Topic** — 分野マスタ。name（最大 50 文字・一意）。`belongs_to :topic_group`（`topic_group_id` は `null: false`）。`find_or_create_from_input` で入力を strip + downcase 正規化して引き当て / 新規作成し、**同時にグループも用意する**。`Topic.create` を直接呼ぶと NOT NULL 制約違反で失敗するため、**分野の作成は必ず `find_or_create_from_input` を通す**
- **TopicGroup** — 複数の分野を集計上まとめる単位。name（最大 50 文字・一意）。`has_many :topics` を持ち、**1 グループに複数の分野が属する / 1 分野が属するグループは 1 つだけ**。`topics.topic_group_id` の外部キーは `on_delete: :restrict`（グループを消してもレビューの分野表示が壊れないようにするため）。`assign_topics!` で宣言された分野をグループへ移し、`delete_unused!` で空のグループを削除する
- **ReviewTopic** — Review と Topic の中間テーブル。`[review_id, topic_id]` の複合一意制約

**topic を Material ではなく Review に持たせる設計思想**：同じ教材でもレビュアーによって「何の分野として学んだか」は異なる（例：『プロを目指す人のためのRuby入門』を Ruby と捉える人、Web 開発と捉える人、オブジェクト指向と捉える人がいる）。Material に固定タグを付けるとこの感じ方の差が潰れてしまうため、topic は **Review に多対多で**紐づける（`Review ─ ReviewTopic ─ Topic`）。教材の「客観的分野」は事前に固定せず、Review 群の集計（→ 後述の教材推薦）から動的に導出する。

### 教材推薦（あなたへのおすすめ）

- `app/services/material_recommender.rb` — ログインユーザーの過去 review が持つ分野を**グループ単位で**集計し、一致の多い未レビュー教材を返す副作用なしの読み取りサービス
- `materials#index` で `@recommended` にセットし、教材一覧の上部に「あなたへのおすすめ」として表示（未ログイン / レビュー履歴ゼロなら非表示）

**集計をグループ単位にする理由**：`js` と `javascript` のように同じものを指す表記が別レコードになると、ユーザーの興味が分散して推薦の精度が落ちる。そのため **集計は `topics.topic_group_id` で行い、マッチ数は `COUNT(DISTINCT (reviews.id, topics.topic_group_id))` で数える**（1 レビュー内に同じグループの分野が複数あっても二重に数えない）。

**レビューの分野バッジ（`app/views/reviews/_item.html.erb`）はユーザーが入力した語を表示する。グループ名に置き換えてはいけない。** `js` と書いたレビューは `js`、`javascript` と書いたレビューは `javascript` と表示する（集計上はどちらも同じグループ）。

ただし `find_or_create_from_input` が `strip` + `downcase` するため、`JavaScript` は `javascript` として保存・表示される。**この正規化は許容する。**

### ルーティング構造

```
root → materials#index
resource  :profile,   only: [:show, :edit, :update]            # 単数 resource
resources :materials, only: [:index, :new, :create, :show]     # 検索: Ransack（タイトル部分一致）
  resources :reviews, only: [:create, :edit, :update, :destroy] # materials にネスト。編集/削除は所有者のみ
```

### フロントエンド

- TailwindCSS + DaisyUI でスタイリング
- Hotwire（Turbo + Stimulus）を使用。esbuild でバンドル
- CSS は `tailwindcss-rails` gem でビルド（`bin/dev` 起動時にウォッチ）

### CI（`.github/workflows/ci.yml`）

3 ジョブが並列実行：brakeman セキュリティスキャン（`scan_ruby`）、rubocop Lint（`lint`）、RSpec 実行（`test`）。

## 技術スタック

| 項目 | バージョン |
|---|---|
| Ruby | 3.3.6 |
| Rails | 8.1.3.1 |
| Node | 20.20.0 |
| DB | PostgreSQL |
| 認証 | Devise |
| 検索 | Ransack |
