import Foundation
import libtidy


// MARK: -
//
open class Libtidy {


    // MARK: - Initializers

    public init() {

    }


    ///
    ///
    open func prettify(html input: String) -> String? {
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


// MARK: -
//
private extension Libtidy {

    ///
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

//        guard tidyOptSetInt(document, TidyIndentContent, UInt(TidyAutoState.rawValue)) == yes else {
//            throw TidySetupErrors.indent
//        }

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

    ///
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

    ///
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


// MARK: -
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

// let test = NSString(bytes: buffer.bp, length: Int(buffer.size), encoding: String.Encoding.utf8.rawValue)
// NSLog("Error: \(test)")
