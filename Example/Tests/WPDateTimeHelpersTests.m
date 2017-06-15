#import <XCTest/XCTest.h>

@interface WPDateTimeHelpers : NSObject

+ (NSString *)userFriendlyStringDateFromDate:(NSDate *)date;

+ (NSString *)userFriendlyStringTimeFromDate:(NSDate *)date;

+ (NSString *)stringFromTimeInterval:(NSTimeInterval)timeInterval;

@end

@interface WPDateTimeHelpersTest : XCTestCase

@end

@implementation WPDateTimeHelpersTest

- (void)testStringFromTimeInterval
{
    NSTimeInterval timeInterval = 120;
    NSString * result = [WPDateTimeHelpers stringFromTimeInterval:timeInterval];
    XCTAssertEqualObjects(@"2:00", result);

    timeInterval = 119.4;
    result = [WPDateTimeHelpers stringFromTimeInterval:timeInterval];
    XCTAssertEqualObjects(@"2:00", result);

    timeInterval = 119.5;
    result = [WPDateTimeHelpers stringFromTimeInterval:timeInterval];
    XCTAssertEqualObjects(@"2:00", result);

    timeInterval = 0.1;
    result = [WPDateTimeHelpers stringFromTimeInterval:timeInterval];
    XCTAssertEqualObjects(@"0:01", result);

    timeInterval = 30;
    result = [WPDateTimeHelpers stringFromTimeInterval:timeInterval];
    XCTAssertEqualObjects(@"0:30", result);

    timeInterval = 60;
    result = [WPDateTimeHelpers stringFromTimeInterval:timeInterval];
    XCTAssertEqualObjects(@"1:00", result);

    timeInterval = 65;
    result = [WPDateTimeHelpers stringFromTimeInterval:timeInterval];
    XCTAssertEqualObjects(@"1:05", result);

    timeInterval = 3600;
    result = [WPDateTimeHelpers stringFromTimeInterval:timeInterval];
    XCTAssertEqualObjects(@"1:00:00", result);

    timeInterval = 3605;
    result = [WPDateTimeHelpers stringFromTimeInterval:timeInterval];
    XCTAssertEqualObjects(@"1:00:05", result);

    timeInterval = 3667;
    result = [WPDateTimeHelpers stringFromTimeInterval:timeInterval];
    XCTAssertEqualObjects(@"1:01:07", result);
}

- (void)testUserFriendlyStringDateFromDate {    
    XCTAssertThrows([WPDateTimeHelpers userFriendlyStringDateFromDate:nil]);
}
@end

