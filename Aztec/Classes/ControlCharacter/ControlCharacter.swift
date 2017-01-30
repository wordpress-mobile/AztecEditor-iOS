import Foundation

let ControlCharacterAttributeName = "Aztec.AttributeKeys.controlCharacter" // Value is ControlCharacterType

/// NSAttributedString attributes that can be affected by interactions with control characters.
///
enum ControlElement {
    case blockquote
    case listItem
    case paragraph
}

/// Control characters are used to control the formatting of some NSAttributedString attributes.
///
enum ControlCharacterType: String {
    case blockquoteCloser = "Aztec.ControlCharacterType.blockquoteCloser"
    case blockquoteOpener = "Aztec.ControlCharacterType.blockquoteOpener"
    case listItemCloser = "Aztec.ControlCharacterType.listItemCloser"
    case listItemOpener = "Aztec.ControlCharacterType.listItemOpener"
    case paragraphCloser = "Aztec.ControlCharacterType.paragraphCloser"

    static func closer(forElement element: ControlElement) -> ControlCharacterType? {
        switch element {
        case .blockquote:
            return .blockquoteCloser
        case .listItem:
            return .listItemCloser
        case .paragraph:
            return .paragraphCloser
        }
    }

    static func opener(forElement element: ControlElement) -> ControlCharacterType? {
        switch element {
        case .blockquote:
            return .blockquoteOpener
        case .listItem:
            return .listItemOpener
        default:
            return nil
        }
    }
}
