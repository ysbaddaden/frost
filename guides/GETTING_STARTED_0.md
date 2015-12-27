---
title: "Frost: Getting Started [Day 0]"
layout: application
---

# Getting Started [Day 0]

## Install

Start by cloning the Frost repository, then use the application generator to
bootstrap your project. For example for a `myapp` application:

```
$ git clone https://github.com/ysbaddaden/frost.git
$ crystal frost/src/cli.cr -- new myapp
$ cd myapp
$ crystal deps install
```

## Database

Configure your database by creating the `config/database.yml` file. See
`config/database.yml.example` for an example. Please note that only PostgreSQL
is supported at the moment.

If you don't have a PostgreSQL database, you may create one with the following
commands. Please adapt to your setup. Linux distributions usually have a
`postgres` user, so:

```
$ sudo -u postgres createdb myapp_development
$ sudo -u postgres createdb myapp_test
```

You may have authorized your login user as a PostgreSQL user (default on OS X)
so you may just:

```
$ createdb myapp_development
$ createdb myapp_test
```

## Server

You should now be capable to compile and start your application:

```
$ make run
crystal run bin/db -- migrate
crystal build  myapp.cr -o bin/myapp
bin/myapp
Listening on http://0.0.0.0:9292
```

Trying to access <https://localhost:9292> should greet you with a
`No Such Route: GET "/"` message. Congrats, it worked!

## Next

[Continue to Day 1](GETTING_STARTED_1.html)
