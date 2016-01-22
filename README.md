# Frost

Full featured MVC Web Framework for the Crystal programming language, largely
inspired by Ruby on Rails (ie. implements most of its API).

Frost is to Ruby on Rails what Crystal is to Ruby: similar API, developer
hapiness and productivity, but enhanced with static typing (mostly hidden) and
incredible performance.


## STATUS: DEVELOPER PREVIEW

Frost is in _developer preview_, and must be considered alpha software until
further notice. Features may be added, dropped, tweaked, or changed at any
time. Please experiment with Frost, contribute to Frost, let's make it
incredible, but build software with it at your own risk!

TLDR: using Frost is like using Crystal. It's great, but be prepared to fix
your software on a regular basis.

You've been warned :-)


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


## Requirements

Since Crystal introduces changes on a regular basis, Frost may not compile
with the version of Crystal you are using.

The Frost master branch should follow changes in Crystal's master branch,
and thus require the Crystal master branch.

Frost releases should always be usable with the latest Crystal release. In
some cases it may require the previous Crystal release. In this case,
switching to the Frost master branch should fix the compilation errors
until a new Frost release is made.


## Contribute

Thanks for considering to contribute! Please see
[CONTRIBUTES](https://github.com/ysbaddaden/frost/blob/master/CONTRIBUTES.md)
to get started.


## License

Distributed under the MIT License.
See [MIT-LICENSE](https://github.com/ysbaddaden/frost/blob/master/MIT-LICENSE)


## Authors

- The Ruby on Rails Team that modeled an awesome framework.
- Julien Portalier (@ysbaddaden) for bringing it to Crystal.
