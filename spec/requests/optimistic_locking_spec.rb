require 'rails_helper'

RSpec.describe '楽観的ロック (Optimistic Locking)', type: :request do
  let(:menu) { create(:menu, name: 'Original Name', price: 1000) }
  
  describe 'メニューの同時更新' do
    it '2つのリクエストが同じメニューを更新しようとすると、2番目は失敗する' do
      # 1つ目のリクエスト: メニューを取得
      get "/api/v1/admin/menus/#{menu.id}"
      expect(response).to have_http_status(:ok)
      first_version = JSON.parse(response.body)['lock_version']
      
      # 別のリクエストが先に更新を完了
      menu.update!(name: 'Updated by Another Request', price: 1500)
      
      # 1つ目のリクエストが更新を試みる（古いlock_versionを使用）
      patch "/api/v1/admin/menus/#{menu.id}",
            params: { menu: { name: 'My Update', lock_version: first_version } }
      
      expect(response).to have_http_status(:conflict)
      json_response = JSON.parse(response.body)
      expect(json_response['code']).to eq('stale_object')
      expect(json_response['error']).to include('modified by another request')
      
      # データベースには2番目の更新が残っている
      menu.reload
      expect(menu.name).to eq('Updated by Another Request')
    end
    
    it '正しいlock_versionで更新すると成功する' do
      patch "/api/v1/admin/menus/#{menu.id}",
            params: { menu: { name: 'New Name' } }
      
      expect(response).to have_http_status(:ok)
      menu.reload
      expect(menu.name).to eq('New Name')
      expect(menu.lock_version).to eq(1) # バージョンが増加
    end
  end
end
