import Foundation
import UniformTypeIdentifiers
import MobileCoreServices
import UIKit

// MARK: - Pasteboard Helpers
//
extension UIPasteboard {

    /// Attempts to retrieve the Pasteboard's contents as an attributed string, if possible.
    ///
    func attributedString() -> NSAttributedString? {
        
        if let string = aztecAttributedString() {
            return string
        }

        if let string = rtfdAttributedString() {
            return string
        }

        if let string = rtfAttributedString() {
            return string
        }

        if let string = richTextAttributedString() {
            return string
        }

        return plainTextAttributedString()
    }
    
    func html() -> String? {
        guard let htmlData = data(forPasteboardType: UTType.html.identifier) else {
            return nil
        }
        
        return String(data: htmlData, encoding: .utf8)
    }

    // Compatibility Helper for using UTType before iOS14's UniformTypeIdentifiers
    // Feel free to remove once Deployment Target of the project gets bumped to >14.0
    struct UTType {
        let identifier: String

        static let html: UTType = {
            if #available(iOS 14.0, *) {
                UTType(identifier: UniformTypeIdentifiers.UTType.html.identifier)
            } else {
                UTType(identifier: kUTTypeHTML as String)
            }
        }()
        static let plainText: UTType = {
            if #available(iOS 14.0, *) {
                UTType(identifier: UniformTypeIdentifiers.UTType.utf8PlainText.identifier)
            } else {
                UTType(identifier: kUTTypeUTF8PlainText as String)
            }
        }()
        static let richText: UTType = {
            if #available(iOS 14.0, *) {
                UTType(identifier: UniformTypeIdentifiers.UTType.text.identifier)
            } else {
                UTType(identifier: kUTTypeText as String)
            }
        }()
        static let RTFText: UTType = {
            if #available(iOS 14.0, *) {
                UTType(identifier: UniformTypeIdentifiers.UTType.rtf.identifier)
            } else {
                UTType(identifier: kUTTypeRTF as String)
            }
        }()
        static let RTFDText: UTType = {
            if #available(iOS 14.0, *) {
                UTType(identifier: UniformTypeIdentifiers.UTType.flatRTFD.identifier)
            } else {
                UTType(identifier: kUTTypeFlatRTFD as String)
            }
        }()
        static let URL: UTType = {
            if #available(iOS 14.0, *) {
                UTType(identifier: UniformTypeIdentifiers.UTType.url.identifier)
            } else {
                UTType(identifier: kUTTypeURL as String)
            }
        }()
    }

    func store(_ data: Any, as type: UTType) {
        if numberOfItems > 0 {
            items[0][type.identifier] = data
        } else {
            addItems([[type.identifier: data]])
        }
    }
}

// MARK: - Attributed String Conversion

private extension UIPasteboard {

    // MARK: -
    /// Attempts to unarchive the Pasteboard's Aztec-Archived String
    ///
    private func aztecAttributedString() -> NSAttributedString? {
        guard let data = data(forPasteboardType: NSAttributedString.pasteboardUTI.identifier) else {
            return nil
        }
        
        return try? NSAttributedString.unarchive(with: data)
    }
    
    /// Attempts to unarchive the Pasteboard's Plain Text contents into an Attributed String
    ///
    private func plainTextAttributedString() -> NSAttributedString? {
        return unarchiveAttributedString(fromPasteboardType: .plainText, with: StringOptions.plainText)
    }
    
    /// Attempts to unarchive the Pasteboard's Text contents into an Attributed String
    ///
    private func richTextAttributedString() -> NSAttributedString? {
        return unarchiveAttributedString(fromPasteboardType: .richText, with: StringOptions.RTFText)
    }
    
    /// Attempts to unarchive the Pasteboard's RTF contents into an Attributed String
    ///
    private func rtfAttributedString() -> NSAttributedString? {
        return unarchiveAttributedString(fromPasteboardType: .RTFText, with: StringOptions.RTFText)
    }

    /// Attempts to unarchive the Pasteboard's RTFD contents into an Attributed String
    ///
    private func rtfdAttributedString() -> NSAttributedString? {
        return unarchiveAttributedString(fromPasteboardType: .RTFDText, with: StringOptions.RTFDText)
    }

    // MARK: - Helpers

    /// String Initialization Options
    ///
    private struct StringOptions {
        static let html: [DocumentReadingOptionKey: DocumentType] = [.documentType: .html]
        static let plainText: [DocumentReadingOptionKey: DocumentType] = [.documentType: .plain]
        static let RTFText: [DocumentReadingOptionKey: DocumentType] = [.documentType: .rtf]
        static let RTFDText: [DocumentReadingOptionKey: DocumentType] = [.documentType: .rtfd]
    }

    /// Attempts to unarchive a Pasteboard's Entry into a NSAttributedString Instance.
    ///
    /// - Parameters:
    ///     - type: Pasteboard's Attribute Key
    ///     - options: Properties to be utilized during the NSAttributedString Initialization.
    ///
    /// - Returns: NSAttributed String with the contents of the specified Pasteboard entry, if any.
    ///
    private func unarchiveAttributedString(fromPasteboardType type: UTType, with options: [DocumentReadingOptionKey: Any]) -> NSAttributedString? {
        guard let data = data(forPasteboardType: type.identifier) else {
            return nil
        }
        
        return try? NSAttributedString(data: data, options: options, documentAttributes: nil)
    }
}
