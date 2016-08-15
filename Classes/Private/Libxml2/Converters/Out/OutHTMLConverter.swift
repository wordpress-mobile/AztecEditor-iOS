import Foundation
import libxml2

extension Libxml2.Out {
    class HTMLConverter: Converter {
        
        typealias Node = Libxml2.Node
        typealias ElementNode = Libxml2.ElementNode
        typealias RootNode = Libxml2.RootNode

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

            let finalString = htmlDumpString.stringByReplacingOccurrencesOfString("<\(RootNode.name)>", withString: "").stringByReplacingOccurrencesOfString("</\(RootNode.name)>", withString: "")
            
            return finalString
        }
    }
}
