Temp::Application.routes.draw do
  resources :transactions

  resources :articles

  resources :messages

  resources :participants

  resources :transports

  resources :notices

  resources :issues

  resources :tasks

  get "manage/user"

  devise_for :users

  resources :users do
    resources :tasks
  end

  resources :tasks
  
  resources :users do
    resources :participants
  end

  resources :users do
    resources :messages
  end

  match 'task_list/:task_type' => 'board#task_list'
  match 'task_show/:task_type' => 'board#task_show'
  match 'task_list/:task_type' => 'devise/board#task_list'
  match 'task_show/:task_type' => 'devise/board#task_show'
  match 'do/:id' => 'board#do_task'
  match 't/:action(/:id)' => 'board#(:action)'
  match 'm/:action(/:id)' => 'account#(:action)'

  match 's/:action' => 'site#(:action)'

  root :to => 'site#index'

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
  # root :to => "welcome#index"

  # See how all your routes lay out with "rake routes"

  # This is a legacy wild controller route that's not recommended for RESTful applications.
  # Note: This route will make all actions in every controller accessible via GET requests.
  # match ':controller(/:action(/:id(.:format)))'
end
