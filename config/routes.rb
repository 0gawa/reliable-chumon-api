Rails.application.routes.draw do
  mount Rswag::Ui::Engine => '/api-docs'
  mount Rswag::Api::Engine => '/api-docs'
  get "up" => "rails/health#show", as: :rails_health_check

  namespace :api do
    namespace :v1 do
      namespace :admin do
        resources :menus
        resources :orders, only: [ :index, :show ] do
          member do
            patch :update_status
          end
        end

        namespace :analytics do
          get :daily
          get :summary
        end
      end

      namespace :customer do
        resources :menus, only: [ :index, :show ]
        resources :orders, only: [ :create ] do
          member do
            get :summary
          end
        end
      end
    end
  end
end
