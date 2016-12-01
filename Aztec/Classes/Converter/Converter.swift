import Foundation

/// A protocol for classes that convert objects from an input type to an output type.
/// Conversion can fail.
///
protocol Converter {

    /// The type of the initial object that will be provided to this deserializer.
    ///
    associatedtype TypeIn

    /// The type of the final object that will be provided by this converter.
    ///
    associatedtype TypeOut

    /// Converts the from the input type to the output type.
    ///
    /// - Parameters:
    ///     - input: the input object to convert.
    ///
    /// - Returns: the converted object.
    ///
    func convert(_ input: TypeIn) throws -> TypeOut
}

/// A protocol for classes that convert objects from an input type to an output type.
/// Safe version - conversion cannot fail.
///
protocol SafeConverter {

    /// The type of the initial object that will be provided to this deserializer.
    ///
    associatedtype TypeIn

    /// The type of the final object that will be provided by this converter.
    ///
    associatedtype TypeOut

    /// Converts the from the input type to the output type.
    ///
    /// - Parameters:
    ///     - input: the input object to convert.
    ///
    /// - Returns: the converted object.
    ///
    func convert(_ input: TypeIn) -> TypeOut
}
