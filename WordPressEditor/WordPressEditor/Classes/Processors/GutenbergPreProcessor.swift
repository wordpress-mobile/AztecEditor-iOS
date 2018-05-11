import Aztec
import Foundation

public extension Element {
    static let gutenblock = Element("gutenblock")
}

public class GutenbergPreProcessor: Processor {
    
    private static let classInitializer: () = {
        Element.blockLevelElements.append(.gutenblock)
    }()
    
    private static func encode(gutenblock: String) -> String {
        let data = gutenblock.data(using: .utf16)!
        let base64String = data.base64EncodedString()
            
        return base64String
    }
    
    private class SelfClosedBlockProcessor: RegexProcessor {
        public init() {
            let regex = try! NSRegularExpression(pattern: "(?:<!-- +wp:)(?:[^<>\\]]+)(?: +\\/-->)", options: [])
            
            super.init(regex: regex) { (match, text) -> String? in
                guard let gutenblock = match.captureGroup(in: 0, text: text) else {
                    return nil
                }
                
                return "<\(Element.gutenblock.rawValue) data=\"\(GutenbergPreProcessor.encode(gutenblock: gutenblock))\">"
            }
        }
    }
    
    /// Pre processes Gutenberg block start comments, to replace them with an actual element opening tag.
    ///
    private class BlockStartProcessor: RegexProcessor {
        public init() {
            let regex = try! NSRegularExpression(pattern: "(?:<!-- +wp:)(?:[^\\/].+?)(?: +-->)", options: [])
            
            super.init(regex: regex) { (match, text) -> String? in
                guard let gutenblock = match.captureGroup(in: 0, text: text) else {
                    return nil
                }
                
                return "<\(Element.gutenblock.rawValue) data=\"\(GutenbergPreProcessor.encode(gutenblock: gutenblock))\">"
            }
        }
    }
    
    /// Pre processes Gutenberg block end comments, to replace them with an actual element closing tag.
    ///
    private class BlockEndProcessor: RegexProcessor {
        public init() {
            let regex = try! NSRegularExpression(pattern: "(?:<!-- +\\/wp:)(?:.+?)(?: +-->)", options: [])
            
            super.init(regex: regex) { (_, _) -> String? in
                return "</\(Element.gutenblock.rawValue)>"
            }
        }
    }
    
    private let selfClosedBlockProcessor = SelfClosedBlockProcessor()
    private let blockStartProcessor = BlockStartProcessor()
    private let blockEndProcessor = BlockEndProcessor()

    public init() {
        // This is a hack to simulate a class initializer.  The closure will be executed once.
        GutenbergPreProcessor.classInitializer
    }
    
    public func process(_ text: String) -> String {
        var output = text
        
        output = selfClosedBlockProcessor.process(output)
        output = blockStartProcessor.process(output)
        output = blockEndProcessor.process(output)
        
        return output
    }
}
