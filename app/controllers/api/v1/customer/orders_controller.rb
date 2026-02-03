class Api::V1::Customer::OrdersController < ApplicationController
  # POST /api/v1/customer/orders
  def create
    # 冪等性キーをヘッダーから取得（オプショナル）
    idempotency_key = request.headers['X-Idempotency-Key']
    
    creator = OrderCreator.new(
      table_number: order_params[:table_number],
      items: order_params[:items],
      order_type: order_params[:order_type] || 'dine_in',
      idempotency_key: idempotency_key
    )
    
    order = creator.call
    
    if creator.success?
      # 重複リクエストの場合は200、新規作成の場合は201
      status_code = creator.duplicate? ? :ok : :created
      render json: order.as_json(include: { order_items: {} }), status: status_code
    else
      # デッドロックの場合は409 Conflict
      if creator.errors.any? { |err| err.include?('deadlock') }
        render json: { errors: creator.errors }, status: :conflict
      else
        render json: { errors: creator.errors }, status: :unprocessable_entity
      end
    end
  end
  
  # GET /api/v1/customer/orders/:id/summary
  def summary
    @order = Order.includes(:order_items).find(params[:id])
    render json: @order.as_json(include: { order_items: {} })
  rescue ActiveRecord::RecordNotFound
    render json: { error: '注文が見つかりません' }, status: :not_found
  end
  
  private
  
  def order_params
    params.require(:order).permit(:table_number, :order_type, items: [:menu_id, :quantity])
  end
end
