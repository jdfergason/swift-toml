[![Build Status](https://travis-ci.org/jdfergason/swift-toml.svg?branch=master)](https://travis-ci.org/jdfergason/swift-toml)
[![codebeat badge](https://codebeat.co/badges/21ffbe72-dd12-4d9d-ad01-cfdf423ea5fa)](https://codebeat.co/projects/github-com-jdfergason-swift-toml)

# SwiftToml

SwiftToml is a TOML parser written in the swift language.  TOML is an intuitive
configuration file format that is designed to be easy for humans to read and
computers to parse.

SwiftToml currently parses files that conform to version 0.4.0 of the TOML spec.

For full details of writing TOML files see the [TOML documentation](https://github.com/toml-lang/toml).

# Quickstart

TOML files are parsed using one of two functions:

1. Read TOML from file
2. Parse TOML from string

Both functions return a Toml object of parsed key/value pairs

## Parse TOML from file on disk

```swift
import Toml
let toml = try Toml(contentsOfFile: "/path/to/file.toml")
```

## Parse TOML from string

```swift
import Toml
let toml = try Toml(withString: "answer = 42")
```

## Get raw values from TOML document

```swift
import Toml
let toml = try Toml(contentsOfFile: "/path/to/file.toml")

// string value
print(toml.string("table1", "name"))

// boolean value
print(toml.bool("table1", "manager"))

// integer value
print(toml.int("table1", "age"))

// double value
print(toml.double("table1", "rating"))

// date value
print(toml.date("table1", "birthday"))

// get value and resolve type at runtime
print(try toml.value("title")!)

// get array of type [String]
let array: [String] = toml.array("locations")!

// get table
let table1 = toml.table("table1")

// iterate over all tables at the root level
for (tablePath, table) in toml.tables() { ... }

// iterate over all tables under table1
for (tablePath, table) in toml.tables("table1") { ... }
```

## Installation

Add the project to  to your Package.swift file as a dependency:

    dependencies: [
        .Package(url: "http://github.com/jdfergason/swift-toml", majorVersion: 1)
    ]

## Compatibility

SwiftToml is compatible with Swift 4.0.3 and TOML 0.4.0.

It has been tested with Swift 4.0.3 on Mac OS X and Ubuntu 16.04. 

## Tests

To run the unit tests checkout the repository and type:

    swift test

## License

[Apache License 2.0](http://www.apache.org/licenses/LICENSE-2.0.txt)
