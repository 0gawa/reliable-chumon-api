module Api
  module V1
    module Admin
      class MenusController < ApplicationController
        before_action :set_menu, only: [ :show, :update, :destroy ]

        def index
          menus = Menu.all
          render json: menus
        end

        def show
          render json: @menu
        end

        def create
          menu = Menu.new(menu_params)

          if menu.save
            render json: menu, status: :created
          else
            raise ActiveRecord::RecordInvalid.new(menu)
          end
        end

        def update
          if @menu.update(menu_params)
            render json: @menu
          else
            raise ActiveRecord::RecordInvalid.new(@menu)
          end
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
          params.require(:menu).permit(
            :name,
            :price,
            :image_url,
            :is_available,
            :category,
            :lock_version
          )
        end
      end
    end
  end
end
