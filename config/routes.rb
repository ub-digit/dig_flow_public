DigFlow::Application.routes.draw do
  root :to => "projects#index"

  resources :jobs do
    collection do
      get 'catalog_request'
      get 'import'
      post 'batch_fetch'
      post 'batch_import'
      get 'batch_import_status'
      post 'batch_quality_control'
    end

    member do
      get 'digitizing_begin'
      get 'digitizing_end'
      get 'digitizing_end'
      get 'post_processing_begin'
      get 'post_processing_user_input_begin'
      get 'post_processing_user_input_end'
      get 'post_processing_end'
      get 'quality_control_begin'
      get 'quarantine'
      get 'unquarantine'
      post 'job_edit'
      post 'job_move'
      post 'job_copyright'
      get 'delete'
      get 'print'
      get 'update_priority'
      get 'restart'
    end
  end

  resources :projects do
    member do
      get 'delete'
    end
  end

  resources :users do
    collection do
      get 'login'
      post 'authenticate'
      get 'logout'
      get 'change_password'
    end

    member do
      put 'set_password'
      get 'delete'
      get 'undelete'
    end
  end

  controller :statistics do
    get "statistics" => "statistics#index"
  end

  # The priority is based upon order of creation:
  # first created -> highest priority.

  # Sample of regular route:
  #   match 'products/:id' => 'catalog#view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  #   match 'products/:id/purchase' => 'catalog#purchase', :as => :purchase
  # This route can be invoked with purchase_url(:id => product.id)

  # Sample resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Sample resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Sample resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Sample resource route with more complex sub-resources
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', :on => :collection
  #     end
  #   end

  # Sample resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end

  # You can have the root of your site routed with "root"
  # just remember to delete public/index.html.
  # root :to => 'welcome#index'

  # See how all your routes lay out with "rake routes"

  # This is a legacy wild controller route that's not recommended for RESTful applications.
  # Note: This route will make all actions in every controller accessible via GET requests.
  # match ':controller(/:action(/:id))(.:format)'
end
