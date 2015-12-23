# Frost

Full featured MVC Web Framework for the Crystal programming language, largely
inspired by Ruby on Rails (ie. implements most of its API).

Frost is to Ruby on Rails what Crystal is to Ruby: similar API, developer
hapiness and productivity, but enhanced with static typing (mostly hidden) and
incredible performance.


## STATUS: DEVELOPER PREVIEW

**WARNING**: Frost is in _developer preview_, and must be considered alpha
software until further notice. features may be added, dropped, tweaked, or
changed dramatically at any time. Please experiment with Frost, contribute to
Frost, let's make it incerdiable, but build software out of it at your own risk!
You've been warned :-)

Frost won't hit stable until the Crystal programming language is stable anyway.


## INSTALL

Start by cloning the Frost repository, then use the application generator to
bootstrap your project. For example for a `myapp` application:

```
$ git clone https://github.com/ysbaddaden/frost.git
$ crystal frost/src/cli.cr -- new myapp
$ cd myapp
$ crystal deps install
```

### Database

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

### Server

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


## Getting Started

Nothing fancy, just the regular flow:

Data:
- write migrations in `db/migrations`;
- create models in `app/models`;
- write tests in `test/models`.

Application Logic:
- add routes to `config/routes.cr`;
- create controllers and actions in `app/controllers`;
- design views in `app/views`;
- write tests in `test/controllers`.

See [Getting Started With Frost] for an example application.


## License

Distributed under the MIT License.


## Authors

- The Ruby on Rails Team that modeled an awesome framework.
- Julien Portalier (@ysbaddaden) for bringing it to Crystal.
