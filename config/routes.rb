Rails.application.routes.draw do
  mount_devise_token_auth_for 'User', at: 'auth'
  namespace :v1, defaults: { format: :json } do
    get :healthcheck, to: 'sessions#healthcheck'
    mount_devise_token_auth_for 'User', at: 'auth', controllers: {
      registrations: 'v1/registrations',
      sessions: "devise_token_auth/sessions"
    }
    resources :users
  end
end
