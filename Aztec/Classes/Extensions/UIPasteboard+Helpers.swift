import Foundation
import MobileCoreServices
import UIKit


// MARK: - Pasteboard Helpers
//
extension UIPasteboard
{
    ///
    ///
    private struct StringOptions {
        static let RTFText = [NSDocumentTypeDocumentAttribute: NSRTFTextDocumentType]
        static let RTFDText = [NSDocumentTypeDocumentAttribute: NSRTFDTextDocumentType]
        static let plainText = [NSDocumentTypeDocumentAttribute: NSPlainTextDocumentType]
    }

    ///
    ///
    private func unarchiveAttributedString(fromPasteboardCFType type: CFString, with options: [String: Any]) -> NSAttributedString? {
        guard let data = data(forPasteboardType: String(type)) else {
            return nil
        }

        return try? NSAttributedString(data: data, options: options, documentAttributes: nil)
    }


    ///
    ///
    func loadAttributedString() -> NSAttributedString? {
        if let string = aztecAttributedString {
            return string
        }

        if let string = RTFAttributedString {
            return string
        }

        if let string = RTFDAttributedString {
            return string
        }

        if let string = richTextAttributedString {
            return string
        }

        return plainTextAttributedString
    }

    ///
    ///
    private var RTFAttributedString: NSAttributedString? {
        return unarchiveAttributedString(fromPasteboardCFType: kUTTypeRTF, with: StringOptions.RTFText)
    }

    ///
    ///
    private var RTFDAttributedString: NSAttributedString? {
        return unarchiveAttributedString(fromPasteboardCFType: kUTTypeFlatRTFD, with: StringOptions.RTFDText)
    }

    ///
    ///
    private var richTextAttributedString: NSAttributedString? {
        return unarchiveAttributedString(fromPasteboardCFType: kUTTypeText, with: StringOptions.RTFText)
    }

    ///
    ///
    private var plainTextAttributedString: NSAttributedString? {
        return unarchiveAttributedString(fromPasteboardCFType: kUTTypePlainText, with: StringOptions.plainText)
    }


    ///
    ///
    private var aztecAttributedString: NSAttributedString? {
        guard let data = data(forPasteboardType: NSAttributedString.pastesboardUTI) else {
            return nil
        }

        return NSAttributedString.unarchive(with: data)
    }


//        let fullRange = stripped.rangeOfEntireString
//        stripped.removeAttribute(NSFontAttributeName, range: fullRange)
//        stripped.removeAttribute(NSStrikethroughStyleAttributeName, range: fullRange)
//        stripped.removeAttribute(NSUnderlineStyleAttributeName, range: fullRange)
}
