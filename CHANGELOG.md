# Change Log
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/)
and this project adheres to [Semantic Versioning](http://semver.org/).

## [Unreleased]
### Changed
- All accessor methods now return `Optionals` and do not throw.  Notably, this
  means that `TomlError.KeyError` is no longer thrown if a missing key is
  requested.
- `Toml.keys` now returns a `Set<[String]> of value key names
- Moved `Toml.setValue(_:[String])` from  the private API to the public API

## [0.3.0] - 2016-08-19
### Added
- Support for iterating over all tables at a given level with `tables(_: [String])`
  method.
    - Resolves [Issue #2](https://github.com/jdfergason/swift-toml/issues/2)
- Added public API call for retrieving a TOML table at a specified level with
  `table(from: [String])` method.

### Changed
- Rename `arrayWithPath(keyPath: [String])` to `array(_: [String])` for consistency
  with the rest of the public API.

### Fixed
- `hasTable(_: [String])` now correctly returns true for implicitly defined tables.

## [0.2.0] - 2016-08-16
### Changed
- Updated to Swift 3.0 preview 6

## [0.1.0] - 2016-08-14
### Added
- Parse [TOML 0.4.0](https://github.com/toml-lang/toml) files with Swift 3.0

[Unreleased]: https://github.com/jdfergason/swift-toml/compare/v0.3.0...HEAD
[0.3.0]: https://github.com/jdfergason/swift-toml/compare/v0.2.0...v0.3.0
[0.2.0]: https://github.com/jdfergason/swift-toml/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/jdfergason/swift-toml/tree/v0.1.0