import Foundation

public protocol HTMLTreeProcessor {
    func process(_ rootNode: RootNode)
}

public class HTMLTreeProcessorPipeline: HTMLTreeProcessor {
    private let processors: [HTMLTreeProcessor]
    
    public required init(processors: [HTMLTreeProcessor]) {
        self.processors = processors
    }
    
    public func process(_ rootNode: RootNode) {
        for processor in processors {
            processor.process(rootNode)
        }
    }
}
