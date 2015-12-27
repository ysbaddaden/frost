---
title: "Frost: Getting Started [Day 1]"
layout: application
---

# Getting Started [Day 1]

What to do after [bootstrapping your application](GETTING_STARTED_0.html)?
Let's make a read-only blog!

## Model

We start by writing a migration to create our `posts` table (notice that the up
and down are blocks):

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

```crystal
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
    assert_equal [posts(:second), posts(:first), posts(:hello)],
      Post.latest
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
<http://localhost:9292/> and see what happens.

## Views

Let's render a single post:

```erb
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

```erb
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

Now, restarting our app, and loading <http://localhost:9292/> should greet us
with a nice list of posts (as long as you populated the `posts` table with some
data first) and you should be able to read your posts! Congrats, you have a
working read-only blog!

### Let's add a RSS alternative to our list of posts

We first create a new layout. We didn't create one for our HTML template,
because the `application.html.ecr` layout already existed (but you're welcome to
customize it). So, let's create our RSS layout:

```erb
<!-- app/views/layouts/application.rss.ecr -->
<rss version="2.0">
  <channel>
    <title>My Blog</title>
    <link><%= root_url %></link>
    <lastBuildDate><%= Time.now %></lastBuildDate>

    <%= yield %>
  </channel>
</rss>
```

And our alternative view:

```erb
<!-- app/views/posts/index.rss.ecr -->

<% posts.limit(2).each do |post| %>
  <item>
    <title><%= post.title %></title>
    <link><%= post_url(post) %></link>
    <description><%= post.body %></description>
    <pubDate><%= post.updated_at %></pubDate>
    <guid isPermaLink="true"><%= post_url(post) %></guid>
  </item>
<% end %>
```

Restarting and loading <http://localhost:9292/posts.rss> should print our RSS
feed. Frost was smart enough to understand that we wanted the RSS feed from the
`.rss` format present in the URL. Change it to something like `.xml` to see it
fail to find an `index.xml.ecr` template.


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
    assert_select "li a", text: posts(:second).title
    assert_select "li a", text: posts(:first).title
    assert_select "li a", text: posts(:hello).title
  end

  def test_index_rss
    get "/posts.rss"
    assert_response 200
    assert_select "item", count: 2
  end

  def test_show
    get "/posts/#{ posts(:first) }"
    assert_response 200
    assert_select, "article h1", text: posts(:first).title
    assert_select, "article div", text: posts(:first).body
  end
end
```


## Integration Tests

Sorry, not yet (working on it)
