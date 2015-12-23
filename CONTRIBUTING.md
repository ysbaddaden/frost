# Contributing

Thanks for considering to contribute to Frost!

Here are some guidelines to help you get started.


## What to contribute?

We are welcoming any contribution that:

- fixes bugs;
- improves documentation;
- improves performance without increasing complexity;
- improves the test suite (eg: adding missing tests);
- improves existing features (eg: reduces complexity).

When proposing a feature, please create an issue first, so we can discuss the
best strategy to adopt to implement it, as long as it doesn't bloat the
framework or wouldn't fit better as an external library, of course.


## How to contribute?

We follow the regular GitHub flow:

1. fork and clone the Frost repository;
2. create a branch using one the prefixes `doc`, `fix`, `enhancement` or `feature`;
   for example `fix/create-record-with-hash-like-object` or `doc/belongs-to-associations`;
3. develop your feature (with unit tests);
4. squash your commits, so each commit implements one thing at a time (ie. avoid
   commits that fix a previous commit, squash them into the actual commits).
5. make sure that tests are passing;
6. open a pull request!

We'll then review and comment your patch, which may result in running steps 3-5
multiple times. Do not hesitate to open a pull request early on, we'll may be
able to help you sooner.


## Getting Started

1. Fork and clone the [repository](https://github.com/ysbaddaden/frost).
2. Create a PostgreSQL database for running the Frost::Record tests (eg:
  `createdb frost_test`)
3. copy `.env.example` as `.env` and personnalise the `DATABASE_URL` so it
   points to the database you just created (eg: `postgres://postgres@/frost_test`
   or `postgres://julien:secret@localhost/frost_test`).
4. Run the test suite: `make test` and be sure that every test is passing.
5. You're ready to contribute.

## Contributor Obligations

### License

Any contribution will be made available under the [MIT license][license] which
you are considered to have accepted when you propose a patch.

### Code of Conduct

All contributors abide to the [Code of Conduct][code_of_conduct]. This includes
anybody participating to Frost by contributing code, reporting issues or
commenting on issues and pull requests.

[license]: https://github.com/ysbaddaden/frost/blob/master/LICENSE.md
[code_of_conduct]: https://github.com/ysbaddaden/frost/blob/master/CODE_OF_CONDUCT.md
