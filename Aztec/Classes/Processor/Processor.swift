import Foundation

public protocol Processor {
    func process(_ text: String) -> String
}
