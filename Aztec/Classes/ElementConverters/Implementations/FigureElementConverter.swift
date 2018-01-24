import UIKit


/// Returns a specialised representation for a `<figure>` element.
///
class FigureElementConverter: AttachmentElementConverter {

    let imageElementConverter: ImageElementConverter
    let linkedImageElementConverter: LinkedImageElementConverter
    unowned let serializer: AttributedStringSerializer
    
    // MARK: - Initializers
    
    init(using serializer: AttributedStringSerializer, and imageElementConverter: ImageElementConverter, and linkedImageElementConverter: LinkedImageElementConverter) {
        self.imageElementConverter = imageElementConverter
        self.linkedImageElementConverter = linkedImageElementConverter
        self.serializer = serializer
    }
    
    // MARK: - ElementConverter
    
    /// Indicates if the current ElementNode is supported, or not. For now, at least, only the following Figure is supported:
    ///
    /// `<figure><img/><figcaption></figcaption></figure>`
    ///
    func canConvert(element: ElementNode) -> Bool {
        return element.isNodeType(.figure) &&
            element.children.count == 2 &&
            (element.firstChild(ofType: .img) != nil || element.firstChild(ofType: .a) != nil) &&
            element.firstChild(ofType: .figcaption) != nil
    }
    
    // MARK: - AttachmentElementConverter
    
    typealias AttachmentType = ImageAttachment
    
    func convert(_ element: ElementNode, inheriting attributes: [AttributedStringKey: Any]) -> (attachment: ImageAttachment, string: NSAttributedString) {
        assert(canConvert(element: element))

        // Extract the Image + Figcaption Elements
        //
        guard let imageContainerElement = element.firstChild(ofType: .img) ?? element.firstChild(ofType: .a),
            let captionElement = element.firstChild(ofType: .figcaption)
            else {
                fatalError()
        }
        
        // Serialize the Figcaption:
        // We're wrapping the Figcaption's children within a figcaption, so that the `<figcaption>` element itself doesn't get mapped
        // as UnknownHTML
        //
        let wrappedCaptionChildren = RootNode(children: captionElement.children)
        
        let (imageAttachment, output): (attachment: ImageAttachment, string: NSAttributedString) = {
            if imageContainerElement.isNodeType(.img) {
                return imageElementConverter.convert(imageContainerElement, inheriting: attributes)
            } else {
                return linkedImageElementConverter.convert(imageContainerElement, inheriting: attributes)
            }
        }()
        
        imageAttachment.caption = serializer.serialize(wrappedCaptionChildren, inheriting: attributes)
        
        return (imageAttachment, output)
    }    
}
