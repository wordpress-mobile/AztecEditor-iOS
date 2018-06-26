import Aztec
import Foundation

public extension Element {
    static let gutenpack = Element("gutenpack")
}

public class GutenpackConverter: ElementConverter {
    
    // MARK: - ElementConverter
    
    public func convert(
        _ element: ElementNode,
        inheriting attributes: [NSAttributedStringKey: Any],
        childrenSerializer serializeChildren: ChildrenSerializer) -> NSAttributedString {
        
        precondition(element.type == .gutenpack)

        let decoder = GutenbergAttributeDecoder()
        guard let content = decoder.decodedAttribute(named: GutenbergAttributeNames.selfCloser, from: element) else {
            let serializer = HTMLSerializer()
            let attachment = HTMLAttachment()
            attachment.rootTagName = element.name
            attachment.rawHTML = serializer.serialize(element)
            return NSAttributedString(attachment: attachment, attributes: attributes)
        }

        let blockContent = String(content[content.startIndex ..< content.index(before: content.endIndex)])
        let blockName = String(content.trimmingCharacters(in: .whitespacesAndNewlines).prefix(while: { (char) -> Bool in
            char != " "
        }))
        let attachment = GutenpackAttachment(name: blockName, content: blockContent)
        return NSAttributedString(attachment: attachment, attributes: attributes)
    }
        
}
