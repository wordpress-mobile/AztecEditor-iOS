import Foundation

/// A generic converter for array elements.  Requires an element converter.
///
class ArrayConverter<ElementConverterType: Converter>: Converter {

    /// The element converter will be used to convert each element in the source array to the
    /// destination array.
    ///
    let elementConverter: ElementConverterType

    /// Main Initializer.
    ///
    /// - Parameters:
    ///     - elementConverter: the converter that will be used to convert each element in the input
    ///                     linked array into an element of the output array.
    ///
    init(elementConverter: ElementConverterType) {
        self.elementConverter = elementConverter
    }

    func convert(_ input: [ElementConverterType.TypeIn]) throws -> [ElementConverterType.TypeOut] {

        var output = TypeOut()

        for element in input {
            try output.append(elementConverter.convert(element))
        }

        return output
    }
}

/// A generic converter for array elements.  Requires an element converter.
///
class SafeArrayConverter<ElementConverterType: SafeConverter>: SafeConverter {

    /// The element converter will be used to convert each element in the source array to the
    /// destination array.
    ///
    let elementConverter: ElementConverterType

    /// Main Initializer.
    ///
    /// - Parameters:
    ///     - elementConverter: the converter that will be used to convert each element in the input
    ///                     linked array into an element of the output array.
    ///
    init(elementConverter: ElementConverterType) {
        self.elementConverter = elementConverter
    }

    func convert(_ input: [ElementConverterType.TypeIn]) -> [ElementConverterType.TypeOut] {

        var output = TypeOut()

        for element in input {
            output.append(elementConverter.convert(element))
        }

        return output
    }
}
