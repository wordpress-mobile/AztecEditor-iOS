import Foundation

let VisualOnlyAttributeName = "Aztec.AttributeKeys.VisualOnlyAttributeName" // Value is ControlCharacterType

/// The different visual-only element types.
///
enum VisualOnlyElement: String {
    case newline = "Aztec.ControlCharacterType.newline"
    case zeroWidthSpace = "Aztec.ControlCharacterType.zeroWidthSpace"
}
