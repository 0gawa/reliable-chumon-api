class Api::V1::Admin::OrdersController < ApplicationController
  before_action :set_order, only: [ :show, :update_status ]

  # GET /api/v1/admin/orders
  def index
    @orders = Order.includes(:order_items).order(ordered_at: :desc)

    # フィルタリング
    @orders = @orders.by_table(params[:table_number]) if params[:table_number].present?
    @orders = @orders.by_status(params[:status]) if params[:status].present?

    render json: @orders.as_json(include: { order_items: {} })
  end

  # GET /api/v1/admin/orders/:id
  def show
    render json: @order.as_json(include: { order_items: {} })
  end

  # PATCH /api/v1/admin/orders/:id/status
  def update_status
    if @order.update(status: status_params[:status])
      render json: @order
    else
      render json: { errors: @order.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def set_order
    @order = Order.includes(:order_items).find(params[:id])
  end

  def status_params
    params.require(:order).permit(:status)
  end
end
