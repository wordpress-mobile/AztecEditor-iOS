import Foundation

/// A generic converter from C linked lists to regular arrays.  Requires an element converter and
/// a closure to obtain the next element (from the current one).
///
class CLinkedListToArrayConverter<ElementConverterType: Converter>: Converter {

    /// The element converter will be used to convert each element in the linked list (probably a C
    /// struct) into an element of the output array (probably a Swift class or struct).
    ///
    let elementConverter: ElementConverterType

    /// This closure will be used to navigate the C linked list.
    ///
    /// - Parameters:
    ///     - current: The current element in the linked list.
    ///
    /// - Returns: a pointer to the next element in the linked list.  Can be nil to signal the end
    ///         of the list is reached.
    ///
    let next: (_ current: ElementConverterType.TypeIn) -> (UnsafeMutablePointer<ElementConverterType.TypeIn>)

    /// Defines the TypeIn to fulfill the Converter contract.  Since this class converts from C
    /// linked lists to Swift arrays, it's going to be an UnsafeMutablePointer to whatever the
    /// element converter receives as input.
    ///
    typealias TypeIn = UnsafeMutablePointer<ElementConverterType.TypeIn>


    /// Defines the TypeOut to fulfill the Converter contract.  Since this class converts from C
    /// linked lists to Swift arrays, it's going to be a Swift array of whatever the element
    /// converter outputs.
    ///
    typealias TypeOut = [ElementConverterType.TypeOut]

    /// Main Initializer.
    ///
    /// - Parameters:
    ///     - elementConverter: the converter that will be used to convert each element in the input
    ///                     linked list into an element of the output array.
    ///     - next: the closure that will provide the next element in the list, given the current one.
    ///
    init(elementConverter: ElementConverterType, next: @escaping (ElementConverterType.TypeIn) -> (TypeIn)) {
        self.elementConverter = elementConverter
        self.next = next
    }

    func convert(_ inputPtr: TypeIn) throws -> TypeOut {
        var result = TypeOut()
        var nextPtr: UnsafeMutablePointer<ElementConverterType.TypeIn>? = inputPtr

        while let currentPtr = nextPtr {
            let element = currentPtr.pointee

            result.append(try elementConverter.convert(element))

            nextPtr = next(element)
        }

        return result
    }
}

/// A generic converter from C linked lists to regular arrays.  Requires an element converter and
/// a closure to obtain the next element (from the current one).
///
class SafeCLinkedListToArrayConverter<ElementConverterType: SafeConverter>: SafeConverter {

    /// The element converter will be used to convert each element in the linked list (probably a C
    /// struct) into an element of the output array (probably a Swift class or struct).
    ///
    let elementConverter: ElementConverterType

    /// This closure will be used to navigate the C linked list.
    ///
    /// - Parameters:
    ///     - current: The current element in the linked list.
    ///
    /// - Returns: a pointer to the next element in the linked list.  Can be nil to signal the end
    ///         of the list is reached.
    ///
    let next: (_ current: ElementConverterType.TypeIn) -> (TypeIn)

    /// Defines the TypeIn to fulfill the Converter contract.  Since this class converts from C
    /// linked lists to Swift arrays, it's going to be an UnsafeMutablePointer to whatever the
    /// element converter receives as input.
    ///
    typealias TypeIn = UnsafeMutablePointer<ElementConverterType.TypeIn>?


    /// Defines the TypeOut to fulfill the Converter contract.  Since this class converts from C
    /// linked lists to Swift arrays, it's going to be a Swift array of whatever the element
    /// converter outputs.
    ///
    typealias TypeOut = [ElementConverterType.TypeOut]

    /// Main Initializer.
    ///
    /// - Parameters:
    ///     - elementConverter: the converter that will be used to convert each element in the input
    ///                     linked list into an element of the output array.
    ///     - next: the closure that will provide the next element in the list, given the current one.
    ///
    init(elementConverter: ElementConverterType, next: @escaping (ElementConverterType.TypeIn) -> (TypeIn)) {
        self.elementConverter = elementConverter
        self.next = next
    }

    func convert(_ inputPtr: TypeIn) -> TypeOut {
        var result = TypeOut()
        var nextPtr: UnsafeMutablePointer<ElementConverterType.TypeIn>? = inputPtr

        while let currentPtr = nextPtr {
            let element = currentPtr.pointee
            
            result.append(elementConverter.convert(element))
            nextPtr = next(element)
        }
        
        return result
    }
}
