# 実運用に向けた不足要素と次期アクション提案

## 📊 現在の実装状況

### ✅ 完了している機能
- **Phase 1-3**: メニュー管理、注文エンジン、価格スナップショット、計算精度
- **Phase 4**: 日次集計基盤、バックグラウンドジョブ処理
- **追加機能**: レート制限、CI/CD、セキュリティスキャン

---

## 🚨 実運用システムに不足している重要要素

### 1. 認証・認可 (Authentication & Authorization) 【最優先】

**現状の問題:**
- 管理者APIが認証なしで誰でもアクセス可能
- 注文データの改ざんリスク
- 不正な価格操作の可能性

**推奨実装:**

#### Option A: JWT (JSON Web Token) - API専用の標準的手法
```ruby
# Gemfile
gem 'jwt'
gem 'bcrypt' # パスワードハッシュ化

# 実装すべき要素
- POST /api/v1/auth/login (トークン発行)
- POST /api/v1/auth/refresh (トークン更新)
- AdminController に before_action :authenticate_admin!
- トークンの有効期限管理 (15分 + リフレッシュトークン7日)
```

#### Option B: API Key方式 - 券売機/レジ端末向け
```ruby
# 各端末に固有のAPI Keyを発行
- api_keys テーブル: name, key_hash, scope, expires_at
- ヘッダー: X-API-Key による認証
- スコープ: admin, pos, kiosk, analytics
```

**優先度: 🔴 最高 (本番環境では必須)**

---

### 2. トランザクション整合性とロック制御

**現状の問題:**
- 同時注文時の在庫数減算が競合する可能性
- 複数の券売機からの同時アクセスでデータ不整合
- 注文確定中のメニュー変更

**推奨実装:**

```ruby
# 楽観的ロック (Optimistic Locking)
class Menu < ApplicationRecord
  # lock_version カラムを追加
end

# 悲観的ロック (Pessimistic Locking) - 在庫管理時
Menu.lock.find(menu_id) # SELECT ... FOR UPDATE

# トランザクション分離レベル
ActiveRecord::Base.transaction(isolation: :serializable) do
  # 注文処理
end

# 冪等性キーの実装
class Order < ApplicationRecord
  validates :idempotency_key, uniqueness: true, allow_nil: true
end
```

**優先度: 🟡 高 (複数端末環境では必須)**

---

### 3. 在庫管理 (Inventory Management)

**現状の問題:**
- `is_available` のON/OFFしかない
- 売り切れの自動管理ができない
- 日次の在庫補充フローがない

**推奨実装:**

```ruby
# マイグレーション
add_column :menus, :stock_quantity, :integer
add_column :menus, :auto_disable_on_zero, :boolean, default: true

# サービス実装
class StockManagementService
  def decrease_stock(menu_id, quantity)
    menu = Menu.lock.find(menu_id)
    
    if menu.stock_quantity < quantity
      raise InsufficientStockError
    end
    
    menu.decrement!(:stock_quantity, quantity)
    
    if menu.stock_quantity <= 0 && menu.auto_disable_on_zero
      menu.update!(is_available: false)
      # 通知: 在庫切れアラート
    end
  end
end

# 日次在庫リセットジョブ
class DailyStockResetJob < ApplicationJob
  def perform
    Menu.where(auto_reset: true).update_all(stock_quantity: ...)
  end
end
```

**優先度: 🟡 高 (券売機では必須)**

---

### 4. 監査ログ (Audit Trail)

**現状の問題:**
- 価格変更の履歴が追跡できない
- 注文のキャンセル/修正の記録がない
- 不正操作の検知が不可能

**推奨実装:**

```ruby
# Gemfile
gem 'paper_trail' # または自前実装

# マイグレーション
class CreateAuditLogs < ActiveRecord::Migration[7.2]
  def change
    create_table :audit_logs do |t|
      t.string :resource_type, null: false
      t.bigint :resource_id, null: false
      t.string :action # create, update, delete
      t.jsonb :changes # 変更内容
      t.string :user_id # 操作者
      t.string :ip_address
      t.timestamps
    end
    
    add_index :audit_logs, [:resource_type, :resource_id]
    add_index :audit_logs, :created_at
  end
end

# ミドルウェア実装
class AuditLogger
  def log_change(model, action, user)
    AuditLog.create!(
      resource_type: model.class.name,
      resource_id: model.id,
      action: action,
      changes: model.changes,
      user_id: user&.id,
      ip_address: current_ip
    )
  end
end
```

**優先度: 🟡 高 (監査要件、PCI DSS準拠に必須)**

---

### 5. リアルタイム通信 (WebSocket/Server-Sent Events)

**現状の問題:**
- キッチンへの注文通知がリアルタイムでない
- 注文状況の更新をポーリングに依存
- ユーザー側での注文状況確認が不便

**推奨実装:**

```ruby
# Action Cable (Rails標準のWebSocket)
# app/channels/order_channel.rb
class OrderChannel < ApplicationCable::Channel
  def subscribed
    stream_from "orders_kitchen"
  end
end

# 注文確定時にブロードキャスト
class OrderCreator
  def call
    # ... 注文処理
    ActionCable.server.broadcast(
      "orders_kitchen",
      order: order.as_json(include: :order_items)
    )
  end
end

# または Server-Sent Events (SSE) - よりシンプル
class Api::V1::Admin::OrderEventsController < ApplicationController
  include ActionController::Live
  
  def stream
    response.headers['Content-Type'] = 'text/event-stream'
    
    loop do
      # 新規注文をストリーム
    end
  ensure
    response.stream.close
  end
end
```

**優先度: 🟢 中 (キッチンディスプレイシステムには必須)**

---

### 6. エラーハンドリングと復旧戦略

**現状の問題:**
- ネットワーク障害時の注文データロスト
- 決済連携エラー時のロールバック不足
- システム障害時の自動復旧なし

**推奨実装:**

```ruby
# 1. オフライン対応 (券売機側)
# - ローカルキャッシュ + 後続同期
# - 注文データの一時保存

# 2. Circuit Breaker パターン
class PaymentGateway
  include CircuitBreaker
  
  def charge(amount)
    with_circuit_breaker do
      external_api.charge(amount)
    end
  rescue CircuitBreaker::OpenError
    # フォールバック処理: 手動決済フラグ
    create_manual_payment_task(amount)
  end
end

# 3. Dead Letter Queue (DLQ)
# Sidekiq の failed jobs を永続化
class FailedJobHandler
  def handle
    Sidekiq::RetrySet.new.each do |job|
      if job.retry_count > 5
        notify_admin(job)
        archive_to_manual_queue(job)
      end
    end
  end
end
```

**優先度: 🟡 高 (24時間営業やミッションクリティカルな環境)**

---

### 7. パフォーマンス最適化

**現状の問題:**
- N+1クエリの可能性
- キャッシュ戦略なし
- 大量注文時のレスポンス遅延

**推奨実装:**

```ruby
# 1. Redis キャッシュ
class Api::V1::Customer::MenusController
  def index
    @menus = Rails.cache.fetch("available_menus", expires_in: 5.minutes) do
      Menu.available.to_a
    end
  end
end

# 2. データベースインデックス最適化
add_index :orders, [:status, :ordered_at]
add_index :order_items, [:menu_id, :ordered_date]
add_index :orders, :table_number, where: "status != 'completed'"

# 3. コネクションプーリング
# config/database.yml
production:
  pool: <%= ENV.fetch("DB_POOL") { 25 } %>
  timeout: 5000

# 4. クエリ最適化
Order.includes(:order_items).where(status: 'pending')
```

**優先度: 🟢 中 (高トラフィック環境で重要)**

---

### 8. 外部システム連携

**実際のシステムで必要な連携:**

#### A. キャッシュレス決済 (必須)
```ruby
# app/services/payment_integrations/
- stripe_service.rb
- square_service.rb
- paypay_service.rb

# 実装すべき機能
- 決済トークン検証
- 決済実行と確認
- 返金処理
- 決済ステータス同期
```

#### B. POSシステム連携
```ruby
# レシート出力
- 注文データのPOS形式変換
- ESC/POS コマンド生成

# 売上データ同期
- 日次売上のエクスポート
- 在庫データの同期
```

#### C. キッチンディスプレイシステム (KDS)
```ruby
# 注文のリアルタイム転送
- WebSocket経由の注文通知
- 調理完了のステータス更新
- 優先度管理
```

**優先度: 🔴 最高 (実運用には必須)**

---

### 9. セキュリティ強化

**現在実装済み:**
- ✅ Rate Limiting (Rack::Attack)
- ✅ Brakeman セキュリティスキャン
- ✅ Bundler Audit

**追加すべき対策:**

```ruby
# 1. CORS設定 (本番環境)
# config/initializers/cors.rb
Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins ENV['ALLOWED_ORIGINS']&.split(',') || 'localhost:3000'
    resource '*', 
      headers: :any,
      methods: [:get, :post, :put, :patch, :delete],
      credentials: false
  end
end

# 2. SQL Injection 対策
# - すでにActiveRecordで対策済み
# - 生SQLは避ける

# 3. XSS対策
# - APIモードなのでXSSリスクは低い
# - JSONレスポンスのエスケープ確認

# 4. 機密情報の暗号化
# config/credentials.yml.enc の活用
Rails.application.credentials.payment_api_key

# 5. HTTPS強制 (本番環境)
config.force_ssl = true
```

**優先度: 🔴 最高**

---

### 10. 運用・監視 (Observability)

**現状の問題:**
- エラー通知なし
- パフォーマンス可視化なし
- ログ分析ツールなし

**推奨実装:**

```ruby
# 1. エラー追跡
gem 'sentry-ruby'
gem 'sentry-rails'

# 2. APM (Application Performance Monitoring)
gem 'newrelic_rpm'
# または
gem 'skylight'

# 3. 構造化ログ
gem 'lograge' # JSONフォーマットのログ

# config/environments/production.rb
config.lograge.enabled = true
config.lograge.formatter = Lograge::Formatters::Json.new

# 4. ヘルスチェックエンドポイント
class HealthController < ApplicationController
  def show
    render json: {
      status: 'ok',
      database: check_database,
      redis: check_redis,
      sidekiq: check_sidekiq,
      timestamp: Time.current
    }
  end
end
```

**優先度: 🟡 高 (本番運用には必須)**

---

## 🎯 推奨実装ロードマップ

### Phase 5: セキュリティ基盤 (2-3週間)
1. **Week 1**: JWT認証の実装
   - 管理者ログイン機能
   - トークン発行・検証
   - 権限管理 (RBAC)

2. **Week 2**: API Key認証
   - 券売機/レジ端末用のAPI Key発行
   - スコープ管理
   - キーのローテーション機能

3. **Week 3**: 監査ログ
   - Audit Trail実装
   - 重要操作のログ記録

### Phase 6: 決済連携基盤 (2-3週間)
1. **Week 1-2**: 決済プロバイダー統合
   - Stripe/Square等のSDK統合
   - Webhook処理
   - 決済状態管理

2. **Week 3**: エラーハンドリング
   - Circuit Breaker実装
   - リトライ戦略
   - タイムアウト管理

### Phase 7: 在庫・リアルタイム通信 (2週間)
1. **Week 1**: 在庫管理
   - 在庫数管理機能
   - 自動売り切れ設定
   - 在庫アラート

2. **Week 2**: WebSocket
   - Action Cable設定
   - キッチン注文通知
   - 注文状況リアルタイム更新

### Phase 8: 運用基盤 (1-2週間)
1. **Week 1**: 監視・ログ
   - Sentry統合
   - 構造化ログ
   - ヘルスチェック

2. **Week 2**: パフォーマンス
   - キャッシュ戦略
   - インデックス最適化
   - コネクションプール調整

---

## 📋 即座に対応すべき項目 (優先順)

1. 🔴 **認証・認可の実装** (1週間)
   - 最低限のJWT認証を実装
   - 管理者APIの保護

2. 🔴 **決済連携の設計** (3-5日)
   - 決済プロバイダーの選定
   - インターフェース設計
   - Webhook処理の実装

3. 🟡 **トランザクション整合性** (3-5日)
   - 楽観的ロックの導入
   - 冪等性キーの実装

4. 🟡 **監査ログ** (3日)
   - 基本的なAudit Trail

5. 🟡 **エラー監視** (2日)
   - Sentry導入
   - 基本的なアラート設定

---

## 💡 軽量OSS化を考慮した推奨事項

本プロジェクトをOSSとして公開する場合:

### 必須対応
- ✅ MIT Licenseの明記
- ✅ CONTRIBUTINGガイドライン作成
- ✅ 決済連携をプラグイン可能な設計に
- ✅ 環境変数による設定の外部化
- ✅ Docker Composeでの簡単なセットアップ維持

### 推奨対応
- 📚 詳細なAPI仕様書 (OpenAPI/Swagger)
- 🧪 E2Eテストの追加
- 📖 多言語対応のREADME
- 🎨 Postmanコレクションの提供
- 🔌 プラグインアーキテクチャの導入

---

## 🚀 まとめ

**現在のシステム完成度: 60-70%**

実運用可能にするには:
- 🔴 認証・認可 (必須)
- 🔴 決済連携 (必須)
- 🟡 在庫管理 (推奨)
- 🟡 監視・ログ (推奨)
- 🟢 リアルタイム通信 (オプション)

**次のアクション候補:**
1. Phase 5 (セキュリティ基盤) の着手
2. 決済プロバイダーとの統合設計
3. 在庫管理機能の追加

どの機能から着手するか、ご希望をお聞かせください！
