import Foundation
import UIKit


/// HTML Attachments: Represents unknown HTML
///
open class HTMLAttachment: NSTextAttachment, RenderableAttachment  {

    /// Internal Cached Image
    ///
    fileprivate var glyphImage: UIImage?

    /// Delegate
    ///
    public weak var delegate: RenderableAttachmentDelegate?

    /// Name of the Root "Unknown" Tag
    ///
    open var rootTagName: String = "" {
        didSet {
            glyphImage = nil
        }
    }

    /// Raw Unknown HTML to be rendered
    ///
    open var rawHTML: String = "" {
        didSet {
            rootTagName = extractRootTagName(from: rawHTML)
        }
    }


    // MARK: - Initializers

    public init() {
        super.init(data: nil, ofType: nil)
    }

    public required init?(coder aDecoder: NSCoder) {
        super.init(data: nil, ofType: nil)

        guard let rootTagName = aDecoder.decodeObject(forKey: Keys.rootTagName) as? String,
            let rawHTML = aDecoder.decodeObject(forKey: Keys.rawHTML) as? String
            else {
                return
        }

        self.rootTagName = rootTagName
        self.rawHTML = rawHTML
    }


    /// Extracts the root tag name from a given HTML string
    ///
    private func extractRootTagName(from html: String) -> String {
        let root = HTMLParser().parse(html)
        let firstChildren = root.children.first

        return firstChildren?.name ?? NSLocalizedString("Unknown", comment: "Unknown Tag Name")
    }


    /// Returns the Pretty Printed version of the contained HTML
    ///
    open func prettyHTML() -> String {
        let htmlParser = HTMLParser()
        let serializer = HTMLSerializer()

        let inNode = htmlParser.parse(rawHTML)
        return serializer.serialize(inNode, prettify: true)
    }


    // MARK: - NSCoder Methods

    open override func encode(with aCoder: NSCoder) {
        super.encode(with: aCoder)

        aCoder.encode(rootTagName, forKey: Keys.rootTagName)
        aCoder.encode(rawHTML, forKey: Keys.rawHTML)
    }


    // MARK: - NSTextAttachmentContainer

    override open func image(forBounds imageBounds: CGRect, textContainer: NSTextContainer?, characterIndex charIndex: Int) -> UIImage? {
        if let cachedImage = glyphImage, imageBounds.size.equalTo(cachedImage.size) {
            return cachedImage
        }

        glyphImage = delegate?.attachment(self, imageForSize: imageBounds.size)

        return glyphImage
    }

    override open func attachmentBounds(for textContainer: NSTextContainer?, proposedLineFragment lineFrag: CGRect, glyphPosition position: CGPoint, characterIndex charIndex: Int) -> CGRect {
        guard let bounds = delegate?.attachment(self, boundsForLineFragment: lineFrag) else {
            assertionFailure("Could not determine HTML Attachment Size")
            return .zero
        }

        return bounds
    }
}


// MARK: - NSCopying
//
extension HTMLAttachment: NSCopying {

    public func copy(with zone: NSZone? = nil) -> Any {
        let clone = HTMLAttachment()
        clone.rawHTML = rawHTML
        clone.delegate = delegate
        return clone
    }
}


// MARK: - Private Helpers
//
private extension HTMLAttachment {

    struct Keys {
        static let rootTagName  = "rootTagName"
        static let rawHTML      = "rawHTML"
    }
}
