import Foundation


// MARK: - CSSAttribute
//
class CSSAttribute: Hashable {
    
    let name: String
    let value: String

    // MARK: - Separators

    static let attributeSeparator = ";"
    static let keyValueSeparator = ":"

    // MARK: - Initializers

    init(name: String, value: String) {
        self.name = name
        self.value = value
    }

    convenience init?(for string: String) {
        let components = string.components(separatedBy: CSSAttribute.keyValueSeparator)
        guard let name = components.first, let value = components.last, components.count == 2 else {
            return nil
        }

        self.init(name: name, value: value)
    }

    // MARK: - Hashable

    var hashValue: Int {
        return name.hashValue ^ value.hashValue
    }

    // MARK: - String Representation

    func toString() -> String {
        return name + CSSAttribute.keyValueSeparator + value
    }

    // MARK: - Equatable

    static func ==(leftValue: CSSAttribute, rightValue: CSSAttribute) -> Bool {
        return leftValue.name == rightValue.name && leftValue.value == rightValue.value
    }
}

