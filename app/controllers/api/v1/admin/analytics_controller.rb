module Api
  module V1
    module Admin
      class AnalyticsController < ApplicationController
        def daily
          stats = MenuDailyStat.includes(:menu)
                               .by_date_range(start_date, end_date)

          stats = stats.by_menu(params[:menu_id]) if params[:menu_id].present?
          stats = stats.ordered_by_date

          render json: stats.as_json(include: { menu: { only: [ :id, :name, :category ] } })
        end

        def summary
          stats = MenuDailyStat.by_date_range(start_date, end_date)

          render json: {
            start_date: start_date,
            end_date: end_date,
            total_sales_amount: stats.sum(:total_sales_amount),
            total_quantity: stats.sum(:total_quantity),
            unique_menus_count: stats.distinct.count(:menu_id)
          }
        end

        private

        def start_date
          params[:start_date]&.to_date || 30.days.ago.to_date
        end

        def end_date
          params[:end_date]&.to_date || Date.current
        end
      end
    end
  end
end
