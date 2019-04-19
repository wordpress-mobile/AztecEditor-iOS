import Foundation
import UIKit

public extension Character {

    enum Name: Character {
        case lineFeed = "\u{000A}"
        case carriageReturn = "\u{000D}"
        case nonBreakingSpace = "\u{00A0}"
        case lineSeparator = "\u{2028}"
        case objectReplacement = "\u{FFFC}"
        case paragraphSeparator = "\u{2029}"
        case space = " "
        case tab = "\t"
        case zeroWidthSpace = "\u{200B}"
        
        // Aliases
        static let textAttachment = objectReplacement
    }
    
    static let paragraphBreakingCharacters: [Name] = [.lineFeed, .carriageReturn, .paragraphSeparator]
    
    init(_ characterName: Name) {
        self.init(unicodeScalarLiteral: characterName.rawValue)
    }
}
