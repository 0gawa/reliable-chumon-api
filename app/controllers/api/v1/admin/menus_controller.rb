module Api
  module V1
    module Admin
      class MenusController < ApplicationController
        before_action :set_menu, only: [:show, :update, :destroy]

        def index
          @menus = Menu.all
          render json: @menus
        end

        def show
          render json: @menu
        end

        def create
          @menu = Menu.new(menu_params)

          if @menu.save
            render json: @menu, status: :created
          else
            render json: { errors: @menu.errors.full_messages }, status: :unprocessable_entity
          end
        end

        def update
          if @menu.update(menu_params)
            render json: @menu
          else
            render json: { errors: @menu.errors.full_messages }, status: :unprocessable_entity
          end
        rescue ActiveRecord::StaleObjectError
          render_optimistic_lock_error
        end

        def destroy
          @menu.destroy
          head :no_content
        end

        private

        def set_menu
          @menu = Menu.find(params[:id])
        end

        def menu_params
          params.require(:menu).permit(:name, :price, :image_url, :is_available, :category, :lock_version)
        end

        def render_optimistic_lock_error
          render json: { 
            error: 'Menu was modified by another request', 
            code: 'stale_object' 
          }, status: :conflict
        end
      end
    end
  end
end
