Rails.application.routes.draw do
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
  # 
  resources :access_records
  post 'get_project_by_client' => 'access_records#get_project_by_client'
end
