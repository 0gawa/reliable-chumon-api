require 'rails_helper'

RSpec.describe Orders::OrderInputValidator do
  let(:menu1) { create(:menu, name: 'ハンバーグ', price: 1000, is_available: true) }
  let(:menu2) { create(:menu, name: 'サラダ', price: 500, is_available: true) }

  describe '#validate!' do
    context '有効な入力の場合' do
      let(:items) do
        [
          { menu_id: menu1.id, quantity: 2 },
          { menu_id: menu2.id, quantity: 1 }
        ]
      end

      it 'バリデーションが成功すること' do
        validator = described_class.new(
          table_number: 'A-1',
          items: items,
          order_type: 'dine_in'
        )

        expect { validator.validate! }.not_to raise_error
      end

      it 'メニューキャッシュが返されること' do
        validator = described_class.new(
          table_number: 'A-1',
          items: items,
          order_type: 'dine_in'
        )

        result = validator.validate!

        expect(result[:menus_cache]).to be_a(Hash)
        expect(result[:menus_cache][menu1.id]).to eq(menu1)
        expect(result[:menus_cache][menu2.id]).to eq(menu2)
      end

      it 'エラーが空であること' do
        validator = described_class.new(
          table_number: 'A-1',
          items: items,
          order_type: 'dine_in'
        )

        result = validator.validate!

        expect(result[:errors]).to be_empty
      end
    end

    context '注文アイテムが空の場合' do
      it 'ActiveRecord::RecordInvalidが発生すること' do
        validator = described_class.new(
          table_number: 'A-1',
          items: [],
          order_type: 'dine_in'
        )

        expect { validator.validate! }.to raise_error(ActiveRecord::RecordInvalid)
      end

      it 'エラーメッセージが設定されること' do
        validator = described_class.new(
          table_number: 'A-1',
          items: [],
          order_type: 'dine_in'
        )

        begin
          validator.validate!
        rescue ActiveRecord::RecordInvalid
          # Expected error
        end

        expect(validator.errors).to include('注文アイテムが指定されていません')
      end
    end

    context '無効なorder_typeの場合' do
      let(:items) do
        [ { menu_id: menu1.id, quantity: 1 } ]
      end

      it 'ActiveRecord::RecordInvalidが発生すること' do
        validator = described_class.new(
          table_number: 'A-1',
          items: items,
          order_type: 'invalid_type'
        )

        expect { validator.validate! }.to raise_error(ActiveRecord::RecordInvalid)
      end

      it 'エラーメッセージが設定されること' do
        validator = described_class.new(
          table_number: 'A-1',
          items: items,
          order_type: 'invalid_type'
        )

        begin
          validator.validate!
        rescue ActiveRecord::RecordInvalid
          # Expected error
        end

        expect(validator.errors.first).to include('order_typeは')
        expect(validator.errors.first).to include('dine_in, takeout, delivery')
      end
    end

    context '存在しないメニューIDが指定された場合' do
      let(:items) do
        [ { menu_id: 99999, quantity: 1 } ]
      end

      it 'ActiveRecord::RecordInvalidが発生すること' do
        validator = described_class.new(
          table_number: 'A-1',
          items: items,
          order_type: 'dine_in'
        )

        expect { validator.validate! }.to raise_error(ActiveRecord::RecordInvalid)
      end

      it 'エラーメッセージが設定されること' do
        validator = described_class.new(
          table_number: 'A-1',
          items: items,
          order_type: 'dine_in'
        )

        begin
          validator.validate!
        rescue ActiveRecord::RecordInvalid
          # Expected error
        end

        expect(validator.errors).not_to be_empty
        expect(validator.errors.first).to include('メニューID 99999 が見つかりません')
      end
    end

    context '販売不可のメニューが含まれる場合' do
      let(:unavailable_menu) { create(:menu, name: 'カレー', is_available: false) }
      let(:items) do
        [ { menu_id: unavailable_menu.id, quantity: 1 } ]
      end

      it 'ActiveRecord::RecordInvalidが発生すること' do
        validator = described_class.new(
          table_number: 'A-1',
          items: items,
          order_type: 'dine_in'
        )

        expect { validator.validate! }.to raise_error(ActiveRecord::RecordInvalid)
      end

      it 'エラーメッセージが設定されること' do
        validator = described_class.new(
          table_number: 'A-1',
          items: items,
          order_type: 'dine_in'
        )

        begin
          validator.validate!
        rescue ActiveRecord::RecordInvalid
          # Expected error
        end

        expect(validator.errors).not_to be_empty
        expect(validator.errors.first).to include('現在注文できません')
      end
    end

    context '複数の有効なorder_typeをテスト' do
      let(:items) do
        [ { menu_id: menu1.id, quantity: 1 } ]
      end

      %w[dine_in takeout delivery].each do |order_type|
        it "order_type '#{order_type}' が有効であること" do
          validator = described_class.new(
            table_number: 'A-1',
            items: items,
            order_type: order_type
          )

          expect { validator.validate! }.not_to raise_error
        end
      end
    end
  end
end
