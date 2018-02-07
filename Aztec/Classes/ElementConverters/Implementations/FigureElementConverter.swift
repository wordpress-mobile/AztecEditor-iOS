import UIKit


/// Returns a specialised representation for a `<figure>` element.
///
class FigureElementConverter: AttachmentElementConverter {

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
    
    // MARK: - AttachmentElementConverter
    
    typealias AttachmentType = ImageAttachment
    
    func convert(_ element: ElementNode, inheriting attributes: [NSAttributedStringKey: Any]) -> (attachment: ImageAttachment, string: NSAttributedString) {
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
        let (imageAttachment, output) = ImageElementConverter().convert(imgElement, inheriting: attributes)
        
        // Serialize the Figcaption:
        // We're wrapping the Figcaption's children within a figcaption, so that the `<figcaption>` element itself doesn't get mapped
        // as UnknownHTML
        //
        let serializer = AttributedStringSerializer()
        let wrappedCaptionChildren = RootNode(children: captionElement.children)
        imageAttachment.caption = serializer.serialize(wrappedCaptionChildren, inheriting: attributes)
        
        return (imageAttachment, output)
    }    
}
