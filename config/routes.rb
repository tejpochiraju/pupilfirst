Svapp::Application.routes.draw do


  devise_for :users, controllers: { passwords: 'users/passwords', invitations: 'users/invitations', sessions: 'users/sessions' }
  devise_for :admin_users, ActiveAdmin::Devise.config
  ActiveAdmin.routes(self)

  resources :users, only: [:show, :edit, :update] do
    collection do
      patch 'update_password'
      get 'invite'
      post 'send_invite'
    end
  end

  resources :events

  resources :startup_links, only: :destroy

  resources :startups, only: [:show, :edit, :update] do
    resources :startup_links, only: [:index, :create]
    resources :startup_jobs do
      patch :repost
    # resources :founders do
    # collection do
    #   post :invite
    # end
    end

    member do
      post :confirm_employee
      get :confirm_employee
      get :confirm_startup_link
    end

    collection do
      get 'featured'
    end
  end

  scope 'mentoring', as: 'mentoring', controller: 'mentoring' do
    get '/', action: 'index'
    get 'register', action: 'new_step1'
    post 'register'
    get 'register_2', action: 'new_step2'
    post 'register_2'
    get 'register_3', action: 'new_step3'
    post 'register_3'
    get 'register_4', action: 'new_step4'
    post 'register_4'
    get 'sign_up', action: 'sign_up_form'
    post 'sign_up'
  end

  scope 'partnerships', controller: 'partnerships', as: 'partnerships' do
    get 'confirm/:confirmation_token', action: 'show_confirmation', as: 'show_confirmation'
    post 'confirm/:confirmation_token', action: 'submit_confirmation', as: 'submit_confirmation'
    get 'confirmation_success'
  end

  # get 'team' => 'welcome#team'
  get 'jobs', to: 'startup_jobs#list_all'
  get 'privacy_policy', to: 'welcome#privacy_policy'
  get 'faq', to: 'welcome#faq'

  root 'welcome#index'
end
