Rails.application.routes.draw do
  root 'incidents#index'
  
  resources :incidents do
    member do
      post :start_replay
    end
  end
  
  resources :suggestions, only: [:update]
  
  # Action Cable for real-time features
  mount ActionCable.server => '/cable'
end
