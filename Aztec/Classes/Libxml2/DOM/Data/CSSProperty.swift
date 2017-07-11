import Foundation

class CSSProperty: Hashable {
    
    let name: String
    let value: String

    init(name: String, value: String) {
        self.name = name
        self.value = value
    }

    // MARK: - Hashable

    var hashValue: Int {
        return name.hashValue ^ value.hashValue
    }

    // MARK: - Equatable

    static func ==(leftValue: CSSProperty, rightValue: CSSProperty) -> Bool {
        return leftValue.name == rightValue.name && leftValue.value == rightValue.value
    }

    // MARK: - String Representation

    func toString() -> String {
        return name + ": " + value
    }
}
