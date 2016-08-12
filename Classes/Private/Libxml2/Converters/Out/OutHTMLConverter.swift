import Foundation
import libxml2

extension Libxml2.Out {
    class HTMLConverter: Converter {
        
        typealias Node = HTML.Node
        typealias ElementNode = HTML.ElementNode

        /// Converts the a Libxml2 Node into HTML representing the same data.
        ///
        /// - Parameters:
        ///     - rawNode: the Libxml2 Node to convert.
        ///
        /// - Returns: a String object representing the specified HTML data.
        ///
        func convert(rawNode: Node) -> String {
            
            let buf = xmlBufferCreate()
            let xmlDocPtr = xmlNewDoc(nil)

            let xmlNodePtr = Libxml2.Out.NodeConverter().convert(rawNode)
            
            xmlDocSetRootElement(xmlDocPtr, xmlNodePtr)
            htmlNodeDump(buf, xmlDocPtr, xmlNodePtr)
            
            let htmlDumpString = String(CString: UnsafePointer<Int8>(buf.memory.content), encoding: NSUTF8StringEncoding)!
            
            xmlFreeDoc(xmlDocPtr)
            xmlBufferFree(buf)

            let finalString = htmlDumpString.stringByReplacingOccurrencesOfString("<\(Aztec.AttributeName.rootNode)>", withString: "").stringByReplacingOccurrencesOfString("</\(Aztec.AttributeName.rootNode)>", withString: "")
            
            return finalString
        }
    }
}
