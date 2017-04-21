import Foundation

extension Character {
    
    enum Name: Character {
        case lineSeparator = "\u{2028}"
        case newline = "\n"
        case paragraphSeparator = "\u{2029}"
        case space = " "
        case zeroWidthSpace = "\u{200B}"
    }
    
    init(_ characterName: Name) {
        self.init(unicodeScalarLiteral: characterName.rawValue)
    }
}
