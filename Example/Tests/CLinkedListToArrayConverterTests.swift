import XCTest
@testable import Aztec

class CLinkedListToArrayConverterTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    struct TestStruct {
        var name: String
        var next: UnsafeMutablePointer<TestStruct>
    }

    class TestClass {
        let name: String

        init(name: String) {
            self.name = name
        }
    }

    class TestStructToClassConverter: Converter {
        func convert(input: TestStruct) -> TestClass {
            let testClass = TestClass(name: input.name)
            return testClass
        }
    }

    func testConversion() {
        var struct4 = TestStruct(name: "Struct 4", next: nil)
        var struct3 = TestStruct(name: "Struct 3", next: &struct4)
        var struct2 = TestStruct(name: "Struct 2", next: &struct3)
        var struct1 = TestStruct(name: "Struct 1", next: &struct2)

        // Useful for the final comparison.
        let structArray = [struct1, struct2, struct3, struct4]

        let elementConverter = TestStructToClassConverter()
        let listToArrayConverter = CLinkedListToArrayConverter(elementConverter: elementConverter, next: { return $0.next })

        let array = listToArrayConverter.convert(&struct1)

        XCTAssertEqual(array.count, structArray.count)

        for (index, element) in array.enumerate() {
            XCTAssertEqual(element.name, structArray[index].name)
        }
    }
}