Rails.application.routes.draw do
  root "application#index"

  get 'chats/chat', to: 'chats#chat'
  get 'chats/form', to: 'chats#form'
  post 'chats/form_submitted', to: 'chats#form_submitted'
  get 'chats/show/:id', to: 'chats#show'
end
