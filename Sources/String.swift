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

extension String {
    func trim() -> String {
        return self.trimmingCharacters(in: NSCharacterSet.whitespacesAndNewlines)
    }

    func stripLineContinuation() -> String {
        var s = self
        let regex = try! NSRegularExpression(pattern: "\\\\(\\s+)",
            options: [.dotMatchesLineSeparators])
        let matches = regex.matches(in: s, options: [],
            xrange: NSMakeRange(0, s.utf16.count))
        let nss = (s as NSString)

        for match in matches {
            let m0 = nss.substring(with: match.rangeAt(0))
            s = s.replacingOccurrences(of: m0, with: "")
        }

        return s
    }

    func replaceEscapeSequences() throws -> String {
        var s = "" // new string that is being constructed
        var escape = false
        var unicode = ""
        var unicodeSize = -1

        for char in self.characters {
            if escape {
                if unicodeSize == 0 {
                    // check if it's a valid character
                    let code = Int(strtoul(unicode, nil, 16))

                    if code < 0x0 || (code > 0xD7FF && code < 0xE000) || code > 0x10FFFF {
                        throw TomlError.InvalidUnicodeCharacter(code)
                    }

                    s += String(UnicodeScalar(code))
                    escape = false
                    unicodeSize = -1
                    unicode = ""

                    s += String(char)
                } else if unicodeSize > 0 {
                    unicodeSize -= 1
                    unicode += String(char)
                } else {
                    switch char {
                        case "n":
                            s += "\n"
                            escape = false
                        case "\\":
                            s += "\\"
                            escape = false
                        case "\"":
                            s += "\""
                            escape = false
                        case "f":
                            s += "\u{000C}"
                            escape = false
                        case "b":
                            s += "\u{0008}"
                            escape = false
                        case "t":
                            s += "\t"
                            escape = false
                        case "r":
                            s += "\r"
                            escape = false
                        case "u":
                            unicodeSize = 4
                        case "U":
                            unicodeSize = 8
                        default:
                            throw TomlError.InvalidEscapeSequence("\\" + String(char))
                    }
                }
            } else if char == "\\" {
                escape = true
            } else {
                s += String(char)
            }
        }

        if unicodeSize == 0 {
            // check if it's a valid character
            let code = Int(strtoul(unicode, nil, 16))

            if code < 0x0 || (code > 0xD7FF && code < 0xE000) || code > 0x10FFFF {
                throw TomlError.InvalidUnicodeCharacter(code)
            }

            s += String(UnicodeScalar(code))
        }

        return s
    }
}
