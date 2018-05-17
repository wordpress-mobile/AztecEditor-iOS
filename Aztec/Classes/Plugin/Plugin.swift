import Foundation

protocol Plugin {
    var inputHTMLProcessor: Processor? { get }
    var outputHTMLProcessor: Processor? { get }
    var inputHTMLTreeProcessor: HTMLTreeProcessor? { get }
    var outputHTMLTreeProcessor: HTMLTreeProcessor? { get }
    var elementConverter: ElementConverter? { get }
}
