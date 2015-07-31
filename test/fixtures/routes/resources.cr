require "../../../src/routing/mapper"

module Trail::Routing::Mapper
  resources :posts do
    resources :comments
    resource :user

    member do
      post :publish
    end

    collection do
      get :search
    end
  end

  resource :user do
    resources :comments
    get :posts
  end

  resources :rs1s, only: :index
  resources :rs2s, only: "show"
  resources :rs3s, only: %i(new edit)
  resources :rs4s, only: %w(create update replace destroy)

  resource :r1, only: :replace
  resource :r2, only: "show"
  resource :r3, only: %i(new edit)
  resource :r4, only: %w(create update destroy)
end
