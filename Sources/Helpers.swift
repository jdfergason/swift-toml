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
    Utility function to cast an array to a given type or throw an error

    - Parameter array: Input array to cast to type T
    - Parameter out: Array to store result in

    - Throws: `TomlError.MixedArrayType` if array cannot be casted to appropriate type
*/
func checkAndSetArray(check: [Any], out: inout [Any]) throws {
    // allow empty arrays
    if check.count == 0 {
        out.append(check)
        return
    }

    // convert array to proper type
    switch check[0] {
        case is Int:
            if let typedArray = check as? [Int] {
                out.append(typedArray)
            } else {
                throw TomlError.MixedArrayType("Int")
            }
        case is Double:
            if let typedArray = check as? [Double] {
                out.append(typedArray)
            } else {
                throw TomlError.MixedArrayType("Double")
            }
        case is String:
            if let typedArray = check as? [String] {
                out.append(typedArray)
            } else {
                throw TomlError.MixedArrayType("String")
            }
        case is Bool:
            if let typedArray = check as? [Bool] {
                out.append(typedArray)
            } else {
                throw TomlError.MixedArrayType("Bool")
            }
        case is Date:
            if let typedArray = check as? [Date] {
                out.append(typedArray)
            } else {
                throw TomlError.MixedArrayType("Date")
            }
        default:
            // array of arrays leave as any
            out.append(check)
    }
}

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
