class Api::V1::Customer::MenusController < ApplicationController
  # GET /api/v1/customer/menus
  def index
    @menus = Menu.available.order(:category, :name)
    render json: @menus
  end

  # GET /api/v1/customer/menus/:id
  def show
    @menu = Menu.available.find(params[:id])
    render json: @menu
  rescue ActiveRecord::RecordNotFound
    render json: { error: "メニューが見つかりません" }, status: :not_found
  end
end
