import Foundation
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
        guard let htmlData = data(forPasteboardType: String(kUTTypeHTML)) else {
            return nil
        }
        
        return String(data: htmlData, encoding: .utf8)
    }
}

// MARK: - Attributed String Conversion

private extension UIPasteboard {

    // MARK: -
    
    /// Attempts to unarchive the Pasteboard's Aztec-Archived String
    ///
    private func aztecAttributedString() -> NSAttributedString? {
        guard let data = data(forPasteboardType: NSAttributedString.pastesboardUTI) else {
            return nil
        }
        
        return NSAttributedString.unarchive(with: data)
    }
    
    /// Attempts to unarchive the Pasteboard's Plain Text contents into an Attributed String
    ///
    private func plainTextAttributedString() -> NSAttributedString? {
        return unarchiveAttributedString(fromPasteboardCFType: kUTTypePlainText, with: StringOptions.plainText)
    }
    
    /// Attempts to unarchive the Pasteboard's Text contents into an Attributed String
    ///
    private func richTextAttributedString() -> NSAttributedString? {
        return unarchiveAttributedString(fromPasteboardCFType: kUTTypeText, with: StringOptions.RTFText)
    }
    
    /// Attempts to unarchive the Pasteboard's RTF contents into an Attributed String
    ///
    private func rtfAttributedString() -> NSAttributedString? {
        return unarchiveAttributedString(fromPasteboardCFType: kUTTypeRTF, with: StringOptions.RTFText)
    }

    /// Attempts to unarchive the Pasteboard's RTFD contents into an Attributed String
    ///
    private func rtfdAttributedString() -> NSAttributedString? {
        return unarchiveAttributedString(fromPasteboardCFType: kUTTypeFlatRTFD, with: StringOptions.RTFDText)
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
    private func unarchiveAttributedString(fromPasteboardCFType type: CFString, with options: [DocumentReadingOptionKey: Any]) -> NSAttributedString? {
        guard let data = data(forPasteboardType: String(type)) else {
            return nil
        }
        
        return try? NSAttributedString(data: data, options: options, documentAttributes: nil)
    }
}
