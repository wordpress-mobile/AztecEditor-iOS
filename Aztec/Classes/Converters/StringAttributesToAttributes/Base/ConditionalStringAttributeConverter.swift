import Foundation


/// A composite converter that selects a converted based on specialized logic.
/// The branch predicates are evaluated in order, and a match means the branch's
/// converter will be used for the conversion (interrupting further evaluation).
///
open class ConditionalStringAttributeConverter: StringAttributeConverter {
    
    /// A condition and a converter to be used if that condition is true.
    ///
    typealias Branch = (predicate: Predicate, converter: StringAttributeConverter)
    
    /// A predicate that will be used to select the converter that will be used
    /// for a conditional conversion.
    ///
    typealias Predicate = (_ attributes: [NSAttributedString.Key: Any]) -> Bool
    
    /// The branches representing our condition tree.
    ///
    private let branches: [Branch]
    
    /// Default initializer.
    ///
    init(branches: [Branch]) {
        self.branches = branches
    }
    
    // MARK: - StringAttributeConverter
    
    public func convert(
        attributes: [NSAttributedString.Key: Any],
        andAggregateWith elementNodes: [ElementNode]) -> [ElementNode] {
        
        guard let converter = converter(for: attributes) else {
            return elementNodes
        }
        
        return converter.convert(attributes: attributes, andAggregateWith: elementNodes)
    }
    
    // MARK: - Branch Resolution
    
    /// Retrieves the branch for the specified attributes.
    ///
    /// - Parameters:
    ///     - attributes: the attributes used to evaluate the branch predicates.
    ///
    /// - Returns: the branch that will convert the specified attributes, or `nil` if
    ///     no predicate matches those attributes.
    ///
    private func branch(for attributes: [NSAttributedString.Key: Any]) -> Branch? {
        return branches.first { $0.predicate(attributes) }
    }
    
    /// Retrieves the converter for the specified attributes.
    ///
    /// - Parameters:
    ///     - attributes: the attributes used to evaluate the branch predicates.
    ///
    /// - Returns: the converter that will convert the specified attributes, or `nil` if
    ///     no predicate matches those attributes.
    ///
    private func converter(for attributes: [NSAttributedString.Key: Any]) -> StringAttributeConverter? {
        return branch(for: attributes)?.converter
    }
}
