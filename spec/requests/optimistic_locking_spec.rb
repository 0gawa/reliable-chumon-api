require 'rails_helper'

RSpec.describe '楽観的ロック (Optimistic Locking)', type: :request do
  let(:menu) { create(:menu, name: 'Original Name', price: 1000) }

  describe 'メニューの同時更新' do
    it '2つのリクエストが同じメニューを更新しようとすると、2番目は失敗する' do
      # Railsのupdateメソッドは自動的にlock_versionをチェックする
      # 古いlock_versionで更新しようとすると失敗する
      original_lock_version = menu.lock_version

      # 別のリクエストがメニューを更新（lock_versionがインクリメントされる）
      menu.update!(name: 'Updated by Another Request', price: 1500)

     # 古いlock_versionで更新を試みる
     # `update_attribute`ではなく、`menu_params`に含める
     patch "/api/v1/admin/menus/#{menu.id}",
            params: { menu: { name: 'My Update', price: 2000, lock_version: original_lock_version } },
            as: :json

      expect(response).to have_http_status(:conflict)
      json_response = JSON.parse(response.body)
      expect(json_response['error']['code']).to eq('STALE_OBJECT')
      expect(json_response['error']['message']).to include('modified by another request')

      menu.reload
      expect(menu.name).to eq('Updated by Another Request')
    end

    it '正しいlock_versionで更新すると成功する' do
      patch "/api/v1/admin/menus/#{menu.id}",
            params: { menu: { name: 'New Name', lock_version: menu.lock_version } },
            as: :json

      expect(response).to have_http_status(:ok)
      menu.reload
      expect(menu.name).to eq('New Name')
      expect(menu.lock_version).to eq(1)
    end

    context 'lock_versionが欠落している場合' do
      it '更新が拒否される（またはエラーになる）' do
        patch "/api/v1/admin/menus/#{menu.id}",
              params: { menu: { name: 'No Lock Version' } },
              as: :json

        # 実装方針によるが、StaleObjectErrorを防ぐために必須とするのが一般的
        # ここでは422または400を期待
        expect(response.status).to be_in([400, 422])
        json_response = JSON.parse(response.body)
        expect(json_response['error']['code']).to eq('MISSING_LOCK_VERSION')
      end
    end

    context 'lock_versionが無効な場合' do
      it 'エラーを返す' do
        patch "/api/v1/admin/menus/#{menu.id}",
              params: { menu: { name: 'Invalid Lock Version' }, lock_version: 'invalid' },
              as: :json

        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end
end
