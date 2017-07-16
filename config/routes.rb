Rails.application.routes.draw do
  devise_for :users, controllers: { registrations: 'customers' }
  resources :logins, only: %i[index new create] do
    resources :accounts, only: %i[index] do
      resources :transactions, only: %i[index]
    end
  end

  put 'logins/:id', to: 'logins#refresh', as: 'refresh_login'
  get 'logins/:id/reconnect', to: 'logins#reconnect', as: 'reconnect_login'
  put 'logins/:id/reconnect', to: 'logins#update'
  delete 'logins/:id', to: 'logins#destroy', as: 'destroy_login'
  get 'logins/stage', to: 'logins#stage', as: 'stage'

  root 'logins#index'

  get '/users', to: redirect('/users/sign_up')
  get '/users/password', to: redirect('/users/password/new')
end
