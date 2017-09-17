import Foundation


// MARK: - CSSAttribute
//
class CSSAttribute: NSObject, CustomReflectable, NSCoding {

    let name: String
    let value: String?

    // MARK: - Initializers

    init(name: String, value: String? = nil) {
        self.name = name
        self.value = value
    }

    convenience init?(for string: String) {
        let components = string.components(separatedBy: CSSParser.keyValueSeparator)

        guard let name = components.first?.trimmingCharacters(in: .whitespacesAndNewlines),
            let value = components.last?.trimmingCharacters(in: .whitespacesAndNewlines),
            components.count == 2 else {
                return nil
        }

        self.init(name: name, value: value)
    }

    // MARK: - NSCoding

    required init?(coder aDecoder: NSCoder) {
        guard let name = aDecoder.decodeObject(forKey: #keyPath(name)) as? String,
            let value = aDecoder.decodeObject(forKey: #keyPath(value)) as? String? else {
                return nil
        }

        self.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        self.value = value?.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func encode(with aCoder: NSCoder) {
        aCoder.encode(name, forKey: #keyPath(name))
        aCoder.encode(value, forKey: #keyPath(value))
    }

    // MARK: - CustomReflectable

    public var customMirror: Mirror {
        get {
            return Mirror(self, children: ["name": name, "value": value ?? ""])
        }
    }

    // MARK: - Hashable

    override var hashValue: Int {

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

        return name + CSSParser.keyValueSeparator + " " + value.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: - Equatable

    override func isEqual(_ object: Any?) -> Bool {

        guard let rightValue = object as? CSSAttribute else {
            return false
        }

        return self == rightValue
    }

    static func ==(leftValue: CSSAttribute, rightValue: CSSAttribute) -> Bool {
        return leftValue.name == rightValue.name && leftValue.value == rightValue.value
    }
}

