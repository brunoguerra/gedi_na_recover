
Gedi::Engine.routes.prepend do
  resources :nas do
    post :multi, :on => :collection
    get :list, :on => :collection
    post :accept, :on => :member
  end
end
