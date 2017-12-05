import UIKit

protocol MediaInserter {
    func insert(into inheritedAttribbutes: [AttributedStringKey: Any], from representation: HTMLRepresentation) -> [AttributedStringKey: Any]

    func attachment(from representation: HTMLRepresentation) -> MediaAttachment?

    static var htmlRepresentationKey: AttributedStringKey { get }
}


extension MediaInserter {
    func insert(into inheritedAttribbutes: [AttributedStringKey: Any], from representation: HTMLRepresentation) -> [AttributedStringKey: Any] {
        guard let attachment = attachment(from: representation) else {
            return inheritedAttribbutes
        }
        
        var copiedAttributes = inheritedAttribbutes

        copiedAttributes[.attachment] = attachment
        copiedAttributes[Self.htmlRepresentationKey] = representation

        return copiedAttributes
    }
}
