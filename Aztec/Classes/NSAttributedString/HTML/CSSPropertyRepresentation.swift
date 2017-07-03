import Foundation

class CSSPropertyRepresentation {
    let name: String
    let value: String

    init(name: String, value: String) {
        self.name = name
        self.value = value
    }

    func toString() -> String {
        return name + ": " + value
    }
}
