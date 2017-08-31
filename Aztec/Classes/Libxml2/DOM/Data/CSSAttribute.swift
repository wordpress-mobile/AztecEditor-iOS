import Foundation


// MARK: - CSSAttribute
//
class CSSAttribute: Hashable {
    
    let name: String
    let value: String?

    // MARK: - Initializers

    init(name: String, value: String? = nil) {
        self.name = name
        self.value = value
    }

    convenience init?(for string: String) {
        let components = string.components(separatedBy: CSSParser.keyValueSeparator)
        guard let name = components.first, let value = components.last, components.count == 2 else {
            return nil
        }

        self.init(name: name, value: value)
    }

    // MARK: - Hashable

    var hashValue: Int {

        guard let value = value else {
            return name.hashValue
        }

        return name.hashValue ^ value.hashValue
    }

    // MARK: - String Representation

    func toString() -> String {

        guard let value = value else {
            return name
        }

        return name + CSSParser.keyValueSeparator + value
    }

    // MARK: - Equatable

    static func ==(leftValue: CSSAttribute, rightValue: CSSAttribute) -> Bool {
        return leftValue.name == rightValue.name && leftValue.value == rightValue.value
    }
}

