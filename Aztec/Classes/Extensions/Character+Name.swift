import Foundation
import UIKit

extension Character {

    enum Name: Character {
        case newline = "\u{000A}" // "\n" (also called line feed)
        case carriageReturn = "\u{000D}" // "\r"
        case space = "\u{0020}"
        case nextLine = "\u{0085}"
        case zeroWidthSpace = "\u{200B}"
        case lineSeparator = "\u{2028}"
        case paragraphSeparator = "\u{2029}"
        case objectReplacement = "\u{FFFC}"
    }
    
    init(_ characterName: Name) {
        self.init(unicodeScalarLiteral: characterName.rawValue)
    }
}
