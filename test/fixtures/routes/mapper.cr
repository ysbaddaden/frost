require "../../../src/routing/mapper"

Trail::Routing.draw do
  {% for method in %w(options head get post put patch delete) %}
    {{ method.id }} "/match/{{ method.id }}", "mapper#match"
  {% end %}

  match "/", "mapper#root", via: %i(get post delete), as: "root"

  get "/posts/search(.:format)", "mapper#search", as: "search_post"
  get "/posts/:id", "mapper#root", as: "post"
  get "/posts/:post_id/comments/:id(.:format)", "mapper#root", as: "post_comment"
end
