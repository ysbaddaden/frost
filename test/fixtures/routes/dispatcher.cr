require "../../../src/routing/mapper"

module Trail::Routing::Mapper
  get "/success", "pages#success"
  get "/failure", "pages#failure"
end
