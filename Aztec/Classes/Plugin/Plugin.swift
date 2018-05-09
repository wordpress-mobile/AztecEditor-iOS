import Foundation

protocol Plugin {
    func preProcessor() -> Processor?
    func postProcessor() -> Processor?
}
