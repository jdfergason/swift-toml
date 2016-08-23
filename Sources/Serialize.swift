import Foundation

/**
    Serialize a toml object to a string

    - Parameter toml: Toml object to serialize
    - Parameter indent: Number of levels to indent this table
    - Parameter level: Current level to indent

    - Returns: The Toml object serialized to Toml
*/
func serialize(toml: Toml, indent: Int = 2, level: Int = 0) -> String {
    var result = ""

    // serialize all key/value pairs at the base level
    for key in toml.keys {
        if let keyName = key.last {
            result += "\(quoted(keyName)) = \(toml.valueDescription(key)!)\n"
        }
    }

    // serialize each table
    for (tableName, table) in toml.tables() {
        result += "[\(tableName)]\n"
        result += serialize(toml: table, indent: indent, level: level)
    }

    return result
}
