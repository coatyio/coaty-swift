//  Copyright (c) 2019 Siemens AG. Licensed under the MIT License.

import Foundation

#if swift(>=4.2)
@usableFromInline
protocol _AnyDecodable {
    var value: Any { get }
    init<T>(_ value: T?)
}
#else
protocol _AnyDecodable {
    var value: Any { get }
    init<T>(_ value: T?)
}
#endif

extension _AnyDecodable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if container.decodeNil() {
            self.init(())
        } else if let bool = try? container.decode(Bool.self) {
            self.init(bool)
        } else if let int = try? container.decode(Int.self) {
            self.init(int)
        } else if let uint = try? container.decode(UInt.self) {
            self.init(uint)
        } else if let double = try? container.decode(Double.self) {
            self.init(double)
        } else if let string = try? container.decode(String.self) {
            self.init(string)
        } else if let coatyUUID = try? container.decode(CoatyUUID.self) {
            self.init(coatyUUID)
        } else if let array = try? container.decode([AnyCodable].self) {
            self.init(array.map { $0.value })
        } else if let dictionary = try? container.decode([String: AnyCodable].self) {
            self.init(dictionary.mapValues { $0.value })
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "AnyCodable value cannot be decoded")
        }
    }
}
