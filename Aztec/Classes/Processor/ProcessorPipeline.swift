import Foundation

open class ProcessorPipeline: Processor {
    private let processors: [Processor]

    public init(_ processors: [Processor]) {
        self.processors = processors
    }

    open func process(_ text: String) -> String {
        return processors.reduce(text, { (previousText, processor) -> String in
            return processor.process(previousText)
        })
    }
}
