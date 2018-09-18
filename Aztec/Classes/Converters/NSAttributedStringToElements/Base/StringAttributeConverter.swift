import Foundation


/// This protocol is implemented by all of our classes that convert NSAttributedString attributes
/// into either ElementNodes or Attributes.
///
protocol StringAttributeConverter {
    func convert(
        attributes: [NSAttributedStringKey: Any],
        andAggregateWith elementNodes: [ElementNode]) -> [ElementNode]
}
