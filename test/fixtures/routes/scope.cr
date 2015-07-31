require "../../../src/routing/mapper"

module Trail::Routing::Mapper
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
