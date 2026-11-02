// repository: https://github.com/JonathanStorey/swift-permutation
// path: Collections/IdentifiedSet+Codable.swift
// dependencies: [Collections/IdentifiedSet.swift]

extension IdentifiedSet: Encodable where Element: Encodable {

    /// Encodes the elements as a plain array in order.
    public func encode(to encoder: any Encoder) throws {
        var container: any UnkeyedEncodingContainer = encoder.unkeyedContainer()
        for element in self { try container.encode(element) }
    }
}

extension IdentifiedSet: Decodable where Element: Decodable {

    /// Decodes a plain array of elements, throwing when two of them share an id.
    public init(from decoder: any Decoder) throws {
        var container: any UnkeyedDecodingContainer = try decoder.unkeyedContainer()
        self.init()
        while !container.isAtEnd {
            let element: Element = try container.decode(Element.self)
            guard append(element) else {
                throw DecodingError.dataCorruptedError(in: container, debugDescription: "Duplicate id \(element.id) in IdentifiedSet.")
            }
        }
    }
}
