import Foundation
import UIKit

class VideoAttachmentToElementConverter: AttachmentToElementConverter {
    func convert(_ attachment: VideoAttachment, attributes: [NSAttributedString.Key : Any]) -> [Node] {
        let element: ElementNode
        
        if let representation = attributes[.videoHtmlRepresentation] as? HTMLRepresentation,
            case let .element(representationElement) = representation.kind {
            
            element = representationElement.toElementNode()
        } else {
            element = ElementNode(type: .video)
        }
        
        if let attribute = videoSourceAttribute(from: attachment) {
            element.updateAttribute(named: attribute.name, value: attribute.value)
        }
        
        if let attribute = videoPosterAttribute(from: attachment) {
            element.updateAttribute(named: attribute.name, value: attribute.value)
        }
        
        for attribute in attachment.extraAttributes {
            element.updateAttribute(named: attribute.name, value: attribute.value)
        }

        element.children = element.children + videoSourceElements(from: attachment)

        return [element]
    }
    
    /// Extracts the Video Source Attribute from a VideoAttachment Instance.
    ///
    private func videoSourceAttribute(from attachment: VideoAttachment) -> Attribute? {
        guard let source = attachment.url?.absoluteString else {
            return nil
        }
        
        return Attribute(type: .src, value: .string(source))
    }
    
    
    /// Extracts the Video Poster Attribute from a VideoAttachment Instance.
    ///
    private func videoPosterAttribute(from attachment: VideoAttachment) -> Attribute? {
        guard let poster = attachment.posterURL?.absoluteString else {
            return nil
        }
        
        return Attribute(name: "poster", value: .string(poster))
    }

    /// Extracts the Video source elements from a VideoAttachment Instance.
    ///
    private func videoSourceElements(from attachment: VideoAttachment) -> [Node] {
        var nodes = [Node]()
        for source in attachment.sources {
            var attributes = [Attribute]()
            if let src = source.src {
                let sourceAttribute = Attribute(type: .src, value: .string(src))
                attributes.append(sourceAttribute)
            }
            if let type = source.type {
                let typeAttribute = Attribute(name: "type", value: .string(type))
                attributes.append(typeAttribute)
            }
            nodes.append(ElementNode(type: .source, attributes: attributes, children: []))
        }
        return nodes
    }
}
