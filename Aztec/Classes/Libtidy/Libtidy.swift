import Foundation
import libtidy


// MARK: - Tidy Wrapper
//
class Libtidy {

    /// Indicates whether we want the output string to be indented, or not
    ///
    var indentHtmlTags = false


    // MARK: - Initializers

    init() {
        // No Op
    }


    /// Returns a pretty version of the input HTML string/
    ///
    /// - Parameter html: HTML to-be-prettified
    ///
    /// - Returns: Pretty string, on success, or nil, on failure
    ///
    func prettify(html input: String) -> String? {
        guard input.isEmpty == false else {
            return nil
        }

        guard let document = tidyCreate() else {
            return nil
        }

        var output: String?
        var buffer = TidyBuffer()
        tidyBufInit(UnsafeMutablePointer<TidyBuffer>(&buffer))

        do {
            try setup(document: document, buffer: &buffer)
            try parse(string: input, document: document)
            output = try export(document: document)
        } catch {
            NSLog("Tidy Error: \(error)")
        }

        tidyBufFree(UnsafeMutablePointer<TidyBuffer>(&buffer))
        tidyRelease(document)

        return output
    }
}


// MARK: - Private Helpers
//
private extension Libtidy {

    /// Sets up a Tidy Document + Buffer
    ///
    func setup(document: TidyDoc, buffer: inout TidyBuffer) throws {
        guard tidyOptSetBool(document, TidyXmlTags, yes) == yes else {
            throw TidySetupErrors.xmlTag
        }

        guard tidyOptSetBool(document, TidyXmlOut, yes) == yes else {
            throw TidySetupErrors.xmlOut
        }

        guard tidyOptSetBool(document, TidyForceOutput, yes) == yes else {
            throw TidySetupErrors.output
        }

        if indentHtmlTags {
            guard tidyOptSetInt(document, TidyIndentContent, UInt(TidyAutoState.rawValue)) == yes else {
                throw TidySetupErrors.indent
            }
        }

        guard tidySetInCharEncoding(document, TidyConstants.utf8) >= 0 else {
            throw TidySetupErrors.encoding
        }

        guard tidySetOutCharEncoding(document, TidyConstants.utf8) >= 0 else {
            throw TidySetupErrors.encoding
        }

        guard tidySetErrorBuffer(document, UnsafeMutablePointer<TidyBuffer>(&buffer)) >= 0 else {
            throw TidySetupErrors.buffer
        }
    }

    /// Parses a plain String
    ///
    func parse(string: String, document: TidyDoc) throws {
        guard let utf8String = string.data(using: .utf8) else {
            throw TidyPrettifyErrors.parse
        }

        let result = utf8String.withUnsafeBytes { (inString: UnsafePointer<Int8>) -> Int32 in
            return tidyParseString(document, inString)
        }

        guard result >= 0 else {
            throw TidyPrettifyErrors.parse
        }

        guard tidyCleanAndRepair(document) >= 0 else {
            throw TidyPrettifyErrors.clean
        }

        guard tidyRunDiagnostics(document) >= 0 else {
            throw TidyPrettifyErrors.diagnostics
        }
    }

    /// Exports a Tidy Document into an UTF8 Encoded String
    ///
    func export(document: TidyDoc) throws -> String? {
        var length = uint(0)
        tidySaveString(document, nil, UnsafeMutablePointer<uint>(&length) )

        guard let mutableData = NSMutableData(length: Int(length)) else {
            throw TidyExportErrors.alloc
        }

        let dataAsInt8 = mutableData.mutableBytes.bindMemory(to: Int8.self, capacity: Int(length))
        guard tidySaveString(document, dataAsInt8, UnsafeMutablePointer<uint>(&length)) >= 0 else {
            throw TidyExportErrors.save
        }

        return String(data: mutableData as Data, encoding: .utf8)
    }
}


// MARK: - Helpers
//
extension Libtidy {

    struct TidyConstants {
        static let utf8 = "utf8".cString(using: .utf8)
    }

    enum TidyExportErrors: Error {
        case alloc
        case save
    }

    enum TidyPrettifyErrors: Error {
        case parse
        case clean
        case diagnostics
    }

    enum TidySetupErrors: Error {
        case xmlTag
        case xmlOut
        case indent
        case encoding
        case output
        case buffer
    }
}
