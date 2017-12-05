import UIKit

protocol MediaInserter {
    func insert(into inheritedAttribbutes: [AttributedStringKey: Any], from representation: HTMLRepresentation) -> [AttributedStringKey: Any]

    func attachment(from representation: HTMLRepresentation) -> MediaAttachment?
}


extension MediaInserter {
    func insert(into inheritedAttribbutes: [AttributedStringKey: Any], from representation: HTMLRepresentation) -> [AttributedStringKey: Any] {
        guard let attachment = attachment(from: representation) else {
            return inheritedAttribbutes
        }
        
        var copiedAttributes = inheritedAttribbutes

        copiedAttributes[.attachment] = attachment
        //Comment: Sergio Estevao (2017-10-30) - We are not passing the representation because it's all save inside the extraAttributes property of the attachment.

        return copiedAttributes
    }
}
