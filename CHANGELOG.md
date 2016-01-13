# The Frost Changelog

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
