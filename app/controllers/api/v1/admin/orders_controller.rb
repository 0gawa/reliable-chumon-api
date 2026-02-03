class Api::V1::Admin::OrdersController < ApplicationController
  before_action :set_order, only: [ :show, :update_status ]

  def index
    orders = Order.includes(:order_items).order(ordered_at: :desc)
    orders = apply_filters(orders)

    render json: orders.as_json(include: { order_items: {} })
  end

  def show
    render json: @order.as_json(include: { order_items: {} })
  end

  def update_status
    if @order.update(status: status_params[:status])
      render json: @order
    else
      raise ActiveRecord::RecordInvalid.new(@order)
    end
  end

  private

  def set_order
    @order = Order.includes(:order_items).find(params[:id])
  end

  def apply_filters(orders)
    orders = orders.by_table(params[:table_number]) if params[:table_number].present?
    orders = orders.by_status(params[:status]) if params[:status].present?
    orders
  end

  def status_params
    params.require(:order).permit(:status)
  end
end
