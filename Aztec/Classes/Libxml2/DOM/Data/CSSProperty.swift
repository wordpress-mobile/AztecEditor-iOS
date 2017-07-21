import Foundation


// MARK: - CSSProperty
//
class CSSProperty: Hashable {
    
    let name: String
    let value: String

    // MARK: - Initializers

    init(name: String, value: String) {
        self.name = name
        self.value = value
    }

    convenience init?(string: String) {
        let components = string.components(separatedBy: CSSProperty.keyValueSeparator)
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
        return name + CSSProperty.keyValueSeparator + value
    }

    // MARK: - Equatable

    static func ==(leftValue: CSSProperty, rightValue: CSSProperty) -> Bool {
        return leftValue.name == rightValue.name && leftValue.value == rightValue.value
    }
}


// MARK: - Helpers
//
private extension CSSProperty {
    static let keyValueSeparator = ": "
}
