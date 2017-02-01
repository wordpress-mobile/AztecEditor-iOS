import Foundation

extension NSAttributedString {
    convenience init(_ characterName: Character.Name, attributes: [String:Any]?) {
        self.init(string: String(characterName), attributes: attributes)
    }
}
