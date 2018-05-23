import Foundation

extension NSAttributedString {
    convenience init(_ characterName: Character.Name, attributes: [NSAttributedStringKey: Any]?) {
        self.init(string: String(characterName), attributes: attributes)
    }
}
