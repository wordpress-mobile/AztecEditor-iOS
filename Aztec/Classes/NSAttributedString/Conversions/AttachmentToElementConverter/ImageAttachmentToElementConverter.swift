import Foundation
import UIKit

class ImageAttachmentToElementConverter: AttachmentToElementConverter {
    func convert(_ attachment: ImageAttachment, attributes: [NSAttributedStringKey : Any]) -> [Node] {
        let imageElement: ElementNode
        
        if let representation = attributes[.imageHtmlRepresentation] as? HTMLRepresentation,
            case let .element(representationElement) = representation.kind {
            
            imageElement = representationElement.toElementNode()
        } else {
            imageElement = ElementNode(type: .img)
        }
        
        if let attribute = imageSourceAttribute(from: attachment) {
            imageElement.updateAttribute(named: attribute.name, value: attribute.value)
        }
        
        if let attribute = imageClassAttribute(from: attachment) {
            imageElement.updateAttribute(named: attribute.name, value: attribute.value)
        }
        
        for attribute in imageSizeAttributes(from: attachment) {
            imageElement.updateAttribute(named: attribute.name, value: attribute.value)
        }
        
        for (key,value) in attachment.extraAttributes {
            var finalValue = value
            if key == "class", let baseValue = imageElement.stringValueForAttribute(named: "class"){
                let baseComponents = Set(baseValue.components(separatedBy: " "))
                let extraComponents = Set(value.components(separatedBy: " "))
                finalValue = baseComponents.union(extraComponents).joined(separator: " ")
            }
            imageElement.updateAttribute(named: key, value: .string(finalValue))
        }
        
        return [imageElement]
    }
    
    /// Extracts the class attribute from an ImageAttachment Instance.
    ///
    private func imageClassAttribute(from attachment: ImageAttachment) -> Attribute? {
        var style = String()
        style += attachment.alignment.htmlString()
        
        if attachment.size != .none {
            style += style.isEmpty ? String() : String(.space)
            style += attachment.size.htmlString()
        }
        
        guard !style.isEmpty else {
            return nil
        }
        
        return Attribute(name: "class", value: .string(style))
    }
    
    /// Extracts the Image's Width and Height attributes, whenever the Attachment's Size is set to (anything) but .none.
    ///
    private func imageSizeAttributes(from attachment: ImageAttachment) -> [Attribute] {
        guard let imageSize = attachment.image?.size, attachment.size.shouldResizeAsset else {
            return []
        }
        
        let calculatedHeight = floor(attachment.size.width * imageSize.height / imageSize.width)
        let heightValue = String(describing: Int(calculatedHeight))
        let widthValue = String(describing: Int(attachment.size.width))
        
        return [
            Attribute(name: "width", value: .string(widthValue)),
            Attribute(name: "height", value: .string(heightValue))
        ]
    }
    
    /// Extracts the src attribute from an ImageAttachment Instance.
    ///
    private func imageSourceAttribute(from attachment: ImageAttachment) -> Attribute? {
        guard let source = attachment.url?.absoluteString else {
            return nil
        }
        
        return Attribute(name: "src", value: .string(source))
    }
}
