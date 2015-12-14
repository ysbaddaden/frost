require "../../../src/routing/mapper"

Frost::Routing.draw do
  scope path: "scoop" do
    get "/posts", "posts#index"
  end

  scope name: "scoop" do
    get "/things", "things#index"
  end

  namespace "admin" do
    get "/authors", "authors#index"
  end
end
