Rails.application.routes.draw do
  root 'incidents#index'
  
  resources :incidents do
    member do
      post :start_replay
      get :export
    end
    resources :tasks, only: [:create]
    resources :flags, only: [:create]
  end
  
  resources :suggestions, only: [:update]
  
  # Action Cable for real-time features
  mount ActionCable.server => '/cable'
end
