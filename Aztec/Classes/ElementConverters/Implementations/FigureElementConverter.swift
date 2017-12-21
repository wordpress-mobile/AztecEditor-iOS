import UIKit


/// Returns a specialised representation for a `<figure>` element.
///
class FigureElementConverter: AttachmentElementConverter, ElementConverter {
    
    // MARK: - ElementConverter
    
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
    
    func convert(_ element: ElementNode, inheriting attributes: [AttributedStringKey: Any]) -> NSAttributedString {
        let (_, output) = convert(element, inheriting: attributes)
        
        return output
    }
    
    // MARK: - AttachmentElementConverter
    
    typealias AttachmentType = ImageAttachment
    
    func convert(_ element: ElementNode, inheriting attributes: [AttributedStringKey: Any]) -> (attachment: ImageAttachment, string: NSAttributedString) {
        assert(canConvert(element: element))
        
        let attributes = extraAttributes(for: element, inheriting: attributes)
        
        // Extract the Image + Figcaption Elements
        //
        guard let imgElement = element.firstChild(ofType: .img),
            let captionElement = element.firstChild(ofType: .figcaption)
            else {
                fatalError()
        }
        
        // Convert the Image Element
        //
        let (imageAttachment, output) = ImageElementConverter().convert(imgElement, inheriting: attributes)
        
        // Serialize the Figcaption:
        // We're wrapping the Figcaption's children within a figcaption, so that the `<figcaption>` element itself doesn't get mapped
        // as UnknownHTML
        //
        let wrappedCaptionChildren = RootNode(children: captionElement.children)
        let serializer = AttributedStringSerializer(defaultAttributes: attributes)
        imageAttachment.caption = serializer.serialize(wrappedCaptionChildren)
        
        return (imageAttachment, output)
    }
    
    // MARK: - Extra attributes

    private func extraAttributes(for element: ElementNode, inheriting attributes: [AttributedStringKey: Any]) -> [AttributedStringKey: Any] {
        let elementRepresentation = HTMLElementRepresentation(element)
        let representation = HTMLRepresentation(for: .element(elementRepresentation))
        
        return [.hrHtmlRepresentation: representation]
    }
}
