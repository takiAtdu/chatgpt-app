Rails.application.routes.draw do
  root "application#index"

  get 'chats/index', to: 'chats#index'
  get 'chats/input', to: 'chats#input'
  get 'chats/output/', to: 'chats#output'
  get 'chats/chat', to: 'chats#chat'
end
