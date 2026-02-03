class Api::V1::Customer::MenusController < ApplicationController
  def index
    menus = Menu.available.order(:category, :name)
    render json: menus
  end

  def show
    menu = Menu.available.find(params[:id])
    render json: menu
  end
end
