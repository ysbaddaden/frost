require "../../../src/routing/mapper"

Frost::Routing.draw do
  get "/success", "pages#success"
  get "/failure", "pages#failure"
end
