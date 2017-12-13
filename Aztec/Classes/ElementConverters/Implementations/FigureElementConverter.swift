import UIKit


/// Returns a specialised representation for a `<figure>` element.
///
class FigureElementConverter: ElementConverter {

    func convert(from element: ElementNode, inheritedAttributes: [AttributedStringKey: Any]) -> NSAttributedString {
        assert(canConvert(element: element))

        // Extract the Image + Figcaption Elements
        //
        guard let imgElement = element.firstChild(ofType: .img),
            let captionElement = element.firstChild(ofType: .figcaption)
        else {
            fatalError()
        }

        // Convert the Image Element
        //
        let output = ImageElementConverter().convert(from: imgElement, inheritedAttributes: inheritedAttributes)
        guard let imageAttachment = output.attribute(.attachment, at: 0, effectiveRange: nil) as? ImageAttachment else {
            fatalError()
        }

        // Serialize the Figcaption:
        // We're wrapping the Figcaption's children within a figcaption, so that the `<figcaption>` element itself doesn't get mapped
        // as UnknownHTML
        //
        let wrappedCaptionChildren = RootNode(children: captionElement.children)
        let serializer = AttributedStringSerializer(defaultAttributes: inheritedAttributes)
        imageAttachment.caption = serializer.serialize(wrappedCaptionChildren)

        return output
    }

    func specialString(for element: ElementNode) -> String {
        return .textAttachment
    }

    func extraAttributes(for representation: HTMLRepresentation) -> [AttributedStringKey: Any]? {
        return [.hrHtmlRepresentation: representation]
    }

    /// Indicates if the current ElementNode is supported, or not. For now, at least, only the following Figure is supported:
    ///
    /// `<figure><img/><figcaption></figcaption></figure>`
    ///
    func canConvert(element: ElementNode) -> Bool {
        return element.isNodeType(.figure) &&
            element.children.count == 2 &&
            element.firstChild(ofType: .img) != nil &&
            element.firstChild(ofType: .figcaption) != nil
    }
}
