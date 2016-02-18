# The Frost Changelog

## v0.2.2 - 2016-02-18

Fixes:
- Upgraded to Crystal 0.11: matches redesign of HTTP::Server
- Upgraded to Crystal 0.12: minor changes
- Use ECR escapes to generate application layout
- Record#initialize now uses setter methods
- Allow classes inheriting Record to be abstract (ie. `abstract ApplicationModel < Frost::Record`)
- Always save Record datetimes at UTC
- Parse time strings: ISO8601, RFC822, JSON (as generally accepted)

Features:
- `link_to_if` and `link_to_unless` view helpers

## v0.2.1 - 2016-01-22

Security Fixes:
- File traversal vulnerability in PublicFileHandler

Fixes:
- Application generator failed to compile

## v0.2.0 - 2016-01-13

Security Fixes:
- Directory traversal vulnerability in PublicFileHandler
- MessageVerifier#verify always returned true (affected session cookie signatures)

Features:
- Crystal 0.10.1 compatibility
- `concat` view helper
- Reworked Frost::Controller::Test methods for testing controllers (with documentation)
- JSON Serialization of records (basic)
- HttpsEverywhereHandler to redirect traffic from HTTP to HTTPS

Fixes:
- LLVM failure with empty routes (affected OS X)
- View helpers: tests and corrections (mostly Hash value types)
- `css_to_xpath` couldn't have brackets in string
- Recover from failed PG connections (eg: draconian )

## v0.1.0 - 2015-12-25

Initial Release
