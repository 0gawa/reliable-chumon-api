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
            render json: menu.as_json, status: :created
          else
            raise ActiveRecord::RecordInvalid.new(menu)
          end
        end

        def update
          if params.dig(:menu, :lock_version).blank?
            render_custom_error(
              status: :unprocessable_entity,
              code: 'MISSING_LOCK_VERSION',
              message: 'lock_version is required for updating menu'
            )
            return
          end

          if @menu.update(menu_params)
            render json: @menu.as_json
          else
            raise ActiveRecord::RecordInvalid.new(@menu)
          end
        rescue ActiveRecord::StaleObjectError
          render_custom_error(
            status: :conflict,
            code: 'STALE_OBJECT',
            message: 'The menu has been modified by another request'
          )
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
