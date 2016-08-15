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

// MARK: Parse

public extension Toml {

    // MARK: Public API

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
        try parse(string: source)
    }

    /**
        Parse the string `withString` as TOML.

        - Parameter withString: A string with TOML document

        - Throws: `TomlError.SyntaxError` if the file is invalid

        - Returns: A dictionary with parsed results
    */
    public convenience init(withString string: String) throws {
        self.init()
        try parse(string: string)
    }

    // MARK: Private

    private convenience init(tokens: [Token]) throws {
        self.init()
        try parse(tokens: tokens)
    }

    private func parse(string: String) throws {
        // Convert input into tokens
        let lexer = Lexer(input: string, grammar: Grammar().grammar)
        let tokens = try lexer.tokenize()
        try parse(tokens: tokens)
    }

    /**
        Parse a TOML token stream construct a dictionary.

        - Parameter tokens: Token stream describing a TOML data structure
    */
    private func parse(tokens: [Token]) throws {
        // A dispatch table for parsing TOML tables
        let TokenMap: [Token: (Token, inout [Token]) throws -> ()] = [
            .Identifier("1"): setValue,
            .IntegerNumber(1): setValue,
            .DoubleNumber(1.0): setValue,
            .Boolean(true): setValue,
            .DateTime(Date()): setValue,
            .TableBegin: setTable,
            .ArrayBegin: setArray,
            .TableArrayBegin: setTableArray,
            .InlineTableBegin: setInlineTable
        ]

        // Convert tokens to values in the Toml
        var myTokens = tokens

        while myTokens.count > 0 {
            let token = myTokens.remove(at: 0)
            if case .Key(let val) = token {
                currentKey = val
            } else {
                try TokenMap[token]!(token, &myTokens)
            }
        }
    }

    /**
        Given a TOML token stream construct an array.

        - Parameter tokens: Token stream describing array

        - Returns: Array populated with values from token stream
    */
    private func parse(tokens: inout [Token]) throws -> [Any] {
        var array: [Any] = [Any]()

        while tokens.count > 0 {
            let token = tokens.remove(at: 0)
            switch token {
                case .Identifier(let val):
                    array.append(val)
                case .IntegerNumber(let val):
                    array.append(val)
                case .DoubleNumber(let val):
                    array.append(val)
                case .Boolean(let val):
                    array.append(val)
                case .DateTime(let val):
                    array.append(val)
                case .InlineTableBegin:
                    array.append(try processInlineTable(tokens: &tokens))
                case .ArrayBegin:
                    try checkAndSetArray(check: parse(tokens: &tokens), out: &array)
                default:
                    return array
            }
        }

        return array
    }

    private func processInlineTable(tokens: inout [Token]) throws -> Toml {
        var tableTokens = [Token]()
        while tokens.count > 0 {
            let tableToken = tokens.remove(at: 0)
            if case .InlineTableEnd = tableToken {
                break
            }
            tableTokens.append(tableToken)
        }
        let t = try Toml(tokens: tableTokens)
        return t
    }

    /**
        Given a value token set it's value in the `table`

        - Parameter currToken: A value token that is currently being parsed
        - Parameter tokens: Array of remaining tokens in the stream
    */
    private func setValue(currToken: Token, tokens: inout [Token]) throws {
        var key = keyPath
        key.append(currentKey)
        let hash = String(key)
        let keyExists = data[hash] != nil

        if keyExists {
            throw TomlError.DuplicateKey(hash)
        }

        data[hash] = currToken.value
    }

    /**
        Given a table extract all associated tokens from the stream and create
        a new dictionary.

        - Parameter currToken: A `Token.TableBegin` token
        - Parameter table: Parent table to save resulting table to
    */
    private func setTable(currToken: Token, tokens: inout [Token]) throws {
        var tableExists = false
        var emptyTableSep = false
        // clear out the keyPath
        keyPath.removeAll()

        while tokens.count > 0 {
            let subToken = tokens.remove(at: 0)
            if case .TableEnd = subToken {
                if keyPath.count < 1 {
                    throw TomlError.SyntaxError("Table name must not be blank")
                }

                let keyExists = data[String(keyPath)] != nil
                if keyExists || tables.contains(String(keyPath)) {
                    throw TomlError.DuplicateKey(String(keyPath))
                }

                tables.append(String(keyPath))

                var tableTokens = [Token]()
                while tokens.count > 0 {
                    let tableToken = tokens[0]
                    if case .TableBegin = tableToken {
                        break
                    } else if case .TableArrayBegin = tableToken {
                        break
                    }
                    tokens.remove(at: 0)
                    tableTokens.append(tableToken)
                }

                try parse(tokens: tableTokens)
                tableExists = true
                break
            } else if case .TableSep = subToken {
                if emptyTableSep {
                    throw TomlError.SyntaxError("Must not have un-named implicit tables")
                }
                emptyTableSep = true
            } else if case .Identifier(let val) = subToken {
                emptyTableSep = false
                keyPath.append(val)
            }
        }

        if !tableExists {
            throw TomlError.SyntaxError("Table must contain at least a closing bracket")
        }
    }

    private func setTableArray(currToken: Token, tokens: inout [Token]) throws {
        // clear out the keyPath
        keyPath.removeAll()

        tableLoop: while tokens.count > 0 {
            let subToken = tokens.remove(at: 0)
            if case .TableArrayEnd = subToken {
                if keyPath.count < 1 {
                    throw TomlError.SyntaxError("Table array name must not be blank")
                }

                var tableTokens = [Token]()
                nestedTableLoop: while tokens.count > 0 {
                    let tableToken = tokens[0]

                    // need to include sub tables
                    switch tableToken {
                        case .TableBegin, .TableArrayBegin:
                            // get the key path of the new table
                            var subKeyPath = [String]()
                            subKeyPathLoop: for token in tokens {
                                switch token {
                                    case .Identifier(let val):
                                        subKeyPath.append(val)
                                    case .TableSep, .TableArrayBegin, .TableBegin:
                                        continue
                                    default:
                                        break subKeyPathLoop
                                }
                            }

                            // If the new table is nested within the current one
                            // include it, otherwise we are finished.
                            if subKeyPath.count == 1 {
                                // top-level - break
                                break nestedTableLoop
                            }

                            if subKeyPath[0] != keyPath[0] {
                                // nested table but not part of this table group
                                break nestedTableLoop
                            }

                            // this table should be included because it's a
                            // nested table

                            // .TableBegin || .TableArrayBegin
                            tokens.remove(at: 0)
                            tableTokens.append(tableToken)

                            // skip first name
                            tokens.remove(at: 0) // Identifier
                            tokens.remove(at: 0) // .TableSep

                            while tokens.count > 0 {
                                let nestedToken = tokens[0]
                                tableTokens.append(nestedToken)
                                tokens.remove(at: 0)
                                if case .TableEnd = nestedToken {
                                    break
                                } else if case .TableArrayEnd = nestedToken {
                                    break
                                }
                            }

                        default:
                            tokens.remove(at: 0)
                            tableTokens.append(tableToken)
                    }
                }

                if let _ = data[String(keyPath)] {
                    var arr = data[String(keyPath)] as! [Toml]
                    arr.append(try Toml(tokens: tableTokens))
                    data[String(keyPath)] = arr
                } else {
                    data[String(keyPath)] = [try Toml(tokens: tableTokens)]
                }
                break tableLoop
            } else if case .Identifier(let val) = subToken {
                keyPath.append(val)
            }
        }
    }

    /**
        Given an inline table extract all associated tokens from the stream
        and create a new dictionary.

        - Parameter currToken: A `Token.InlineTableBegin` token
        - Parameter table: Parent table to save resulting inline table to
    */
    private func setInlineTable(currToken: Token, tokens: inout [Token]) throws {
        keyPath.append(currentKey)

        var tableTokens = [Token]()
        while tokens.count > 0 {
            let tableToken = tokens.remove(at: 0)
            if case .InlineTableEnd = tableToken {
                break
            }
            tableTokens.append(tableToken)
        }

        try parse(tokens: tableTokens)
        // This was an inline table so remove from keyPath
        keyPath.removeLast()
    }

    /**
        Given an array save it to the parent table

        - Parameter currToken: A `Token.ArrayBegin` token
        - Parameter table: Parent table to save resulting inline table to
    */
    private func setArray(currToken: Token, tokens: inout [Token]) throws {
        let arr: [Any] = try parse(tokens: &tokens)

        var myKeyPath = keyPath
        myKeyPath.append(currentKey)
        let key = String(myKeyPath)

        // allow empty arrays
        if arr.count == 0 {
            data[key] = arr
            return
        }

        // if not empty; convert array to proper type
        switch arr[0] {
            case is Int:
                if let typedArr = arr as? [Int] {
                    data[key] = typedArr
                } else {
                    throw TomlError.MixedArrayType("Int")
                }
            case is Double:
                if let typedArr = arr as? [Double] {
                    data[key] = typedArr
                } else {
                    throw TomlError.MixedArrayType("Double")
                }
            case is String:
                if let typedArr = arr as? [String] {
                    data[key] = typedArr
                } else {
                    throw TomlError.MixedArrayType("String")
                }
            case is Bool:
                if let typedArr = arr as? [Bool] {
                    data[key] = typedArr
                } else {
                    throw TomlError.MixedArrayType("Bool")
                }
            case is Date:
                if let typedArr = arr as? [Date] {
                    data[key] = typedArr
                } else {
                    throw TomlError.MixedArrayType("Date")
                }
            default:
                // array of arrays leave as any
                data[key] = arr
        }
    }
}
