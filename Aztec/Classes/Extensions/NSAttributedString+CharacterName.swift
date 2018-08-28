import Foundation

extension NSAttributedString {
    convenience init(_ characterName: Character.Name, attributes: [NSAttributedString.Key: Any]?) {
        self.init(string: String(characterName), attributes: attributes)
    }
}
