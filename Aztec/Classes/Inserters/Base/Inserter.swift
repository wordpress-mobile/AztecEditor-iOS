import UIKit

protocol Inserter {
    func insert(for element: ElementNode, inheritedAttributes: [AttributedStringKey: Any]) -> NSAttributedString

    /// The special string that represents the element — usually `NSAttachmentCharacter`.
    ///
    /// - Parameters:
    ///
    ///     - element: Element that should be represented by the replacement String.
    func specialString(for element: ElementNode) -> String

    /// Returns an attachment representing the HTML element.
    ///
    /// - Parameters:
    ///
    ///     - representation: HTML element to turn into an attachment.
    ///     - inheritedAttributes: Attributes inherited from the parent element — to be turned into `extraAttributes` on the `Attachment` itself.
    ///
    /// - Returns: Attachment when appropriate, `nil` when there isn't a valid transformation into an Attachment.
    func attachment(from representation: HTMLRepresentation, inheriting inheritedAttributes: [AttributedStringKey: Any]) -> NSTextAttachment?
}


extension Inserter {
    func insert(for element: ElementNode, inheritedAttributes: [AttributedStringKey: Any]) -> NSAttributedString {
        let string = specialString(for: element)

        let elementRepresentation = HTMLElementRepresentation(element)
        let representation = HTMLRepresentation(for: .element(elementRepresentation))

        guard let attachment = attachment(from: representation, inheriting: inheritedAttributes) else {
            return NSAttributedString(string: string, attributes: inheritedAttributes)
        }



        var copiedAttributes = inheritedAttributes

        copiedAttributes[.attachment] = attachment

        return NSAttributedString(string: string, attributes: copiedAttributes)
    }

    /// Default implementation, Inserters providing attachments should override this.
    func attachment(from representation: HTMLRepresentation, inheriting inheritedAttributes: [AttributedStringKey: Any]) -> NSTextAttachment? {
        return nil
    }
}
