import Foundation
import libxml2

extension Libxml2.In {
    class HTMLConverter: Converter {

        typealias RootNode = Libxml2.RootNode
        
        enum Error: String, Swift.Error {
            case NoRootNode = "No root node"
        }

        required init() {
        }

        /// Converts HTML data into an HTML Node representing the same data.
        ///
        /// - Parameters:
        ///     - html: the HTML string to convert.
        ///
        /// - Returns: the HTML root node.
        ///
        func convert(_ html: String) throws -> RootNode {

            // We wrap the HTML into a special root node, since it helps avoid conversion issues
            // with libxml2, where the library would add custom tags to "fix" the HTML code we
            // provide.
            //
            let wrappedHTML = "<\(RootNode.name)>\(html)</\(RootNode.name)>"
            let data = wrappedHTML.data(using: String.Encoding.utf8)!

            let bufferSize = 1024
            let buffer = Array<Int8>(repeating: 0, count: bufferSize)
            let htmlPtr = (data as NSData).bytes.bindMemory(to: Int8.self, capacity: data.count)

            let parserContext = htmlCreateMemoryParserCtxt(buffer, 1024)
            
            defer {
                htmlFreeParserCtxt(parserContext)
            }

            // We don't want <p> tags added automattically.
            //
            htmlHandleOmittedElem(0)

            let document = htmlCtxtReadMemory(parserContext,
                                              htmlPtr,
                                              Int32(wrappedHTML.lengthOfBytes(using: String.Encoding.utf8)),
                                              "",
                                              "UTF-8",
                                              Int32(HTML_PARSE_RECOVER.rawValue | HTML_PARSE_NODEFDTD.rawValue | HTML_PARSE_NOERROR.rawValue | HTML_PARSE_NOWARNING.rawValue | HTML_PARSE_NOIMPLIED.rawValue | HTML_PARSE_NOBLANKS.rawValue))
            
            defer {
                xmlFreeDoc(document)
            }

            let errorPtr = xmlGetLastError()

            if errorPtr != nil {
                if let messagePtr = errorPtr?.pointee.message {
                    let message = String(cString: messagePtr)

                    NSLog("Message: \(message)")
                }

                // Some errors are really not a problem for us (like "misplaced HTML tag"), so let's
                // keep going.  In the future we should analyze the different errors here and decide
                // if there's a need to handle any of them in a different way.
                //
            }

            let rootNodePtr = xmlDocGetRootElement(document)

            if let rootNode = rootNodePtr?.pointee  {

                // TODO: If the root node has siblings, they're loaded as children instead (by
                // libxml2).  We need to test this a bit more, because saving the HTML back will
                // produce a different result unless there's some way to identify this scenario.
                //
                // Example HTML: <a></a><b></b>
                //
                // It may be a good idea to wrap the HTML in a single fake root node before parsing
                // it to bypass this behaviour.
                //
                let nodeConverter = NodeConverter()

                guard let node = nodeConverter.convert(rootNode) as? RootNode else {
                    throw Error.NoRootNode
                }

                return node
            } else {
                throw Error.NoRootNode
            }
        }
    }
}
