require "../../../src/routing/mapper"

Trail::Routing.draw do
  get "/success", "pages#success"
  get "/failure", "pages#failure"
end
