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

Frost likely won't hit stable until the Crystal programming language is stable.


## INSTALL

Start by cloning the Frost repository, then use the application generator to
bootstrap your project. For example for a `myapp` application:

```
$ git clone https://github.com/ysbaddaden/frost.git
$ crystal frost/src/cli.cr -- new myapp
$ cd myapp
$ crystal deps install
```


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

See [Getting Started With Frost](https://github.com/ysbaddaden/frost/blob/master/guides/GETTING_STARTED.md)
for an example.


## License

Distributed under the MIT License.
See [MIT-LICENSE](https://github.com/ysbaddaden/frost/blob/master/MIT-LICENSE)


## Authors

- The Ruby on Rails Team that modeled an awesome framework.
- Julien Portalier (@ysbaddaden) for bringing it to Crystal.
