#import <XCTest/XCTest.h>
#import "WPDateTimeHelpers.h"

@interface NSString ()
+ (NSString *)emojiCharacterFromCoreEmojiFilename:(NSString *)filename;
+ (NSString *)emojiFromCoreEmojiImageTag:(NSString *)tag;
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
}

@end

