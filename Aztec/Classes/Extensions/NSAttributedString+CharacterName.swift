import Foundation

extension NSAttributedString {
    convenience init(_ characterName: Character.Name, withAttributes attributes: [String:Any]?) {
        self.init(string: String(characterName), attributes: attributes)
    }
}
