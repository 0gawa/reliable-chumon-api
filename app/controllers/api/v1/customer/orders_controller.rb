class Api::V1::Customer::OrdersController < ApplicationController
  def create
    creator = build_order_creator
    order = creator.call

    if creator.success?
      render_order_success(order, creator.duplicate?)
    else
      render_order_error(creator)
    end
  end

  def summary
    @order = Order.includes(:order_items).find(params[:id])
    render json: @order.as_json(include: { order_items: {} })
  rescue ActiveRecord::RecordNotFound
    render json: { error: "注文が見つかりません" }, status: :not_found
  end

  private

  def build_order_creator
    OrderCreator.new(
      table_number: order_params[:table_number],
      items: order_params[:items],
      order_type: order_params[:order_type] || "dine_in",
      idempotency_key: request.headers["X-Idempotency-Key"]
    )
  end

  def render_order_success(order, duplicate)
    status = duplicate ? :ok : :created
    render json: order.as_json(include: { order_items: {} }), status: status
  end

  def render_order_error(creator)
    status = error_status_for(creator)
    render json: { errors: creator.errors }, status: status
  end

  def error_status_for(creator)
    deadlock_detected?(creator) ? :conflict : :unprocessable_entity
  end

  def deadlock_detected?(creator)
    creator.errors.any? { |err| err.include?("deadlock") }
  end

  def order_params
    params.require(:order).permit(:table_number, :order_type, items: [ :menu_id, :quantity ])
  end
end
