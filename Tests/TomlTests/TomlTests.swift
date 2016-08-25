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

import XCTest
@testable import Toml

class TomlTests: XCTestCase {
    func testSimple() {
        let actual = try! Toml(contentsOfFile: "Tests/TomlTests/simple.toml")
        XCTAssertEqual(actual.string("string"), "value")
        XCTAssertEqual(actual.string("literal_string"), "lite\\ral")
        XCTAssertEqual(actual.int("int"), 1)
        XCTAssertEqual(actual.double("float"), 3.14)
        XCTAssertEqual(actual.bool("bool"), true)
        XCTAssertEqual(actual.date("date"), Date(rfc3339String: "1982-07-27T12:00:00.0Z"))
        XCTAssertEqual(actual.string("inline_table", "1"), "one")
        XCTAssertEqual(actual.string("inline_table", "3"), "three")

        // check hasKey and hasTable
        XCTAssertTrue(actual.hasTable("inline_table"))
        XCTAssertTrue(actual.hasKey("inline_table", "1"))
        XCTAssertFalse(actual.hasTable("non-existant-table"))
        XCTAssertFalse(actual.hasKey("inline_table", "4"))

        XCTAssertEqual(actual.array("array"), [1, 2, 3])
    }

    func testSerialize() {
        let actual = try! Toml(contentsOfFile: "Tests/TomlTests/serialize.toml")
        let expected = try! String(contentsOfFile: "Tests/TomlTests/expected-serialize.toml")
        XCTAssertEqual(String(describing: actual), expected.trim())
    }

    func testImplicitlyDefinedTable() {
        let actual = try! Toml(contentsOfFile: "Tests/TomlTests/nested-tables.toml")
        XCTAssertTrue(actual.hasTable("table2"))
    }

    func testNestedTables() {
        let actual = try! Toml(contentsOfFile: "Tests/TomlTests/nested-tables.toml")
        // All tables
        var expectedKeys = ["table1", "table2"]
        var actualKeys: [String] = []
        for (key, _) in actual.tables() {
            actualKeys.append(key)
        }
        expectedKeys.sort()
        actualKeys.sort()

        XCTAssertEqual(String(describing: expectedKeys), String(describing: actualKeys))
        let expectedTables = try! String(contentsOfFile: "Tests/TomlTests/expected-nested-tables.toml")

        XCTAssertEqual(expectedTables.trim(), String(describing: actual).trim())
    }

    /* This test fails in TravisCI for some reason ... it passes on my local machine; disable until we figure out what's going on.
    func testDateFormat() {
        let actual = try! Toml(contentsOfFile: "Tests/TomlTests/date-format.toml")
        XCTAssertEqual(actual.date("date1"), Date(rfc3339String: "1979-05-27T07:32:00.0Z")!)
        XCTAssertEqual(actual.date("date2"), Date(rfc3339String: "1979-05-27T07:32:00.5Z")!)
        XCTAssertEqual(actual.date("date3"), Date(rfc3339String: "1979-05-27T00:32:00.6-07:00")!)
        XCTAssertEqual(actual.date("date4"), Date(rfc3339String: "1979-05-27T00:32:00.999999+07:00")!)
        XCTAssertEqual(actual.date("date5"), Date(rfc3339String: "1979-05-27T07:32:00.0", localTime: true)!)
        XCTAssertEqual(actual.date("date6"), Date(rfc3339String: "1979-05-27T07:32:00.5", localTime: true)!)
        XCTAssertEqual(actual.date("date7"), Date(rfc3339String: "1979-05-27T00:00:00.0", localTime: true)!)
    }
    */

    // Tests from TOML repo

    func testTomlExample() {
        let actual = try! Toml(contentsOfFile: "Tests/TomlTests/toml-example.toml")

        // owner
        XCTAssertEqual(actual.string("owner", "name"), "Tom Preston-Werner")
        XCTAssertEqual(actual.string("owner", "organization"), "GitHub")
        XCTAssertEqual(actual.string("owner", "bio"), "GitHub Cofounder & CEO\nLikes tater tots and beer.")
        XCTAssertEqual(actual.date("owner", "dob"), Date(rfc3339String: "1979-05-27T07:32:00.0Z"))

        // database
        XCTAssertEqual(actual.string("database", "server"), "192.168.1.1")
        let ports: [Int] = actual.array("database", "ports")!
        XCTAssertEqual(ports, [8001, 8001, 8002])
        XCTAssertEqual(actual.int("database", "connection_max"), 5000)
        XCTAssertEqual(actual.bool("database", "enabled"), true)

        // servers.alpha
        XCTAssertEqual(actual.string("servers", "alpha", "ip"), "10.0.0.1")
        XCTAssertEqual(actual.string("servers", "alpha", "dc"), "eqdc10")

        // servers.beta
        XCTAssertEqual(actual.string("servers", "beta", "ip"), "10.0.0.2")
        XCTAssertEqual(actual.string("servers", "beta", "dc"), "eqdc10")
        XCTAssertEqual(actual.string("servers", "beta", "country"), "中国")

        // clients
        let data: [Any] = actual.array("clients", "data")!
        XCTAssertEqual(data[0] as! [String], ["gamma", "delta"])
        XCTAssertEqual(data[1] as! [Int], [1, 2])
        let hosts: [String] = actual.array("clients", "hosts")!
        XCTAssertEqual(hosts, ["alpha", "omega"])

        // products array
        let products: [Toml] = actual.array("products")!
        XCTAssertEqual(products[0].string("name"), "Hammer")
        XCTAssertEqual(products[0].int("sku"), 738594937)
        XCTAssertEqual(products[1].string("name"), "Nail")
        XCTAssertEqual(products[1].int("sku"), 284758393)
        XCTAssertEqual(products[1].string("color"), "gray")
    }

    func testHardExample() {
        let actual = try! Toml(contentsOfFile: "Tests/TomlTests/hard_example.toml")
        XCTAssertEqual(actual.string("the", "test_string"), "You'll hate me after this - #")
        let test_array: [String] = actual.array("the", "hard", "test_array")!
        XCTAssertEqual(test_array, ["] ", " # "])
        let test_array2: [String] = actual.array("the", "hard", "test_array2")!
        XCTAssertEqual(test_array2, ["Test #11 ]proved that", "Experiment #9 was a success"])
        XCTAssertEqual(actual.string("the", "hard", "another_test_string"), " Same thing, but with a string #")
        XCTAssertEqual(actual.string("the", "hard", "harder_test_string"), " And when \"'s are in the string, along with # \"")
        XCTAssertEqual(actual.string("the", "hard", "bit#", "what?"), "You don't think some user won't do that?")
        let multi_line_array: [String] = actual.array("the", "hard", "bit#", "multi_line_array")!
        XCTAssertEqual(multi_line_array, ["]"])
    }

    func testHardExampleUnicode() {
        let actual = try! Toml(contentsOfFile: "Tests/TomlTests/hard_example_unicode.toml")
        XCTAssertEqual(actual.string("the", "test_string"), "Ýôú'ℓℓ λáƭè ₥è áƒƭèř ƭλïƨ - #")
        let test_array: [String] = actual.array("the", "hard", "test_array")!
        XCTAssertEqual(test_array, ["] ", " # "])
        let test_array2: [String] = actual.array("the", "hard", "test_array2")!
        XCTAssertEqual(test_array2, ["Tèƨƭ #11 ]ƥřôƲèδ ƭλáƭ", "Éжƥèřï₥èñƭ #9 ωáƨ á ƨúççèƨƨ"])
        XCTAssertEqual(actual.string("the", "hard", "another_test_string"), "§á₥è ƭλïñϱ, βúƭ ωïƭλ á ƨƭřïñϱ #")
        XCTAssertEqual(actual.string("the", "hard", "harder_test_string"), " Âñδ ωλèñ \"'ƨ ářè ïñ ƭλè ƨƭřïñϱ, áℓôñϱ ωïƭλ # \"")
        XCTAssertEqual(actual.string("the", "hard", "βïƭ#", "ωλáƭ?"), "Ýôú δôñ'ƭ ƭλïñƙ ƨô₥è úƨèř ωôñ'ƭ δô ƭλáƭ?")
        let multi_line_array: [String] = actual.array("the", "hard", "βïƭ#", "multi_line_array")!
        XCTAssertEqual(multi_line_array, ["]"])
    }

    // MARK: toml-tests

    func testArrayEmpty() {
        // thevoid = [[[[[]]]]]
        let actual = try! Toml(contentsOfFile: "Tests/TomlTests/array-empty.toml")
        // there should be 5 sub-arrays
        let arr0: [Any] = actual.array("thevoid")!
        let arr1: [Any] = arr0[0] as! [Any]
        let arr2: [Any] = arr1[0] as! [Any]
        let arr3: [Any] = arr2[0] as! [Any]
        let arr4: [Any] = arr3[0] as! [Any]

        XCTAssertEqual(arr4.count, 0)
    }

    func testArrayNospaces() {
        // ints = [1,2,3]
        let actual = try! Toml(contentsOfFile: "Tests/TomlTests/array-nospaces.toml")
        let arr: [Int] = actual.array("ints")!
        XCTAssertEqual(arr, [1,2,3])
    }

    func testArraysHetergeneous() {
        // mixed = [[1, 2], ["a", "b"], [1.1, 2.1]]
        let actual = try! Toml(contentsOfFile: "Tests/TomlTests/arrays-hetergeneous.toml")
        let arr: [Any] = actual.array("mixed")!
        let arr0: [Int] = arr[0] as! [Int]
        let arr1: [String] = arr[1] as! [String]
        let arr2: [Double] = arr[2] as! [Double]

        XCTAssertEqual(arr0, [1, 2])
        XCTAssertEqual(arr1, ["a", "b"])
        XCTAssertEqual(arr2, [1.1, 2.1])
    }

    func testArraysNested() {
        // nest = [["a"], ["b"]]
        let actual = try! Toml(contentsOfFile: "Tests/TomlTests/arrays-nested.toml")
        let arr: [Any] = actual.array("nest")!
        XCTAssertEqual(arr[0] as! [String], ["a"])
        XCTAssertEqual(arr[1] as! [String], ["b"])
    }

    func testArrays() {
        let actual = try! Toml(contentsOfFile: "Tests/TomlTests/arrays.toml")

        let ints: [Int] = actual.array("ints")!
        XCTAssertEqual(ints, [1, 2, 3])

        let floats: [Double] = actual.array("floats")!
        XCTAssertEqual(floats, [1.1, 2.1, 3.1])

        let strings: [String] = actual.array("strings")!
        XCTAssertEqual(strings, ["a", "b", "c"])

        let dates: [Date] = actual.array("dates")!
        XCTAssertEqual(dates, [Date(rfc3339String: "1987-07-05T17:45:00.0Z")!, Date(rfc3339String: "1979-05-27T07:32:00.0Z")!, Date(rfc3339String: "2006-06-01T11:00:00.0Z")!])
    }

    func testBool() {
        let actual = try! Toml(contentsOfFile: "Tests/TomlTests/bool.toml")
        XCTAssertEqual(actual.bool("t"), true)
        XCTAssertEqual(actual.bool("f"), false)
    }

    func testCommentsEverywhere() {
        let actual = try! Toml(contentsOfFile: "Tests/TomlTests/comments-everywhere.toml")
        XCTAssertEqual(actual.int("group", "answer"), 42)
        XCTAssertEqual(actual.array("group", "more"), [42, 42])
    }

    func testDatetime() {
        let actual = try! Toml(contentsOfFile: "Tests/TomlTests/datetime.toml")
        XCTAssertEqual(actual.date("bestdayever"), Date(rfc3339String: "1987-07-05T17:45:00.0Z")!)
    }

    func testEmpty() {
        let _ = try! Toml(contentsOfFile: "Tests/TomlTests/empty.toml")
    }

    func testExample() {
        let actual = try! Toml(contentsOfFile: "Tests/TomlTests/example.toml")
        XCTAssertEqual(actual.date("best-day-ever"), Date(rfc3339String: "1987-07-05T17:45:00.0Z")!)
        XCTAssertFalse(actual.bool("numtheory", "boring")!)
        XCTAssertEqual(actual.array("numtheory", "perfection"), [6, 28, 496])
    }

    func testFloat() {
        let actual = try! Toml(contentsOfFile: "Tests/TomlTests/float.toml")
        XCTAssertEqual(actual.double("pi"), 3.14)
        XCTAssertEqual(actual.double("negpi"), -3.14)
    }

    func testImplicitAndExplicitAfter() {
        let actual = try! Toml(contentsOfFile: "Tests/TomlTests/implicit-and-explicit-after.toml")
        XCTAssertEqual(actual.int("a", "b", "c", "answer"), 42)
        XCTAssertEqual(actual.int("a", "better"), 43)
    }

    func testImplicitAndExplicitBefore() {
        let actual = try! Toml(contentsOfFile: "Tests/TomlTests/implicit-and-explicit-before.toml")
        XCTAssertEqual(actual.int("a", "b", "c", "answer"), 42)
        XCTAssertEqual(actual.int("a", "better"), 43)
    }

    func testImplicitGroups() {
        let actual = try! Toml(contentsOfFile: "Tests/TomlTests/implicit-groups.toml")
        XCTAssertEqual(actual.int("a", "b", "c", "answer"), 42)
    }

    func testInteger() {
        let actual = try! Toml(contentsOfFile: "Tests/TomlTests/integer.toml")
        XCTAssertEqual(actual.int("answer"), 42)
        XCTAssertEqual(actual.int("neganswer"), -42)
    }

    func testKeyEqualsNospace() {
        let actual = try! Toml(contentsOfFile: "Tests/TomlTests/key-equals-nospace.toml")
        XCTAssertEqual(actual.int("answer"), 42)
    }

    func testKeySpace() {
        let actual = try! Toml(contentsOfFile: "Tests/TomlTests/key-space.toml")
        XCTAssertEqual(actual.int("a b"), 1)
    }

    func testKeySpecialChars() {
        let actual = try! Toml(contentsOfFile: "Tests/TomlTests/key-special-chars.toml")
        XCTAssertEqual(actual.int("~!@$^&*()_+-`1234567890[]|/?><.,;:'"), 1)
    }

    func testLongFloat() {
        let actual = try! Toml(contentsOfFile: "Tests/TomlTests/long-float.toml")
        XCTAssertEqual(actual.double("longpi"), 3.141592653589793)
        XCTAssertEqual(actual.double("neglongpi"), -3.141592653589793)
    }

    func testLongInteger() {
        let actual = try! Toml(contentsOfFile: "Tests/TomlTests/long-integer.toml")
        XCTAssertEqual(actual.int("answer"), 9223372036854775807)
        XCTAssertEqual(actual.int("neganswer"), -9223372036854775808)
    }

    func testMultilineString() {
        let actual = try! Toml(contentsOfFile: "Tests/TomlTests/multiline-string.toml")
        XCTAssertEqual(actual.string("multiline_empty_one"), "")
        XCTAssertEqual(actual.string("multiline_empty_two"), "")
        XCTAssertEqual(actual.string("multiline_empty_three"), "")
        XCTAssertEqual(actual.string("multiline_empty_four"), "")
        let expected = "The quick brown fox jumps over the lazy dog."
        XCTAssertEqual(actual.string("equivalent_one"), expected)
        XCTAssertEqual(actual.string("equivalent_two"), expected)
        XCTAssertEqual(actual.string("equivalent_three"), expected)
    }

    func testRawMultilineString() {
        let actual = try! Toml(contentsOfFile: "Tests/TomlTests/raw-multiline-string.toml")
        XCTAssertEqual(actual.string("oneline"), "This string has a ' quote character.")
        XCTAssertEqual(actual.string("firstnl"), "This string has a ' quote character.")
        XCTAssertEqual(actual.string("multiline"), "This string\nhas ' a quote character\nand more than\none newline\nin it.")
    }

    func testRawString() {
        let actual = try! Toml(contentsOfFile: "Tests/TomlTests/raw-string.toml")
        XCTAssertEqual(actual.string("backspace"), "This string has a \\b backspace character.")
        XCTAssertEqual(actual.string("tab"), "This string has a \\t tab character.")
        XCTAssertEqual(actual.string("newline"), "This string has a \\n new line character.")
        XCTAssertEqual(actual.string("formfeed"), "This string has a \\f form feed character.")
        XCTAssertEqual(actual.string("carriage"), "This string has a \\r carriage return character.")
        XCTAssertEqual(actual.string("slash"), "This string has a \\/ slash character.")
        XCTAssertEqual(actual.string("backslash"), "This string has a \\\\ backslash character.")
    }

    func testStringEmpty() {
        let actual = try! Toml(contentsOfFile: "Tests/TomlTests/string-empty.toml")
        XCTAssertEqual(actual.string("answer"), "")
    }

    func testStringEscapes() {
        let actual = try! Toml(contentsOfFile: "Tests/TomlTests/string-escapes.toml")
        XCTAssertEqual(actual.string("backspace"), "This string has a \u{0008} backspace character.")
        XCTAssertEqual(actual.string("tab"), "This string has a \t tab character.")
        XCTAssertEqual(actual.string("newline"), "This string has a \n new line character.")
        XCTAssertEqual(actual.string("formfeed"), "This string has a \u{000C} form feed character.")
        XCTAssertEqual(actual.string("carriage"), "This string has a \r carriage return character.")
        XCTAssertEqual(actual.string("quote"), "This string has a \" quote character.")
        XCTAssertEqual(actual.string("backslash"), "This string has a \\ backslash character.")
        XCTAssertEqual(actual.string("notunicode1"), "This string does not have a unicode \\u escape.")
        XCTAssertEqual(actual.string("notunicode2"), "This string does not have a unicode \u{005C}u escape.")
        XCTAssertEqual(actual.string("notunicode3"), "This string does not have a unicode \\u0075 escape.")
        XCTAssertEqual(actual.string("notunicode4"), "This string does not have a unicode \\\u{0075} escape.")
    }

    func testStringSimple() {
        let actual = try! Toml(contentsOfFile: "Tests/TomlTests/string-simple.toml")
        XCTAssertEqual(actual.string("answer"), "You are not drinking enough whisky.")
    }

    func testStringWithPound() {
        let actual = try! Toml(contentsOfFile: "Tests/TomlTests/string-with-pound.toml")
        XCTAssertEqual(actual.string("pound"), "We see no # comments here.")
        XCTAssertEqual(actual.string("poundcomment"), "But there are # some comments here.")
    }

    func testTableArrayImplicit() {
        let actual = try! Toml(contentsOfFile: "Tests/TomlTests/table-array-implicit.toml")
        let array: [Toml] = actual.array("albums", "songs")!
        XCTAssertEqual(array[0].string("name"), "Glory Days")
    }

    func testTableArrayMany() {
        let actual = try! Toml(contentsOfFile: "Tests/TomlTests/table-array-many.toml")
        let array: [Toml] = actual.array("people")!
        XCTAssertEqual(array.count, 3)
        XCTAssertEqual(array[0].string("first_name"), "Bruce")
        XCTAssertEqual(array[0].string("last_name"), "Springsteen")

        XCTAssertEqual(array[1].string("first_name"), "Eric")
        XCTAssertEqual(array[1].string("last_name"), "Clapton")

        XCTAssertEqual(array[2].string("first_name"), "Bob")
        XCTAssertEqual(array[2].string("last_name"), "Seger")
    }

    func testTableArrayNest() {
        let actual = try! Toml(contentsOfFile: "Tests/TomlTests/table-array-nest.toml")
        XCTAssertEqual(actual.keyNames.count, 1)
        let array: [Toml] = actual.array("albums")!
        XCTAssertEqual(array.count, 2)

        // First one
        let first = array[0]
        XCTAssertEqual(first.string("name"), "Born to Run")
        let first_songs: [Toml] = first.array("songs")!
        XCTAssertEqual(first_songs.count, 2)
        XCTAssertEqual(first_songs[0].string("name"), "Jungleland")
        XCTAssertEqual(first_songs[1].string("name"), "Meeting Across the River")

        // Second one
        let second = array[1]
        XCTAssertEqual(second.string("name"), "Born in the USA")
        let second_songs: [Toml] = second.array("songs")!
        XCTAssertEqual(second_songs.count, 2)
        XCTAssertEqual(second_songs[0].string("name"), "Glory Days")
        XCTAssertEqual(second_songs[1].string("name"), "Dancing in the Dark")
    }

    func testTableArrayOne() {
        let actual = try! Toml(contentsOfFile: "Tests/TomlTests/table-array-one.toml")
        XCTAssertEqual(actual.keyNames.count, 1)
        let array: [Toml] = actual.array("people")!
        XCTAssertEqual(array[0].string("first_name"), "Bruce")
        XCTAssertEqual(array[0].string("last_name"), "Springsteen")
    }

    func testTableEmpty() {
        let _ = try! Toml(contentsOfFile: "Tests/TomlTests/table-empty.toml")
    }

    func testTableSubEmpty() {
        let _ = try! Toml(contentsOfFile: "Tests/TomlTests/table-sub-empty.toml")
    }

    func testTableWhitespace() {
        let _ = try! Toml(contentsOfFile: "Tests/TomlTests/table-whitespace.toml")
    }

    func testTableWithPound() {
        let actual = try! Toml(contentsOfFile: "Tests/TomlTests/table-with-pound.toml")
        XCTAssertEqual(actual.int("key#group", "answer"), 42)
    }

    func testUnicodeEscape() {
        let actual = try! Toml(contentsOfFile: "Tests/TomlTests/unicode-escape.toml")
        XCTAssertEqual(actual.string("answer4"), "\u{03B4}")
        XCTAssertEqual(actual.string("answer8"), "\u{000003B4}")
    }

    func testUnicodeLiteral() {
        let actual = try! Toml(contentsOfFile: "Tests/TomlTests/unicode-literal.toml")
        XCTAssertEqual(actual.string("answer"), "\u{03B4}")
    }

    // MARK: invalid tests

    func testParseErrorExample1() {
        XCTAssertThrowsError(try Toml(contentsOfFile: "Tests/TomlTests/hard_example-error1.toml"))
    }

    func testParseErrorExample2() {
        XCTAssertThrowsError(try Toml(contentsOfFile: "Tests/TomlTests/hard_example-error2.toml"))
    }

    func testParseErrorExample3() {
        XCTAssertThrowsError(try Toml(contentsOfFile: "Tests/TomlTests/hard_example-error3.toml"))
    }

    func testParseErrorExample4() {
        XCTAssertThrowsError(try Toml(contentsOfFile: "Tests/TomlTests/hard_example-error4.toml"))
    }

    func testInvalidArrayMixedTypesArraysAndInts() {
        XCTAssertThrowsError(try Toml(contentsOfFile: "Tests/TomlTests/array-mixed-types-arrays-and-ints.toml"))
    }

    func testInvalidArrayMixedTypesIntsAndFloats() {
        XCTAssertThrowsError(try Toml(contentsOfFile: "Tests/TomlTests/array-mixed-types-ints-and-floats.toml"))
    }

    func testInvalidArrayMixedTypesStringsAndInts() {
        XCTAssertThrowsError(try Toml(contentsOfFile: "Tests/TomlTests/array-mixed-types-strings-and-ints.toml"))
    }

    func testInvalidDatetimeMalformedNoLeads() {
        XCTAssertThrowsError(try Toml(contentsOfFile: "Tests/TomlTests/datetime-malformed-no-leads.toml"))
    }

    func testInvalidDatetimeMalformedNoSecs() {
        XCTAssertThrowsError(try Toml(contentsOfFile: "Tests/TomlTests/datetime-malformed-no-secs.toml"))
    }

    func testInvalidDatetimeMalformedNoT() {
        XCTAssertThrowsError(try Toml(contentsOfFile: "Tests/TomlTests/datetime-malformed-no-t.toml"))
    }

    func testInvalidDatetimeMalformedWithMilli() {
        XCTAssertThrowsError(try Toml(contentsOfFile: "Tests/TomlTests/datetime-malformed-with-milli.toml"))
    }

    func testInvalidDuplicateKeyTable() {
        XCTAssertThrowsError(try Toml(contentsOfFile: "Tests/TomlTests/duplicate-key-table.toml"))
    }

    func testInvalidDuplicateKeys() {
        XCTAssertThrowsError(try Toml(contentsOfFile: "Tests/TomlTests/duplicate-keys.toml"))
    }

    func testInvalidDuplicateTables() {
        XCTAssertThrowsError(try Toml(contentsOfFile: "Tests/TomlTests/duplicate-tables.toml"))
    }

    func testInvalidEmptyImplicitTable() {
        XCTAssertThrowsError(try Toml(contentsOfFile: "Tests/TomlTests/empty-implicit-table.toml"))
    }

    func testInvalidEmptyTable() {
        XCTAssertThrowsError(try Toml(contentsOfFile: "Tests/TomlTests/empty-table.toml"))
    }

    func testInvalidFloatNoLeadingZero() {
        XCTAssertThrowsError(try Toml(contentsOfFile: "Tests/TomlTests/float-no-leading-zero.toml"))
    }

    func testInvalidFloatNoTrailingDigits() {
        XCTAssertThrowsError(try Toml(contentsOfFile: "Tests/TomlTests/float-no-trailing-digits.toml"))
    }

    func testInvalidKeyEmpty() {
        XCTAssertThrowsError(try Toml(contentsOfFile: "Tests/TomlTests/key-empty.toml"))
    }

    func testInvalidKeyHash() {
        XCTAssertThrowsError(try Toml(contentsOfFile: "Tests/TomlTests/key-hash.toml"))
    }

    func testInvalidKeyNewline() {
        XCTAssertThrowsError(try Toml(contentsOfFile: "Tests/TomlTests/key-newline.toml"))
    }

    func testInvalidKeyOpenBracket() {
        XCTAssertThrowsError(try Toml(contentsOfFile: "Tests/TomlTests/key-open-bracket.toml"))
    }

    func testInvalidKeySingleOpenBracket() {
        XCTAssertThrowsError(try Toml(contentsOfFile: "Tests/TomlTests/key-single-open-bracket.toml"))
    }

    func testInvalidKeySpace() {
        XCTAssertThrowsError(try Toml(contentsOfFile: "Tests/TomlTests/key-space-error.toml"))
    }

    func testInvalidKeyStartBracket() {
        XCTAssertThrowsError(try Toml(contentsOfFile: "Tests/TomlTests/key-start-bracket.toml"))
    }

    func testInvalidKeyTwoEquals() {
        XCTAssertThrowsError(try Toml(contentsOfFile: "Tests/TomlTests/key-two-equals.toml"))
    }

    func testInvalidStringBadByteEscape() {
        XCTAssertThrowsError(try Toml(contentsOfFile: "Tests/TomlTests/string-bad-byte-escape.toml"))
    }

    func testInvalidStringBadEscape() {
        XCTAssertThrowsError(try Toml(contentsOfFile: "Tests/TomlTests/string-bad-escape.toml"))
    }

    func testInvalidStringByteEscapes() {
        XCTAssertThrowsError(try Toml(contentsOfFile: "Tests/TomlTests/string-byte-escapes.toml"))
    }

    func testInvalidStringNoClose() {
        XCTAssertThrowsError(try Toml(contentsOfFile: "Tests/TomlTests/string-no-close.toml"))
    }

    func testInvalidTableArrayMalformedBracket() {
        XCTAssertThrowsError(try Toml(contentsOfFile: "Tests/TomlTests/table-array-malformed-bracket.toml"))
    }

    func testInvalidTableArrayMalformedEmpty() {
        XCTAssertThrowsError(try Toml(contentsOfFile: "Tests/TomlTests/table-array-malformed-empty.toml"))
    }

    func testInvalidTableEmpty() {
        XCTAssertThrowsError(try Toml(contentsOfFile: "Tests/TomlTests/table-empty-invalid.toml"))
    }

    func testInvalidTableNestedBracketsClose() {
        XCTAssertThrowsError(try Toml(contentsOfFile: "Tests/TomlTests/table-nested-brackets-close.toml"))
    }

    func testInvalidTableNestedBracketsOpen() {
        XCTAssertThrowsError(try Toml(contentsOfFile: "Tests/TomlTests/table-nested-brackets-open.toml"))
    }

    func testInvalidTableWhitespace() {
        XCTAssertThrowsError(try Toml(contentsOfFile: "Tests/TomlTests/table-whitespace-invalid.toml"))
    }

    func testInvalidTableWithPound() {
        XCTAssertThrowsError(try Toml(contentsOfFile: "Tests/TomlTests/table-with-pound-invalid.toml"))
    }

    func testInvalidTextAfterArrayEntries() {
        XCTAssertThrowsError(try Toml(contentsOfFile: "Tests/TomlTests/text-after-array-entries.toml"))
    }

    func testInvalidTextAfterInteger() {
        XCTAssertThrowsError(try Toml(contentsOfFile: "Tests/TomlTests/text-after-integer.toml"))
    }

    func testInvalidTextAfterString() {
        XCTAssertThrowsError(try Toml(contentsOfFile: "Tests/TomlTests/text-after-string.toml"))
    }

    func testInvalidTextAfterTable() {
        XCTAssertThrowsError(try Toml(contentsOfFile: "Tests/TomlTests/text-after-table.toml"))
    }

    func testInvalidTextBeforeArraySeparator() {
        XCTAssertThrowsError(try Toml(contentsOfFile: "Tests/TomlTests/text-before-array-separator.toml"))
    }

    func testInvalidTextInArray() {
        XCTAssertThrowsError(try Toml(contentsOfFile: "Tests/TomlTests/text-in-array.toml"))
    }

    // MARK: allTests

    static var allTests : [(String, (TomlTests) -> () throws -> Void)] {
        return [
            ("testSimple", testSimple),
            // ("testDateFormat", testDateFormat), // see comment on function
            ("testNestedTables", testNestedTables),
            ("testImplicitlyDefinedTable", testImplicitlyDefinedTable),
            // failed tests
            ("testParseErrorExample1", testParseErrorExample1),
            ("testParseErrorExample2", testParseErrorExample2),
            ("testParseErrorExample3", testParseErrorExample3),
            ("testParseErrorExample4", testParseErrorExample4),
            // tests from the main toml repository @ https://github.com/toml-lang/toml
            ("testTomlExample", testTomlExample),
            ("testHardExample", testHardExample),
            ("testHardExampleUnicode", testHardExampleUnicode),
            ("testInvalidArrayMixedTypesArraysAndInts", testInvalidArrayMixedTypesArraysAndInts),
            ("testInvalidArrayMixedTypesIntsAndFloats", testInvalidArrayMixedTypesIntsAndFloats),
            ("testInvalidArrayMixedTypesStringsAndInts", testInvalidArrayMixedTypesStringsAndInts),
            ("testInvalidDatetimeMalformedNoLeads", testInvalidDatetimeMalformedNoLeads),
            ("testInvalidDatetimeMalformedNoSecs", testInvalidDatetimeMalformedNoSecs),
            ("testInvalidDatetimeMalformedNoT", testInvalidDatetimeMalformedNoT),
            ("testInvalidDatetimeMalformedWithMilli", testInvalidDatetimeMalformedWithMilli),
            ("testInvalidDuplicateKeyTable", testInvalidDuplicateKeyTable),
            ("testInvalidDuplicateKeys", testInvalidDuplicateKeys),
            ("testInvalidDuplicateTables", testInvalidDuplicateTables),
            ("testInvalidEmptyImplicitTable", testInvalidEmptyImplicitTable),
            ("testInvalidEmptyTable", testInvalidEmptyTable),
            ("testInvalidFloatNoLeadingZero", testInvalidFloatNoLeadingZero),
            ("testInvalidFloatNoTrailingDigits", testInvalidFloatNoTrailingDigits),
            ("testInvalidKeyEmpty", testInvalidKeyEmpty),
            ("testInvalidKeyHash", testInvalidKeyHash),
            ("testInvalidKeyNewline", testInvalidKeyNewline),
            ("testInvalidKeyOpenBracket", testInvalidKeyOpenBracket),
            ("testInvalidKeySingleOpenBracket", testInvalidKeySingleOpenBracket),
            ("testInvalidKeySpace", testInvalidKeySpace),
            ("testInvalidKeyStartBracket", testInvalidKeyStartBracket),
            ("testInvalidKeyTwoEquals", testInvalidKeyTwoEquals),
            ("testInvalidStringBadByteEscape", testInvalidStringBadByteEscape),
            ("testInvalidStringBadEscape", testInvalidStringBadEscape),
            ("testInvalidStringByteEscapes", testInvalidStringByteEscapes),
            ("testInvalidStringNoClose", testInvalidStringNoClose),
            ("testInvalidTableArrayMalformedBracket", testInvalidTableArrayMalformedBracket),
            ("testInvalidTableArrayMalformedEmpty", testInvalidTableArrayMalformedEmpty),
            ("testInvalidTableEmpty", testInvalidTableEmpty),
            ("testInvalidTableNestedBracketsClose", testInvalidTableNestedBracketsClose),
            ("testInvalidTableNestedBracketsOpen", testInvalidTableNestedBracketsOpen),
            ("testInvalidTableWhitespace", testInvalidTableWhitespace),
            ("testInvalidTableWithPound", testInvalidTableWithPound),
            ("testInvalidTextAfterArrayEntries", testInvalidTextAfterArrayEntries),
            ("testInvalidTextAfterInteger", testInvalidTextAfterInteger),
            ("testInvalidTextAfterString", testInvalidTextAfterString),
            ("testInvalidTextAfterTable", testInvalidTextAfterTable),
            ("testInvalidTextBeforeArraySeparator", testInvalidTextBeforeArraySeparator),
            ("testInvalidTextInArray", testInvalidTextInArray),
            // tests from https://github.com/BurntSushi/toml-test
            ("testArrayEmpty", testArrayEmpty),
            ("testArrayNospaces", testArrayNospaces),
            ("testArraysHetergeneous", testArraysHetergeneous),
            ("testArraysNested", testArraysNested),
            ("testArrays", testArrays),
            ("testBool", testBool),
            ("testCommentsEverywhere", testCommentsEverywhere),
            ("testDatetime", testDatetime),
            ("testEmpty", testEmpty),
            ("testExample", testExample),
            ("testFloat", testFloat),
            ("testImplicitAndExplicitAfter", testImplicitAndExplicitAfter),
            ("testImplicitAndExplicitBefore", testImplicitAndExplicitBefore),
            ("testImplicitGroups", testImplicitGroups),
            ("testInteger", testInteger),
            ("testKeyEqualsNospace", testKeyEqualsNospace),
            ("testKeySpace", testKeySpace),
            ("testKeySpecialChars", testKeySpecialChars),
            ("testLongFloat", testLongFloat),
            ("testLongInteger", testLongInteger),
            ("testMultilineString", testMultilineString),
            ("testRawMultilineString", testRawMultilineString),
            ("testRawString", testRawString),
            ("testStringEmpty", testStringEmpty),
            ("testStringEscapes", testStringEscapes),
            ("testStringSimple", testStringSimple),
            ("testStringWithPound", testStringWithPound),
            ("testTableArrayImplicit", testTableArrayImplicit),
            ("testTableArrayMany", testTableArrayMany),
            ("testTableArrayNest", testTableArrayNest),
            ("testTableArrayOne", testTableArrayOne),
            ("testTableEmpty", testTableEmpty),
            ("testTableSubEmpty", testTableSubEmpty),
            ("testTableWhitespace", testTableWhitespace),
            ("testTableWithPound", testTableWithPound),
            ("testUnicodeEscape", testUnicodeEscape),
            ("testUnicodeLiteral", testUnicodeLiteral),
        ]
    }
}
