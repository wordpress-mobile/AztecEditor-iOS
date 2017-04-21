import XCTest
@testable import Aztec

class StringRangeMappingTests: XCTestCase {

    func testMapNSRangeByFilteringString1() {
        let originalString = "Hello World!"
        let filteredString = " "

        let rangeToMap = NSRange(location: 0, length: originalString.characters.count)
        let expectedResult = NSRange(location: 0, length: originalString.characters.count - filteredString.characters.count)

        let mappedRange = originalString.map(range: rangeToMap, byFiltering: filteredString)

        XCTAssertEqual(mappedRange, expectedResult)
    }

    func testMapNSRangeByFilteringString2() {
        let originalString = "Hello 🌎 World!"
        let filteredString = " 🌎 "

        let rangeToMap = NSRange(location: 0, length: originalString.characters.count)
        let expectedResult = NSRange(location: 0, length: originalString.characters.count - filteredString.characters.count)

        let mappedRange = originalString.map(range: rangeToMap, byFiltering: filteredString)

        XCTAssertEqual(mappedRange, expectedResult)
    }

    func testMapNSRangeByFilteringString3() {
        let originalString = "Hello 🌎"
        let filteredString = "🌎"

        let rangeToMap = NSRange(location: 0, length: originalString.characters.count)
        let expectedResult = NSRange(location: 0, length: originalString.characters.count - filteredString.characters.count)

        let mappedRange = originalString.map(range: rangeToMap, byFiltering: filteredString)

        XCTAssertEqual(mappedRange, expectedResult)
    }
}
