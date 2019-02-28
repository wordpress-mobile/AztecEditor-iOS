import Aztec
import Foundation

public extension Element {
    static let gallery = Element("gallery")
}

/// Provides a representation for Gallery (shortcode) elements.
///
class GalleryElementConverter: AttachmentElementConverter {
    
    // MARK: - AttachmentElementConverter
    
    typealias AttachmentType = GalleryAttachment
    
    func convert(
        _ element: ElementNode,
        inheriting attributes: [NSAttributedString.Key: Any],
        contentSerializer serialize: ContentSerializer) -> (attachment: GalleryAttachment, string: NSAttributedString) {
        
        precondition(element.type == .gallery)
        
        let attachment = self.attachment(for: element)
        
        return (attachment, NSAttributedString(attachment: attachment, attributes: attributes))
    }
    
    // MARK: - Attachment Creation
    
    private func attachment(for element: ElementNode) -> GalleryAttachment {
        
        let gallery = GalleryAttachment(identifier: UUID().uuidString)
        
        loadAttributes(element.attributes, into: gallery)
        
        return gallery
    }
}

// MARK: - Retrieveing Supported Attributes

private extension GalleryElementConverter {
    
    private func loadAttributes(_ attributes: [Attribute], into gallery: GalleryAttachment) {
        loadSupportedAttributes(attributes, into: gallery)
        gallery.extraAttributes = getUnsupportedAttributes(attributes)
    }
    
    private func loadSupportedAttributes(_ attributes: [Attribute], into gallery: GalleryAttachment) {
        gallery.columns = getColumns(from: attributes)
        gallery.ids = getIDs(from: attributes)
        gallery.order = getOrder(from: attributes)
        gallery.orderBy = getOrderBy(from: attributes)
    }
    
    private func getColumns(from attributes: [Attribute]) -> Int? {
        return valueOfAttribute(.columns, in: attributes, withType: Int.self)
    }
    
    private func getIDs(from attributes: [Attribute]) -> [Int]? {
        return valueOfAttribute(.ids, in: attributes, withType: [Int].self)
    }
    
    private func getOrder(from attributes: [Attribute]) -> GalleryAttachment.Order? {
        return attribute(.order, in: attributes, withType: GalleryAttachment.Order.self)
    }
    
    private func getOrderBy(from attributes: [Attribute]) -> GalleryAttachment.OrderBy? {
        return attribute(.orderBy, in: attributes, withType: GalleryAttachment.OrderBy.self)
    }
    
    private func getUnsupportedAttributes(_ attributes: [Attribute]) -> [Attribute] {
        
        var output = [Attribute]()
        
        for attribute in attributes {
            guard !GallerySupportedAttribute.isSupported(attribute.name) else {
                continue
            }
            
            output.append(attribute)
        }
        
        return output
    }
}

// MARK: - Attribute Retrieval Logic

private extension GalleryElementConverter {
    
    /// Returns an attribute after mapping its value into a `RawRepresentable` type that has
    /// `String` as its `RawType`.
    ///
    private func attribute<T: RawRepresentable>(_ name: GallerySupportedAttribute, in attributes: [Attribute], withType type: T.Type) -> T? where T.RawValue == String {
        guard let attributeStringValue = valueOfAttribute(name, in: attributes, withType: String.self),
            let result = T.init(rawValue: attributeStringValue) else {
                return nil
        }
        
        return result
    }
    
    /// Maps a supported attribute to `[Int]?`.
    ///
    /// - Parameters:
    ///     - name: the name of the supported attribute.
    ///     - attributes: the list of attributes where the attribute should be searched.
    ///     - type: the output type.
    ///
    /// - Returns: the mapped attribute, or `nil` if not found.
    ///
    private func valueOfAttribute(_ name: GallerySupportedAttribute, in attributes: [Attribute], withType type: [Int].Type) -> [Int]? {
        guard let attributeStringValue = valueOfAttribute(name, in: attributes, withType: String.self) else {
            return nil
        }
        
        return attributeStringValue.split(separator: ",").compactMap { substring -> Int? in
            return Int(substring.trimmingCharacters(in: .whitespaces))
        }
    }
    
    /// Returns an attribute after mapping its value into a `RawRepresentable` type that has
    /// `String` as its `RawType`.
    ///
    private func valueOfAttribute(_ name: GallerySupportedAttribute, in attributes: [Attribute], withType type: Int.Type) -> Int? {
        guard let attributeStringValue = valueOfAttribute(name, in: attributes, withType: String.self),
            let attributeIntValue = Int(attributeStringValue) else {
                return nil
        }
        
        return attributeIntValue
    }
    
    /// Returns an attribute after mapping its value into a `RawRepresentable` type that has
    /// `String` as its `RawType`.
    ///
    private func valueOfAttribute(_ name: GallerySupportedAttribute, in attributes: [Attribute], withType type: String.Type) -> String? {
        guard let attribute = attributes.first(where: { $0.name.lowercased() == name.rawValue.lowercased() }),
            let attributeValue = attribute.value.toString() else {
                return nil
        }
        
        return attributeValue
    }
}
