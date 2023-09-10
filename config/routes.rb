Rails.application.routes.draw do
  root 'chats#form'
  post 'chats/form_submitted', to: 'chats#form_submitted'
  get 'chats/show/:id', to: 'chats#show'
end
