import Foundation

/// This class has the sole purpose of creating control characters when requested.
/// Control characters are characters that only exist in visual mode.  They exist to trigger custom
/// actions when they're deleted (such as unifying two blockquotes).
///
class ControlCharacterFactory {

    typealias ElementNode = Libxml2.ElementNode

    // MARK: - Control Characters

    /// Returns a closing character for the specified node, if any is necessary.
    ///
    /// - Parameters:
    ///     - node: the node the closing character is requested for.
    ///     - inheritedAttributes: the string attributes inherited by the closing character.
    ///
    /// - Returns: the requested closing character, or `nil` if none is needed.
    ///
    func closer(
        forElement element: ControlElement,
        inheritingAttributes inheritedAttributes: [String:Any]) -> NSAttributedString? {

        guard let type = ControlCharacterType.closer(forElement: element) else {
            return nil
        }

        return controlCharacter(
            ofType: type,
            usingCharacterNamed: .newline,
            inheritingAttributes: inheritedAttributes)
    }

    /// Returns an opening character for the specified node, if any is necessary.
    ///
    /// - Parameters:
    ///     - element: the element to control.
    ///     - inheritedAttributes: the string attributes inherited by the opening character.
    ///
    /// - Returns: the requested opening character, or `nil` if none is needed.
    ///
    func opener(
        forElement element: ControlElement,
        inheritingAttributes inheritedAttributes: [String:Any]) -> NSAttributedString? {

        guard let type = ControlCharacterType.opener(forElement: element) else {
            return nil
        }

        return controlCharacter(
            ofType: type,
            usingCharacterNamed: .zeroWidthSpace,
            inheritingAttributes: inheritedAttributes)
    }

    // MARK: - Control Characters: Construction

    /// Returns a block element control character.  Can be either a block-opener, or a closer.
    ///
    /// - Important: you should call `blockElementCloseCharacter(ofType:forNode:inheritingAttributes)`
    ///     or `blockElementOpenCharacter(ofType:forNode:inheritingAttributes)` instead of calling
    ///     this method directly.
    ///
    /// - Parameters:
    ///     - type: the type of control character.
    ///     - characterName: the name of the character to use to represent the control character.
    ///     - inheritedAttributes: the attributes the control character will inherit.
    ///
    /// - Returns: the requested control character.
    ///
    private func controlCharacter(
        ofType type: ControlCharacterType,
        usingCharacterNamed characterName: Character.Name,
        inheritingAttributes inheritedAttributes: [String:Any]) -> NSAttributedString {

        return controlCharacter(ofType: type, usingCharacter: Character(characterName), inheritingAttributes: inheritedAttributes)
    }

    /// Returns a block element control character.  Can be either a block-opener, or a closer.
    ///
    /// - Important: you should call `blockElementCloseCharacter(ofType:forNode:inheritingAttributes)`
    ///     or `blockElementOpenCharacter(ofType:forNode:inheritingAttributes)` instead of calling
    ///     this method directly.
    ///
    /// - Parameters:
    ///     - type: the type of control character.
    ///     - character: the character to use to represent the control character.
    ///     - inheritedAttributes: the attributes the control character will inherit.
    ///
    /// - Returns: the requested control character.
    ///
    private func controlCharacter(
        ofType type: ControlCharacterType,
        usingCharacter character: Character,
        inheritingAttributes inheritedAttributes: [String:Any]) -> NSAttributedString {

        var attributes = inheritedAttributes

        attributes[ControlCharacterAttributeName] = type

        return NSAttributedString(string: String(character), attributes: attributes)
    }
}
