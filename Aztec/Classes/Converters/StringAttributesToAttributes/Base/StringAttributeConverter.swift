import Foundation


/// This protocol is implemented by all of our classes that convert NSAttributedString attributes
/// into either ElementNodes or Attributes.
///
public protocol StringAttributeConverter {
    
    func convert(
        attributes: [NSAttributedString.Key: Any],
        andAggregateWith elementNodes: [ElementNode]) -> [ElementNode]
}
