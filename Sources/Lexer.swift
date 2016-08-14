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

// MARK: Possible tokens

enum Token: Hashable {
    case Identifier(String)
    case Key(String)
    case IntegerNumber(Int)
    case DoubleNumber(Double)
    case Boolean(Bool)
    case DateTime(Date)
    case ArrayBegin
    case ArrayEnd
    case TableArrayBegin
    case TableArrayEnd
    case InlineTableBegin
    case InlineTableEnd
    case TableBegin
    case TableSep
    case TableEnd
    case Comment(String)

    var hashValue: Int {
        switch self {
        case .Identifier:
            return 0
        case .Key:
            return 1
        case .IntegerNumber:
            return 2
        case .DoubleNumber:
            return 3
        case .Boolean:
            return 4
        case .DateTime:
            return 5
        case .ArrayBegin:
            return 6
        case .ArrayEnd:
            return 7
        case .TableArrayBegin:
            return 8
        case .TableArrayEnd:
            return 9
        case .InlineTableBegin:
            return 10
        case .InlineTableEnd:
            return 11
        case .TableBegin:
            return 12
        case .TableSep:
            return 13
        case .TableEnd:
            return 14
        case .Comment:
            return 15
        }
    }

    var value : Any? {
        switch self {
        case .Identifier(let val):
            return val
        case .Key(let val):
            return val
        case .IntegerNumber(let val):
            return val
        case .DoubleNumber(let val):
            return val
        case .Boolean(let val):
            return val
        case .DateTime(let val):
            return val
        case .Comment(let val):
            return val
        default:
            return nil
        }
    }

}

func == (lhs: Token, rhs: Token) -> Bool {
    return lhs.hashValue == rhs.hashValue
}

typealias TokenGenerator = (String) throws -> Token?

/**
    Utility for trimming string identifiers in key/value pairs
*/
func trimStringIdentifier(_ input: String, _ quote: String = "\"") -> String {
    let pattern = quote + "(.+)" + quote + "[ \t]*="
    let regex = try! NSRegularExpression(pattern: pattern, options: [])
    let matches = regex.matches(in: input, options: [],
        range: NSMakeRange(0, input.utf16.count))
    let nss = (input as NSString)
    return nss.substring(with: matches[0].rangeAt(1))
}

// MARK: Evaluator

/**
    Class to evaluate input text with a regular expression and return tokens
*/
class Evaluator {
    let regex: String
    let generator: TokenGenerator
    let push: [String]?
    let pop: Bool
    let multiline: Bool

    init (regex: String, generator: TokenGenerator,
          push: [String]? = nil, pop: Bool = false, multiline: Bool = false) {
        self.regex = regex
        self.generator = generator
        self.push = push
        self.pop = pop
        self.multiline = multiline
    }

    func evaluate (_ content: String) throws ->
        (token: Token?, index: String.CharacterView.Index)? {
        var token: Token?
        var index: String.CharacterView.Index

        var options: NSRegularExpression.Options = []

        if multiline {
            options = [.dotMatchesLineSeparators]
        }

        if let m = content.match(self.regex, options: options) {
            token = try self.generator(m)
            index = content.index(content.startIndex, offsetBy: m.characters.count)
            return (token, index)
        }

        return nil
    }
}

// MARK: Lexer

/**
    Convert an input string of TOML to a stream of tokens
*/
class Lexer {
    let input: String
    var grammar: [String: [Evaluator]]

    init(input: String) {
        self.input = input

        grammar = [String: [Evaluator]]()

        grammar["comment"] = [
            Evaluator(regex: "[\r\n]", generator: { _ in nil }, pop: true),
            // to enable saving comments in the tokenizer use the following line
            // Evaluator(regex: ".*", generator: { (r: String) in .Comment(r.trim()) }, pop: true)
            Evaluator(regex: ".*", generator: { _ in nil }, pop: true)
        ]

        grammar["string"] = [
            Evaluator(regex: "\"", generator: { _ in nil }, pop: true),
            Evaluator(regex: "([\\u0020-\\u0021\\u0023-\\u005B\\u005D-\\uFFFF]|\\\\\"|\\\\)+",
                generator: { (r: String) in .Identifier(try r.replaceEscapeSequences()) })
        ]

        grammar["literalString"] = [
            Evaluator(regex: "'", generator: { _ in nil }, pop: true),
            Evaluator(regex: "([\\u0020-\\u0026\\u0028-\\uFFFF])+",
                generator: { (r: String) in .Identifier(r) })
        ]

        grammar["multilineString"] = [
            Evaluator(regex: "\"\"\"", generator: { _ in nil }, pop: true),
            // Note: Does not allow multi-line strings that end with double qoutes.
            // This is a common limitation of a variety of parsers I have tested
            Evaluator(regex: "([\n\\u0020-\\u0021\\u0023-\\uFFFF]\"?\"?)*[\n\\u0020-\\u0021\\u0023-\\uFFFF]+",
                generator: { (r: String) in .Identifier(try r.trim().stripLineContinuation().replaceEscapeSequences()) }, multiline: true)
        ]

        grammar["multilineLiteralString"] = [
            Evaluator(regex: "'''", generator: { _ in nil }, pop: true),
            Evaluator(regex: "([\n\\u0020-\\u0026\\u0028-\\uFFFF]'?'?)*[\n\\u0020-\\u0026\\u0028-\\uFFFF]+",
                generator: { (r: String) in .Identifier(r.trim()) }, multiline: true)
        ]

        grammar["tableName"] = [
            Evaluator(regex: "\"", generator: { _ in nil }, push: ["string"]),
            Evaluator(regex: "'", generator: { _ in nil }, push: ["literalString"]),
            Evaluator(regex: "\\.", generator: { _ in .TableSep }),
            // opening [ are prohibited directly within a table declaration
            Evaluator(regex: "\\[", generator: { _ in throw TomlError.SyntaxError("Invalid table declaration: [ not allowed within table name.  Enclose table name in quotes") }),
            // hashes are prohibited directly within a table declaration
            Evaluator(regex: "#", generator: { _ in throw TomlError.SyntaxError("Invalid table declaration: comments not allowed within table name.  Must clost table with ] first.") }),
            Evaluator(regex: "[A-Za-z0-9_-]+", generator: { (r: String) in .Identifier(r) }),
            Evaluator(regex: "\\]\\]", generator: { _ in .TableArrayEnd }, pop: true),
            Evaluator(regex: "\\]", generator: { _ in .TableEnd }, pop: true),
        ]

        grammar["tableArray"] = [
            Evaluator(regex: "\"", generator: { _ in nil }, push: ["string"]),
            Evaluator(regex: "'", generator: { _ in nil }, push: ["literalString"]),
            Evaluator(regex: "\\.", generator: { _ in .TableSep }),
            // opening [ are prohibited directly within a table declaration
            Evaluator(regex: "\\[", generator: { _ in throw TomlError.SyntaxError("Invalid table declaration: [ not allowed within table name.  Enclose table name in quotes") }),
            // hashes are prohibited directly within a table declaration
            Evaluator(regex: "#", generator: { _ in throw TomlError.SyntaxError("Invalid table declaration: comments not allowed within table name.  Must clost table with ] first.") }),
            Evaluator(regex: "[A-Za-z0-9_-]+", generator: { (r: String) in .Identifier(r) }),
            Evaluator(regex: "\\]\\]", generator: { _ in .TableArrayEnd }, pop: true),
        ]

        grammar["value"] = [
            // Ignore white-space
            Evaluator(regex: "[ \t]", generator: { _ in nil }),

            // Arrays
            Evaluator(regex: "\\[", generator: { _ in .ArrayBegin }, push: ["array", "array"], pop: true),

            // Inline tables
            Evaluator(regex: "\\{", generator: { _ in .InlineTableBegin }, push: ["inlineTable"], pop: true),

            // Multi-line string values (must come before single-line test)
            // Special case, empty multi-line string
            Evaluator(regex: "\"\"\"\"\"\"", generator: { _ in .Identifier("") }, pop: true),
            Evaluator(regex: "\"\"\"", generator: { _ in nil }, push: ["multilineString"], pop: true),
            // Multi-line literal string values (must come before single-line test)
            Evaluator(regex: "'''", generator: { _ in nil }, push: ["multilineLiteralString"], pop: true),
            // Special case, empty multi-line string literal
            Evaluator(regex: "''''''", generator: { _ in nil }, push: ["multilineLiteralString"], pop: true),
            // empty single line strings
            Evaluator(regex: "\"\"", generator: { _ in .Identifier("") }, pop: true),
            Evaluator(regex: "''", generator: { _ in .Identifier("") }, pop: true),
            // String values
            Evaluator(regex: "\"", generator: { _ in nil }, push: ["string"], pop: true),
            // Literal string values
            Evaluator(regex: "'", generator: { _ in nil }, push: ["literalString"], pop: true),

            // Ugh, date parsers suck.  Let regex do work for different formats

            // Dates, RFC 3339 w/ fractional seconds and time offset
            Evaluator(regex: "\\d{4}-\\d{2}-\\d{2}T\\d{2}:\\d{2}:\\d{2}.\\d+(Z|z|[-\\+]\\d{2}:\\d{2})", generator: { (r: String) in
                if let date = Date(rfc3339FractionalSecondsFormattedString: r) {
                    return Token.DateTime(date)
                } else {
                    throw TomlError.InvalidDateFormat(r)
                }
            }, pop: true),
            // RFC 3339 w/o fractional seconds and time offset
            Evaluator(regex: "\\d{4}-\\d{2}-\\d{2}T\\d{2}:\\d{2}:\\d{2}(Z|z|[-\\+]\\d{2}:\\d{2})", generator: { (r: String) in
                if let date = Date(rfc3339FormattedString: r) {
                    return Token.DateTime(date)
                } else {
                    throw TomlError.InvalidDateFormat(r)
                }
            }, pop: true),
            // Dates, RFC 3339 w/ fractional seconds and w/o time offset
            Evaluator(regex: "\\d{4}-\\d{2}-\\d{2}T\\d{2}:\\d{2}:\\d{2}.\\d+", generator: { (r: String) in
                if let date = Date(rfc3339LocalFractionalSecondsFormattedString: r) {
                    return Token.DateTime(date)
                } else {
                    throw TomlError.InvalidDateFormat(r)
                }
            }, pop: true),
            // Dates, RFC 3339 w/o fractional seconds and w/o time offset
            Evaluator(regex: "\\d{4}-\\d{2}-\\d{2}T\\d{2}:\\d{2}:\\d{2}", generator: { (r: String) in
                if let date = Date(rfc3339LocalFormattedString: r) {
                    return Token.DateTime(date)
                } else {
                    throw TomlError.InvalidDateFormat(r)
                }
            }, pop: true),
            // Date only
            Evaluator(regex: "\\d{4}-\\d{2}-\\d{2}", generator: { (r: String) in
                if let date = Date(rfc3339LocalFormattedString: r + "T00:00:00") {
                    return Token.DateTime(date)
                } else {
                    throw TomlError.InvalidDateFormat(r)
                }
            }, pop: true),
            // Double values with exponent
            Evaluator(regex: "[-\\+]?[0-9]+(\\.[0-9]+)?[eE][-\\+]?[0-9]+", generator: { (r: String) in .DoubleNumber(Double(r)!) }, pop:true),
            // Double values no exponent
            Evaluator(regex: "[-\\+]?[0-9]+\\.[0-9]+", generator: { (r: String) in .DoubleNumber(Double(r)!) }, pop: true),
            // Integer values
            Evaluator(regex: "[-\\+]?[0-9]+", generator: { (r: String) in .IntegerNumber(Int(r)!) }, pop: true),
            // Boolean values
            Evaluator(regex: "true", generator: { (r: String) in .Boolean(true) }, pop: true),
            Evaluator(regex: "false", generator: { (r: String) in .Boolean(false) }, pop: true),
        ]

        grammar["array"] = [
            // Ignore white-space
            Evaluator(regex: "[ \n\t]", generator: { _ in nil }),

            // Comments
            Evaluator(regex: "#", generator: { _ in nil }, push: ["comment"]),

            // Arrays
            Evaluator(regex: "\\[", generator: { _ in .ArrayBegin }, push: ["array"]),
            Evaluator(regex: "\\]", generator: { _ in .ArrayEnd }, pop: true),
            Evaluator(regex: ",", generator: { _ in nil }, push: ["array"]),
        ] + grammar["value"]!

        grammar["inlineTable"] = [
            // Ignore white-space and commas
            Evaluator(regex: "[ \t,]", generator: { _ in nil }),

            // inline-table
            Evaluator(regex: "\\{", generator: { _ in .InlineTableBegin }, push: ["inlineTable"]),
            Evaluator(regex: "\\}", generator: { _ in .InlineTableEnd }, pop: true),

            // detect key-value
            Evaluator(regex: "[a-zA-Z0-9_-]+[ \t]*=",
                generator: { (r: String) in .Key(r.substring(to: r.index(r.endIndex, offsetBy:-1)).trim()) },
                push: ["value"]),
           // string key
            Evaluator(regex: "\"([\\u0020-\\u0021\\u0023-\\u005B\\u005D-\\uFFFF]|\\\\\"|\\\\)+\"[ \t]*=",
                generator: { (r: String) in .Key(try trimStringIdentifier(r, "\"").replaceEscapeSequences()) },
                push: ["value"]),
            // literal string key
            Evaluator(regex: "'([\\u0020-\\u0026\\u0028-\\uFFFF])+'[ \t]*=",
                generator: { (r: String) in .Key(trimStringIdentifier(r, "'")) },
                push: ["value"]),
        ]

        grammar["root"] = [
            // Ignore white-space
            Evaluator(regex: "[ \t\r\n]", generator: { _ in nil }),

            // Comments
            Evaluator(regex: "#", generator: { _ in nil }, push: ["comment"]),

            // Key / Value
            // bare key
            Evaluator(regex: "[a-zA-Z0-9_-]+[ \t]*=",
                generator: { (r: String) in .Key(r.substring(to: r.index(r.endIndex, offsetBy:-1)).trim()) },
                push: ["value"]),
            // string key
            Evaluator(regex: "\"([\\u0020-\\u0021\\u0023-\\u005B\\u005D-\\uFFFF]|\\\\\"|\\\\)+\"[ \t]*=",
                generator: { (r: String) in .Key(try trimStringIdentifier(r, "\"").replaceEscapeSequences()) },
                push: ["value"]),
            // literal string key
            Evaluator(regex: "'([\\u0020-\\u0026\\u0028-\\uFFFF])+'[ \t]*=",
                generator: { (r: String) in .Key(trimStringIdentifier(r, "'")) },
                push: ["value"]),

            // Array of tables (must come before table)
            Evaluator(regex: "\\[\\[", generator: { _ in .TableArrayBegin }, push: ["tableArray"]),

            // Tables
            Evaluator(regex: "\\[", generator: { _ in .TableBegin }, push: ["tableName"]),
        ]
    }

    func tokenize() throws -> [Token] {
        var tokens = [Token]()
        var content = input
        var stack = [String]()

        stack.append("root")

        while content.characters.count > 0 {
            var matched = false

            // check content against evaluators to produce tokens
            for evaluator in grammar[stack.last!]! {
                if let e = try evaluator.evaluate(content) {
                    if e.token != nil {
                        tokens.append(e.token!)
                    }

                    // should we pop the stack?
                    if evaluator.pop {
                        stack.removeLast()
                    }

                    // should we push onto the stack?
                    if evaluator.push != nil {
                        stack = stack + evaluator.push!
                    }

                    content = content.substring(from: e.index)
                    matched = true
                    break
                }
            }

            if !matched {
                throw TomlError.SyntaxError(content)
            }
        }
        return tokens
    }
}
