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
docker compose exec web bundle exec rails console              # Rails コンソール
docker compose exec web bundle exec rubocop                    # Ruby Lint
docker compose exec web bundle exec brakeman                   # セキュリティ脆弱性スキャン
```

### Docker 構成メモ

- docker compose の構成ファイル: `compose.yml`（`docker-compose.yml` ではない）
- `Dockerfile.dev`: Ruby 3.3.6 ベース、Node 20 + Yarn をインストール
- ソースコードは `.:/app` でマウント（ホストの変更がリアルタイムに反映）
- Gem は `bundle_data` volume にキャッシュ（コンテナ再起動時の再インストール不要）
- `node_modules` は専用 volume（ホストの node_modules と分離）
- `db` コンテナのヘルスチェック（`pg_isready`）成功後に `web` が起動

## アーキテクチャ

### ドメインモデル

3 つのモデルが中心。

- **User**（Devise）— display_name（最大 50 文字）を持つ
- **Material** — title（最大 100 文字）、URL（http/https のみ）、description（最大 5000 文字）
- **Review** — User → Material の評価。`start_level`（学習開始レベル 1〜5）と `difficulty_rating`（難易度評価 1〜5）を持つ enum。同一ユーザーと教材の組み合わせは一意制約あり

### ルーティング構造

```
root → materials#index
resources :materials（検索: Ransack、タイトル部分一致）
  resources :reviews（材料に対してネスト）
resources :profiles
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
| Rails | 7.2.3 |
| Node | 20.20.0 |
| DB | PostgreSQL |
| 認証 | Devise |
| 検索 | Ransack |
