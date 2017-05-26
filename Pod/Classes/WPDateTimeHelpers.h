#import <Foundation/Foundation.h>

@interface WPDateTimeHelpers : NSObject

+ (NSString *)userFriendlyStringDateFromDate:(NSDate *)date;

+ (NSString *)userFriendlyStringTimeFromDate:(NSDate *)date;

+ (NSString *)stringFromTimeInterval:(NSTimeInterval)timeInterval;

@end
