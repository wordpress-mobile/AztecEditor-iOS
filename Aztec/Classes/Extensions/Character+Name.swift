import Foundation

extension Character {
    
    enum Name: Character {
        case newline = "\n"
        case space = " "
        case zeroWidthSpace = "\u{200B}"
    }
    
    init(_ characterName: Name) {
        self.init(unicodeScalarLiteral: characterName.rawValue)
    }
}
