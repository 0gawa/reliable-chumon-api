module Api
  module V1
    module Admin
      class MenusController < ApplicationController
        before_action :set_menu, only: [:show, :update, :destroy]

        # GET /api/v1/admin/menus
        def index
          @menus = Menu.all
          render json: @menus
        end

        # GET /api/v1/admin/menus/:id
        def show
          render json: @menu
        end

        # POST /api/v1/admin/menus
        def create
          @menu = Menu.new(menu_params)

          if @menu.save
            render json: @menu, status: :created
          else
            render json: { errors: @menu.errors.full_messages }, status: :unprocessable_entity
          end
        end

        # PATCH/PUT /api/v1/admin/menus/:id
        def update
          if @menu.update(menu_params)
            render json: @menu
          else
            render json: { errors: @menu.errors.full_messages }, status: :unprocessable_entity
          end
        rescue ActiveRecord::StaleObjectError
          # 楽観的ロック: 他のリクエストによって既に更新されている
          render json: { 
            error: 'Menu was modified by another request', 
            code: 'stale_object' 
          }, status: :conflict
        end

        # DELETE /api/v1/admin/menus/:id
        def destroy
          @menu.destroy
          head :no_content
        end

        private

        def set_menu
          @menu = Menu.find(params[:id])
        end

        def menu_params
          params.require(:menu).permit(:name, :price, :image_url, :is_available, :category)
        end
      end
    end
  end
end
