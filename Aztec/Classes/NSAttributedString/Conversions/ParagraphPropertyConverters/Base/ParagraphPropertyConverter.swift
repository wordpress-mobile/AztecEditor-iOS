import Foundation

public protocol ParagraphPropertyConverter {
    func convert(_ property: ParagraphProperty) -> ElementNode?
}
