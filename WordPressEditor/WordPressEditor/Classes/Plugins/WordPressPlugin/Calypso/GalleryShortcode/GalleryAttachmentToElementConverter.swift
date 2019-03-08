import Aztec
import Foundation

class GalleryAttachmentToElementConverter: AttachmentToElementConverter {    
    func convert(_ attachment: GalleryAttachment, attributes: [NSAttributedString.Key : Any]) -> [Node] {
        
        let attributes = getAttributes(from: attachment)
        let galleryElement = ElementNode(type: .gallery, attributes: attributes, children: [])
        
        return [galleryElement]
    }
}

// MARK: - Attribute Retrieval Logic

extension GalleryAttachmentToElementConverter {
    private func getAttributes(from attachment: GalleryAttachment) -> [Attribute] {
        return getSupportedAttributes(from: attachment) + getUnsupportedAttributes(from: attachment)
    }
    
    private func getSupportedAttributes(from attachment: GalleryAttachment) -> [Attribute] {
        var attributes = [Attribute]()
        
        if let attribute = getColumnsAttribute(from: attachment) {
            attributes.append(attribute)
        }
        
        if let attribute = getIDsAttribute(from: attachment) {
            attributes.append(attribute)
        }
        
        if let attribute = getOrderAttribute(from: attachment) {
            attributes.append(attribute)
        }
        
        if let attribute = getOrderByAttribute(from: attachment) {
            attributes.append(attribute)
        }
        
        return attributes
    }
    
    private func getUnsupportedAttributes(from attachment: GalleryAttachment) -> [Attribute] {
        return attachment.extraAttributes.compactMap { attribute -> Attribute? in
            guard !GallerySupportedAttribute.isSupported(attribute.name) else {
                return nil
            }
            
            return attribute
        }
    }
    
    private func getColumnsAttribute(from attachment: GalleryAttachment) -> Attribute? {
        guard let value = attachment.columns else {
            return nil
        }
        
        let stringValue = String(value)
        
        return Attribute(name: GallerySupportedAttribute.columns.rawValue, value: .string(stringValue))
    }
    
    private func getIDsAttribute(from attachment: GalleryAttachment) -> Attribute? {
        guard let ids = attachment.ids else {
            return nil
        }
        
        let stringIDs = ids.map { String($0) }
        let joinedIDs = stringIDs.joined(separator: ",")
        
        return Attribute(name: GallerySupportedAttribute.ids.rawValue, value: .string(joinedIDs))
    }
    
    private func getOrderAttribute(from attachment: GalleryAttachment) -> Attribute? {
        guard let order = attachment.order else {
            return nil
        }
        
        return Attribute(name: GallerySupportedAttribute.order.rawValue, value: .string(order.rawValue))
    }
    
    private func getOrderByAttribute(from attachment: GalleryAttachment) -> Attribute? {
        guard let orderBy = attachment.orderBy else {
            return nil
        }
        
        return Attribute(name: GallerySupportedAttribute.orderBy.rawValue, value: .string(orderBy.rawValue))
    }
}
