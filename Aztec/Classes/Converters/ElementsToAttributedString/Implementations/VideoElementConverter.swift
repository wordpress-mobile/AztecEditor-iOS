import UIKit


/// Provides a representation for `<video>` element.
///
class VideoElementConverter: AttachmentElementConverter {
    
    // MARK: - AttachmentElementConverter
    
    typealias AttachmentType = VideoAttachment
    
    func convert(
        _ element: ElementNode,
        inheriting attributes: [NSAttributedString.Key: Any],
        contentSerializer serialize: ContentSerializer) -> (attachment: VideoAttachment, string: NSAttributedString) {
        
        let attachment = self.attachment(for: element)
        let intrinsicRepresentation = NSAttributedString(attachment: attachment, attributes: attributes)
        let serialization = serialize(element, intrinsicRepresentation, attributes, false)
        
        return (attachment, serialization)
    }
    
    // MARK: - Attachment Creation
    
    func attachment(for element: ElementNode) -> VideoAttachment {
        var extraAttributes = [Attribute]()

        for attribute in element.attributes {
            if let value = attribute.value.toString() {
                extraAttributes[attribute.name] = .string(value)
            }
        }

        let srcURL: URL?
        let srcAttribute = element.attributes.first(where: { $0.name == "src" })
        
        if let urlString = srcAttribute?.value.toString() {
            srcURL = URL(string: urlString)
            extraAttributes.remove(named: "src")
        } else {
            srcURL = nil
        }

        let posterURL: URL?
        let posterAttribute = element.attributes.first(where: { $0.name == "poster" })
        
        if let urlString = posterAttribute?.value.toString() {
            posterURL = URL(string: urlString)
            extraAttributes.remove(named: "poster")
        } else {
            posterURL = nil
        }

        let sources = extractSources(from: element)

        let attachment = VideoAttachment(identifier: UUID().uuidString, srcURL: srcURL, posterURL: posterURL, sources: sources)

        attachment.extraAttributes = extraAttributes

        return attachment
    }


    /// This method search for source elements on the children of the video element and return an array of VideoSource with the corresponding information.<#Description#>
    ///
    /// - Parameter element: the video element to search for sources
    /// - Returns: an array with the source information found
    ///
    private func extractSources(from element: ElementNode) -> [VideoSource] {
        var children = element.children

        //search for source subelements
        let sources = searchSources(in: element)

        children.removeAll(where: { $0 is ElementNode && $0.name == "source"})
        element.children = children
        return sources
    }

    /// This method recursively searches for source elements on the children of element provided and return an array of VideoSource with the corresponding information.
    ///
    /// - Parameter element: the element to search for sources
    /// - Returns: an array with the source information found
    ///
    private func searchSources(in element: ElementNode) -> [VideoSource] {
        var sources:[VideoSource] = []
        for node in element.children {
            guard let sourceElement = node as? ElementNode, sourceElement.name == "source" else {
                continue
            }
            let src = sourceElement.attributes.first(where: { $0.name == "src"} )?.value.toString()
            let type = sourceElement.attributes.first(where: { $0.name == "type"} )?.value.toString()
            sources.append(VideoSource(src: src, type: type) )
            sources.append(contentsOf: searchSources(in: sourceElement))
        }
        return sources
    }
}
