class Api::V1::Customer::OrdersController < ApplicationController
  def create
    creator = build_order_creator
    order = creator.call

    if creator.success?
      render_order_success(order, creator.duplicate?)
    else
      render_order_errors(creator)
    end
  end

  def summary
    order = Order.includes(:order_items).find(params[:id])
    render json: order.as_json(include: { order_items: {} })
  end

  private

  def build_order_creator
    OrderCreator.new(
      table_number: order_params[:table_number],
      items: order_params[:items],
      order_type: order_params[:order_type] || "dine_in",
      idempotency_key: idempotency_key_from_header
    )
  end

  def idempotency_key_from_header
    request.headers["X-Idempotency-Key"]
  end

  def render_order_success(order, duplicate)
    status = duplicate ? :ok : :created
    render json: order.as_json(include: { order_items: {} }), status: status
  end

  def render_order_errors(creator)
    if deadlock_detected?(creator)
      render_deadlock
    else
      render_validation_errors(creator)
    end
  end

  def render_validation_errors(creator)
    render_custom_error(
      status: :unprocessable_entity,
      code: ErrorCode::VALIDATION_ERROR,
      message: "Order creation failed",
      details: { errors: creator.errors }
    )
  end

  def deadlock_detected?(creator)
    creator.errors.any? { |error| error.include?("deadlock") }
  end

  def order_params
    params.require(:order).permit(:table_number, :order_type, items: [:menu_id, :quantity])
  end
end
