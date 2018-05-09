import Aztec
import Foundation

public extension Element {
    static let gutenblock = Element("gutenblock", isBlockLevel: true)
}

public class GutenbergPreProcessor: Processor {
    
    /// Pre processes Gutenberg block start comments, to replace them with an actual element opening tag.
    ///
    private class BlockStartProcessor: RegexProcessor {
        public init() {
            let regex = try! NSRegularExpression(pattern: "(<!-- +wp:)([a-zA-Z]+)( +-->)", options: [])
            
            super.init(regex: regex) { (match, text) -> String? in
                guard let blockName = match.captureGroup(in: 1, text: text) else {
                    return nil
                }
                
                return "<\(Element.gutenblock.rawValue) name=\"\(blockName)\">"
            }
        }
    }
    
    /// Pre processes Gutenberg block end comments, to replace them with an actual element closing tag.
    ///
    private class BlockEndProcessor: RegexProcessor {
        public init() {
            let regex = try! NSRegularExpression(pattern: "(<!-- +/wp:)([a-zA-Z]+)( +-->)", options: [])
            
            super.init(regex: regex) { (match, text) -> String? in
                guard let blockName = match.captureGroup(in: 1, text: text) else {
                    return nil
                }
                
                return "</\(Element.gutenblock.rawValue) name=\"\(blockName)\">"
            }
        }
    }
    
    private let blockStartProcessor = BlockStartProcessor()
    private let blockEndProcessor = BlockEndProcessor()

    public func process(_ text: String) -> String {
        var output = text
        
        output = blockStartProcessor.process(output)
        output = blockEndProcessor.process(output)
        
        return output
    }
}
