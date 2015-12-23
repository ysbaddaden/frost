# Getting Started With Frost

What to do after bootstrapping your application? Let's make a read-only blog!

## Model

We start by writing a migration to create our `posts` table:

```crystal
# db/migrations/000001_create_posts.cr

class CreatePosts < Frost::Record::Migration
  up do
    create_table :posts do |t|
      t.string :title
      t.text   :body
      t.timestamps
    end
  end

  down do
    drop_table :posts
  end
end
```

We may now migrate our database:

```
$ make db_migrate
```

And create our model with a scope:

```crystal
# app/models/post.cr

class Post < Frost::Record
  def self.latest
    order("created_at DESC")
  end
end
```

### Testing our Model

We populate some fixtures:

```yaml
# test/fixtures/posts.yml
hello:
  title: hello
  body: ...
  created_at: 2015-12-01

first:
  title: first
  body: ...
  created_at: 2015-12-02

second:
  title: second
  body: ...
  created_at: 2015-12-03
```

Then write a unit test:

```crystal
# test/models/post_test.cr
require "../test_helper"

class PostTest < Minitest::Test
  def test_latest
    assert_equal [posts(:second), posts(:first), posts(:hello)], Post.latest
  end
end
```

Each single test runs in a transaction that will rollback, so don't worry about
creating or deleting data in a test!


## Controller

Let's write a route to access our posts, and add a redirection from `/` to our
list of posts:

```crystal
# config/routes.cr
require "frost/routing/mapper"

Frost::Routing.draw do
  resources :posts, only: %i(show index)
  get "/", "pages#landing", as: "root"
end
```

We create our redirection:

```crystal
# app/controllers/pages_controller.cr

class PagesController < ApplicationController
  def landing
    redirect_to posts_url
  end
end
```

We write down our resource controller:

```crystal
# app/controllers/posts_controller.cr

class PostsController < ApplicationController
  getter! :posts, :post # so they're accessible from templates

  def index
    @posts = Post.latest.select(:id, :title, :created_at)
  end

  def show
    @post = Post.find(params["id"])
  end
end
```

At this stage our application should compile and run. Try `make run` then access
http://localhost:9292/ and see what happens.

## Views

Let's render our list of read-only posts:

```ecr
<!-- app/views/posts/index.html.ecr -->

<ul>
  <% posts.each do |post| %>
    <li>
      <%= link_to post_url(post) do %>
        <%= post.created_at %>: <%= post.title %>
      <% end %>
    </li>
  <% end %>
</ul>

```

And render a single post:

```ecr
<!-- app/views/posts/show.html.ecr -->

<article>
  <header>
    <h1><%= post.title %></h1>
    <p><%= post.created_at %></p>
  </header>

  <div><%= post.body %></div>

  <p><%= link_to "permalink", post_url(post) %></p>
</article>
```


## Testing Controllers and Views

Let's write a test for the redirection:

```crystal
# test/controllers/pages_controller_test.cr
require "../test_helper"

class PagesControllerTest < Frost::Controller::Test
  def test_landing
    get "/"
    assert_redirected_to "/posts"
  end
end
```

Let's test our resource:

```crystal
# test/controllers/posts_controller_test.cr
require "../test_helper"
require "xml"

class PostsControllerTest < Frost::Controller::Test
  def test_index
    get "/posts"
    assert_response 200

    assert_equal [
      "#{ posts(:second).created_at }: #{ posts(:second).title) }",
      "#{ posts(:first).created_at }: #{ posts(:first).title) }",
      "#{ posts(:hello).created_at }: #{ posts(:hello).title) }",
    ], nodes("//li/a").map(&.text.try(&.strip))
  end

  def test_show
    get "/posts/#{ posts(:first) }"
    assert_response 200
    assert_equal posts(:first).title, node("//article/h1").text
    assert_equal posts(:first).tbody, node("//article/div").text
  end

  private def nodes(search)
    XML.parse_html(response.body).xpath_nodes(search)
  end

  private def node(search)
    XML.parse_html(response.body).xpath_nodes(search).first
  end
end
```

Sorry, no `assert_select` or wrapper around XML yet (working on it)


## Integration Tests

Sorry, not yet (working on it)

