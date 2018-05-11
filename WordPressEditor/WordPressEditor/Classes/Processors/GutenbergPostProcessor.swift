import Aztec
import Foundation

public class GutenbergPostProcessor: Processor {
    
    private static func decode(base64Gutenblock: String) -> String {
        let data = Data(base64Encoded: base64Gutenblock)!
        return String(data: data, encoding: .utf16)!
    }
    
    private class SelfClosedBlockProcessor: RegexProcessor {
        public init() {
            let regex = try! NSRegularExpression(pattern: "(?:<!-- +wp:)(?:[^<>\\]]+)(?: +\\/-->)", options: [])
            
            super.init(regex: regex) { (match, text) -> String? in
                guard let base64Gutenblock = match.captureGroup(in: 0, text: text) else {
                    return nil
                }
                
                return GutenbergPostProcessor.decode(base64Gutenblock: base64Gutenblock)
            }
        }
    }
    
    /// Pre processes Gutenberg block start comments, to replace them with an actual element opening tag.
    ///
    private class BlockStartProcessor: RegexProcessor {
        public init() {
            let regex = try! NSRegularExpression(pattern: "<gutenblock +data=\"(.+?)\">", options: [])
            
            super.init(regex: regex) { (match, text) -> String? in
                guard let base64Gutenblock = match.captureGroup(in: 0, text: text) else {
                    return nil
                }
                
                return GutenbergPostProcessor.decode(base64Gutenblock: base64Gutenblock)
            }
        }
    }
    
    /// Pre processes Gutenberg block end comments, to replace them with an actual element closing tag.
    ///
    private class BlockEndProcessor: RegexProcessor {
        public init() {
            let regex = try! NSRegularExpression(pattern: "</ *gutenblock *>", options: [])
            
            super.init(regex: regex) { (_, _) -> String? in
                return
            }
        }
    }
    
    private let selfClosedBlockProcessor = SelfClosedBlockProcessor()
    private let blockStartProcessor = BlockStartProcessor()
    private let blockEndProcessor = BlockEndProcessor()
    
    public func process(_ text: String) -> String {
        var output = text
        
        output = selfClosedBlockProcessor.process(output)
        output = blockStartProcessor.process(output)
        output = blockEndProcessor.process(output)
        
        return output
    }
}
