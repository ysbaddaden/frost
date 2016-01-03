# Getting Started With Frost [Day 1]

What to do after bootstrapping your application? Let's make a read-only blog!

## Model

We start by writing a migration to create our `posts` table:

```crystal
# db/migrations/000001_create_posts.cr

class CreatePosts < Frost::Record::Migration
  set_version {{ __FILE__ }}

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
    order({ created_at: :desc })
  end
end
```

### Testing our Model

We populate some fixtures:

```yaml
# test/fixtures/posts.yml
hello:
  title: hello
  body: hello world
  created_at: 2015-12-01

first:
  title: first
  body: this is my first post
  created_at: 2015-12-02

second:
  title: second
  body: this is my second post
  created_at: 2015-12-03
```

Then write a unit test:

```crystal
# test/models/post_test.cr
require "../test_helper"

class PostTest < Minitest::Test
  def test_latest
    assert_equal [posts(:second), posts(:first), posts(:hello)], Post.latest.to_a
  end
end
```

We can now run our test, but before that we must migrate the test database
(sorry, the test database isn't rebuilt automatically, yet):

```
$ make db_migrate FROST_ENV=test
$ make test
```

Note that each test runs in a transaction that will rollback, so don't worry
about creating or deleting data in a test!


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

Let's render a single post:

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

We render our list of read-only posts:

```ecr
<!-- app/views/posts/index.html.ecr -->

<ul>
  <% posts.each do |post| %>
    <li>
      <%= link_to(post_url(post)) do %>
        <%= post.created_at %>: <%= post.title %>
      <% end %>
    </li>
  <% end %>
</ul>
```

Oh, and let's add a RSS alternative to our list of posts. We first create a new
layout:

```ecr
<!-- app/views/layouts/application.rss.ecr -->
<rss version="2.0">
  <channel>
    <title>My Blog</title>
    <link><%= root_url %></link>
    <lastBuildDate><%= Time.now.rfc822 %></lastBuildDate>

    <%= yield %>
  </channel>
</rss>
```

And our alternative view:

```ecr
<!-- app/views/posts/index.rss.ecr -->

<% posts.limit(2).each do |post| %>
  <item>
    <title><%= post.title %></title>
    <link><%= post_url(post) %></link>
    <description><%= post.body %></description>
    <pubDate><%= post.created_at.try(&.rfc822) %></pubDate>
    <guid isPermaLink="true"><%= post_url(post) %></guid>
  </item>
<% end %>
```


## Testing Controllers and Views

Let's write a test for the redirection:

```crystal
# test/controllers/pages_controller_test.cr
require "../test_helper"

class PagesControllerTest < Frost::Controller::Test
  def test_landing
    get "/"
    assert_redirected_to "http://test.host/posts"
  end
end
```

Let's test our resource:

```crystal
# test/controllers/posts_controller_test.cr
require "../test_helper"

class PostsControllerTest < Frost::Controller::Test
  def test_index
    get "/posts"
    assert_response 200
    assert_select "li a", text: /second/
    assert_select "li a", text: /first/
    assert_select "li a", text: /hello/
  end

  def test_index_rss
    get "/posts.rss"
    assert_response 200
    assert_select "item", count: 2
  end

  def test_show
    get "/posts/#{ posts(:first) }"
    assert_response 200
    assert_select "article h1", text: /first/
    assert_select "article div", text: /this is my first post/
  end
end
```


## Integration Tests

Sorry, not yet (working on it)
