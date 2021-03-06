import CodableKit
import Foundation


/// A Fluent compatible identifier.
public protocol ID: Codable, Equatable, KeyStringDecodable { }

extension Int: ID { }
extension String: ID { }
extension UUID: ID { }


/// MARK: String

extension Int: StringDecodable {
    /// See StringDecodable.decode
    public static func decode(from string: String) -> Int? {
        return Int(string)
    }
}

extension UUID: StringDecodable {
    /// See StringDecodable.decode
    public static func decode(from string: String) -> UUID? {
        return UUID(uuidString: string)
    }
}

extension String: StringDecodable {
    /// See StringDecodable.decode
    public static func decode(from string: String) -> String? {
        return string
    }
}

