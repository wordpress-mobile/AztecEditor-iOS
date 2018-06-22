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
        
        let attachment = HTMLAttachment()
        let decoder = GutenbergAttributeDecoder()
        if let content = decoder.decodedAttribute(named: GutenbergAttributeNames.selfCloser, from: element) {
            attachment.rawHTML = String(content[content.startIndex ..< content.index(before: content.endIndex)])
            attachment.rootTagName = String(content.trimmingCharacters(in: .whitespacesAndNewlines).prefix(while: { (char) -> Bool in
                char != " "
            }))
        } else {
            let serializer = HTMLSerializer()
            attachment.rootTagName = element.name
            attachment.rawHTML = serializer.serialize(element)
        }

            return NSAttributedString(attachment: attachment, attributes: attributes)
    }
        
}
