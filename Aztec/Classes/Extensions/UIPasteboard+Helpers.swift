import Foundation
import MobileCoreServices
import UIKit


// MARK: - Pasteboard Helpers
//
extension UIPasteboard {

    /// Attempts to load the Pasteboard's contents into a NSAttributedString Instance, if possible.
    ///
    func loadAttributedString() -> NSAttributedString? {

        if let string = aztecAttributedString {
            return string
        }

        if let string = RTFDAttributedString {
            return string
        }

        if let string = RTFAttributedString {
            return string
        }

        if let string = richTextAttributedString {
            return string
        }

        return plainTextAttributedString
    }
}


// MARK: - Pasteboard Private Helpers
//
private extension UIPasteboard {

    /// Attempts to unarchive the Pasteboard's RTF contents into an Attributed String
    ///
    var RTFAttributedString: NSAttributedString? {
        return unarchiveAttributedString(fromPasteboardCFType: kUTTypeRTF, with: StringOptions.RTFText)
    }

    /// Attempts to unarchive the Pasteboard's RTFD contents into an Attributed String
    ///
    var RTFDAttributedString: NSAttributedString? {
        return unarchiveAttributedString(fromPasteboardCFType: kUTTypeFlatRTFD, with: StringOptions.RTFDText)
    }

    /// Attempts to unarchive the Pasteboard's Text contents into an Attributed String
    ///
    var richTextAttributedString: NSAttributedString? {
        return unarchiveAttributedString(fromPasteboardCFType: kUTTypeText, with: StringOptions.RTFText)
    }

    /// Attempts to unarchive the Pasteboard's Plain Text contents into an Attributed String
    ///
    var plainTextAttributedString: NSAttributedString? {
        return unarchiveAttributedString(fromPasteboardCFType: kUTTypePlainText, with: StringOptions.plainText)
    }

    /// Attempts to unarchive the Pasteboard's Aztec-Archived String
    ///
    var aztecAttributedString: NSAttributedString? {
        guard let data = data(forPasteboardType: NSAttributedString.pastesboardUTI) else {
            return nil
        }

        return NSAttributedString.unarchive(with: data)
    }

    // MARK: - Helpers

    /// String Initialization Options
    ///
    private struct StringOptions {
        static let RTFText: [DocumentReadingOptionKey: DocumentType] = [.documentType: .rtf]
        static let RTFDText: [DocumentReadingOptionKey: DocumentType] = [.documentType: .rtfd]
        static let plainText: [DocumentReadingOptionKey: DocumentType] = [.documentType: .plain]
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
        
        return try? NSAttributedString.init(data: data, options: options, documentAttributes: nil)
    }
}
