import UIKit


/// Returns a specialised representation for a `<figure>` element.
///
class FigureElementConverter: ElementConverter {

    func convert(from element: ElementNode, inheritedAttributes: [AttributedStringKey: Any]) -> NSAttributedString {
        guard element.isNodeType(.figure),
            element.children.count == 2,
            let imgElement = element.firstChild(ofType: .img),
            let captionElement = element.firstChild(ofType: .figcaption)
        else {
            fatalError()
        }

        let imageConverter = ImageElementConverter()
        let imageString = imageConverter.convert(from: imgElement, inheritedAttributes: inheritedAttributes)

        guard let attachment = imageString.attribute(.attachment, at: 0, effectiveRange: nil) as? ImageAttachment else {
            fatalError()
        }

        let wrappedCaptionChildren = RootNode(children: captionElement.children)
        let serializer = AttributedStringSerializer(defaultAttributes: inheritedAttributes)
        attachment.caption = serializer.serialize(wrappedCaptionChildren)

        return imageString
    }

    func specialString(for element: ElementNode) -> String {
        return .textAttachment
    }

    func extraAttributes(for representation: HTMLRepresentation) -> [AttributedStringKey: Any]? {
        return [.hrHtmlRepresentation: representation]
    }
}
