/*
 * Copyright 2016 JD Fergason
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import Foundation

/**
    Error thrown when a TOML syntax error is encountered

    - DuplicateKey: Document contains a duplicate key
    - InvalidDateFormat: Date string is not a supported format
    - InvalidEscapeSequence: Unsupported escape sequence used in string
    - InvalidUnicodeCharacter: Non-existant unicode character specified
    - KeyError: Key does not exist
    - MixedArrayType: Array is composed of multiple types, members must all be the same type
    - SyntaxError: Document cannot be parsed due to a syntax error
*/
public enum TomlError: Error {
    case DuplicateKey(String)
    case InvalidDateFormat(String)
    case InvalidEscapeSequence(String)
    case InvalidUnicodeCharacter(Int)
    case KeyError(String)
    case MixedArrayType(String)
    case SyntaxError(String)
}

protocol SetValueProtocol {
    mutating func setValue(key: [String], value: Any)
}

/**
    Data parsed from a TOML document
*/
public class Toml: CustomStringConvertible, SetValueProtocol {
    private var data: [String: Any] = [String: Any]()
    private var tableNames = Set<[String]>()
    private var keyNames = Set<[String]>()

    /**
        Read the specified TOML file from disk.

        - Parameter contentsOfFile: Path of file to read
        - Parameter encoding: Encoding of file

        - Throws: `TomlError.SyntaxError` if the file is invalid
        - Throws: `NSError` if the file does not exist

        - Returns: A dictionary with parsed results
    */
    public convenience init(contentsOfFile path: String,
        encoding: String.Encoding = String.Encoding.utf8) throws {
        self.init()
        let source = try String(contentsOfFile: path, encoding: encoding)
        let parser = Parser(toml: self)
        try parser.parse(string: source)
    }

    /**
        Parse the string `withString` as TOML.

        - Parameter withString: A string with TOML document

        - Throws: `TomlError.SyntaxError` if the file is invalid

        - Returns: A dictionary with parsed results
    */
    public convenience init(withString string: String) throws {
        self.init()
        let parser = Parser(toml: self)
        try parser.parse(string: string)
    }

    /**
        Get an array of all keys in the TOML document.

        - Returns: An array of supported key names
    */
    public var keys: [String] {
        return Array(data.keys)
    }

    /**
        Set the value for the the given key path

        - Parameter key: Array of strings
        - Parameter value: Value to set
    */
    public func setValue(key: [String], value: Any) {
        let path = String(describing: key)
        keyNames.insert(key)
        data[path] = value
    }

    /**
        Add a sub-table

        - Parameter key: Array of strings indicating table path
    */
    public func setTable(key: [String]) {
        tableNames.insert(key)
    }

    /**
        Check if the TOML document contains the specified key.

        - Parameter key: Key path to check
        - Parameter includeTables: Include tables and inline tables in key path check

        - Returns: True if key exists; false otherwise
    */
    public func hasKey(key: [String], includeTables: Bool = true) -> Bool {
        var keyExists = data[String(describing: key)] != nil
        if includeTables {
            keyExists = keyExists || hasTable(key)
        }
        return keyExists
    }

    /**
        Check if the TOML document contains the specified key.

        - Parameter key: Key path to check

        - Returns: True if key exists; false otherwise
    */
    public func hasKey(_ key: String...) -> Bool {
        return hasKey(key: key)
    }

    /**
        Check if the TOML document contains the specified table.

        - Parameter key: Key path to check

        - Returns: True if table exists; false otherwise
    */
    public func hasTable(_ key: [String]) -> Bool {
        let tableNamesLookup = tableNames.map({ String(describing: $0) })
        return tableNamesLookup.contains(String(describing: key))
    }

    /**
        Check if the TOML document contains the specified table.

        - Parameter key: Key path to check

        - Returns: True if key exists; false otherwise
    */
    public func hasTable(_ key: String...) -> Bool {
        return hasTable(key)
    }

    /**
        Get an array of type T from the TOML document

        - Parameter path: Key path of array

        - Throws: `TomlError.KeyError` if the requested key path does not exist
            `RuntimeError` if the array cannot be coerced to type [T]

        - Returns: An array of type [T]
    */
    public func array<T>(_ path: [String]) throws -> [T] {
        if let val = data[String(describing: path)] {
            return val as! [T]
        }

        throw TomlError.KeyError(String(describing: path))
    }

    /**
        Get an array of type T from the TOML document

        - Parameter path: Key path of array

        - Throws: `TomlError.KeyError` if the requested key path does not exist
            `RuntimeError` if the array cannot be coerced to type [T]

        - Returns: An array of type [T]
    */
    public func array<T>(_ path: String...) throws -> [T] {
        return try array(path)
    }

    /**
        Get a boolean value from the specified key path.

        - Parameter path: Key path of value

        - Throws: `TomlError.KeyError` if the requested key path does not exist
            `RuntimeError` if the value cannot be coerced to type boolean

        - Returns: boolean value of key path
    */
    public func bool(_ path: String...) throws -> Bool {
        return try value(path)
    }

    /**
        Get a date value from the specified key path.

        - Parameter path: Key path of value

        - Throws: `TomlError.KeyError` if the requested key path does not exist
            `RuntimeError` if the value cannot be coerced to type date

        - Returns: date value of key path
    */
    public func date(_ path: String...) throws -> Date {
        return try value(path)
    }

    /**
        Get a double value from the specified key path.

        - Parameter path: Key path of value

        - Throws: `TomlError.KeyError` if the requested key path does not exist
            `RuntimeError` if the value cannot be coerced to type double

        - Returns: double value of key path
    */
    public func double(_ path: [String]) throws -> Double {
        return try value(path)
    }

    /**
        Get a double value from the specified key path.

        - Parameter path: Key path of value

        - Throws: `TomlError.KeyError` if the requested key path does not exist
            `RuntimeError` if the value cannot be coerced to type double

        - Returns: double value of key path
    */
    public func double(_ path: String...) throws -> Double {
        return try double(path)
    }

    /**
        Get a double value from the specified key path.

        - Parameter path: Key path of value

        - Throws: `TomlError.KeyError` if the requested key path does not exist
            `RuntimeError` if the value cannot be coerced to type double

        - Returns: double value of key path
    */
    public func float(_ path: String...) throws -> Double {
        return try double(path)
    }

    /**
        Get a int value from the specified key path.

        - Parameter path: Key path of value

        - Throws: `TomlError.KeyError` if the requested key path does not exist
            `RuntimeError` if the value cannot be coerced to type int

        - Returns: int value of key path
    */
    public func int(_ path: String...) throws -> Int {
        return try value(path)
    }

    /**
        Get a string value from the specified key path.

        - Parameter path: Key path of value

        - Throws: `TomlError.KeyError` if the requested key path does not exist
            `RuntimeError` if the value cannot be coerced to type string

        - Returns: string value of key path
    */
    public func string(_ path: String...) throws -> String {
        return try value(path)
    }

    /**
        Get a dictionary of all tables 1-level down from the given key
        path.  To get all tables at the root level call with no parameters.

        - Parameter parent: Root key path

        - Throws: `TomlError.KeyError` if the requested key path does not exist

        - Returns: Dictionary of key names and tables
    */
    public func tables(_ parent: String...) throws -> [String: Toml] {
        var result = [String: Toml]()
        for tableName in tableNames {
            var tableParent = tableName
            tableParent.removeLast()
            if parent == tableParent {
                // this is a table to include
                result[tableName.map(quoted).joined(separator: ".")] = try table(from: tableName)
            }
        }
        return result
    }

    /**
        Return a TOML table that contains everything beneath the specified
        path.

        - Parameter from: Key path to create table from

        - Throws: `TomlError.KeyError` if the requested key path does not exist

        - Returns: `Toml` table of all keys beneath the specified path
    */
    public func table(from path: [String]) throws -> Toml {
        let constructedTable = Toml()

        // add values
        for keyName in keyNames {
            var keyArray = keyName
            if keyArray.begins(with: path) {
                keyArray.removeSubrange(0..<path.count)
                constructedTable.setValue(key: keyArray, value: try self.value(keyName))
            }
        }

        // add tables
        for tableName in tableNames {
            var tableArray = tableName
            if tableArray.begins(with: path) {
                tableArray.removeSubrange(0..<path.count)
                if tableArray.count != 0 {
                    constructedTable.setTable(key: tableArray)
                }
            }
        }

        return constructedTable
    }

    /**
        Get a TOML table from the document

        - Parameter path: Key path of value

        - Throws: `TomlError.KeyError` if the requested key path does not exist
            `RuntimeError` if the value requested is not a table

        - Returns: Table of name `path`
    */
    public func table(_ path: String...) throws -> Toml {
        return try table(from: path)
    }

    /**
        Get a value of type T from the specified key path.

        - Parameter path: Key path of value

        - Throws: `TomlError.KeyError` if the requested key path does not exist
            `RuntimeError` if the value cannot be coerced to type T

        - Returns: value of key path
    */
    public func value<T>(_ path: String...) throws -> T {
        return try value(path)
    }

    private func value<T>(_ path: [String]) throws -> T {
        if let val = data[String(describing: path)] {
            return val as! T
        }

        throw TomlError.KeyError(String(describing: path))
    }

    /**
        Get a string representation of the TOML document

        - Returns: String version of TOML document
    */
    public var description: String {
        return "\(String(describing: data))"
    }
}
