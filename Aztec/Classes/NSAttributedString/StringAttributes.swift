import Foundation

enum StringAttributeName: String {
    case controlCharacterType = "Aztec.AttributeKeys.controlCharacterType" // Value is ControlCharacterType
}

enum ControlCharacterType: String {
    case blockCloser = "Aztec.ControlCharacterType.blockCloser"
    case blockOpener = "Aztec.ControlCharacterType.blockOpener"
}
