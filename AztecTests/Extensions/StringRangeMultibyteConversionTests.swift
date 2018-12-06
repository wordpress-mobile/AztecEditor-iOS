import XCTest
@testable import Aztec

class StringRangeMultibyteConversionTests: XCTestCase {

    let testCases = [
        "🤷‍♂️",
        "நி",
        "ပိ",
    ]

    func testThatRangesWithLowerBoundsIntersectingGraphemeClustersProduceValidRanges() {

        testCases.forEach{

            let validRange = NSString(string: $0).range(of: $0)

            let intersectingRange = NSRange(location: 1, length: 1)
            let calculatedRange = $0.range(fromUTF16NSRange: intersectingRange)

            XCTAssert(validRange.lowerBound == calculatedRange.lowerBound.encodedOffset)
            XCTAssert(validRange.upperBound == calculatedRange.upperBound.encodedOffset)
        }
    }

    func testThatRangesWithUpperBoundsIntersectingGraphemeClustersProduceValidRanges() {

        testCases.forEach{

            let intersectingRange = NSRange(location: 0, length: 1)

            let validRange = NSString(string: $0).range(of: $0)
            let calculatedRange = $0.range(fromUTF16NSRange: intersectingRange)

            XCTAssert(validRange.lowerBound == calculatedRange.lowerBound.encodedOffset)
            XCTAssert(validRange.upperBound == calculatedRange.upperBound.encodedOffset)
        }
    }

    func testThatRangesWithLowerBoundsOutsideOfStringProduceRangesWithLocationSetToZero() {

        let NSNotFoundRange = NSString(string: "").range(of: "foo")
        let calculatedRangeForNSNotFound = "".range(fromUTF16NSRange: NSNotFoundRange)
        XCTAssert(calculatedRangeForNSNotFound.lowerBound.encodedOffset == 0)

        let negativeIndexRange = NSRange(location: -50, length: 0)
        let calculatedRangeForNegativeIndex = "".range(fromUTF16NSRange: negativeIndexRange)
        XCTAssert(calculatedRangeForNegativeIndex.lowerBound.encodedOffset == 0)
    }

    func testThatRangesWithUpperBoundsOutsideOfStringProduceRangesWithCorrectedUpperBounds() {

        let candidate = "This is a string 👍🏽"
        let validRange = NSString(string: candidate).range(of: candidate)

        let intMaxRange = NSRange(location: 0, length: Int.max)
        let calculatedIntMaxRange = candidate.range(fromUTF16NSRange: intMaxRange)

        XCTAssert(validRange.lowerBound == calculatedIntMaxRange.lowerBound.encodedOffset)
        XCTAssert(validRange.upperBound == calculatedIntMaxRange.upperBound.encodedOffset)

        let offByOneRange = NSRange(location: 0, length: candidate.utf16.count + 1)
        let calculatedOffByOneRange = candidate.range(fromUTF16NSRange: offByOneRange)

        XCTAssert(validRange.lowerBound == calculatedOffByOneRange.lowerBound.encodedOffset)
        XCTAssert(validRange.upperBound == calculatedOffByOneRange.upperBound.encodedOffset)
    }
}
