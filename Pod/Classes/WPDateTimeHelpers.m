#import "WPDateTimeHelpers.h"

@implementation WPDateTimeHelpers

+ (NSString *)userFriendlyStringDateFromDate:(NSDate *)date {
    NSDate *now = [NSDate date];
    NSString *dateString = [[[self class] sharedDateFormater] stringFromDate:date];

    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDate *oneWeekAgo = [calendar dateByAddingUnit:NSCalendarUnitWeekOfYear value:-1 toDate:now options:0];
    if ([calendar isDateInToday:date]) {
        dateString = NSLocalizedString(@"Today", @"Reference to the current day.");
    } else if ([calendar isDateInYesterday:date]) {
        dateString = NSLocalizedString(@"Yesterday", @"Reference to the previous day.");
    } else if ([date compare:oneWeekAgo] == NSOrderedDescending) {
        dateString = [[[[self class] sharedDateWeekFormater] stringFromDate:date] capitalizedStringWithLocale:nil];
    }
    return dateString;
}

+ (NSString *)userFriendlyStringTimeFromDate:(NSDate *)date {
    return [[[self class] sharedTimeFormater] stringFromDate:date];
}

+ (NSDateFormatter *)sharedDateFormater {
    static NSDateFormatter * _sharedDateFormatter;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedDateFormatter = [[NSDateFormatter alloc] init];
        _sharedDateFormatter.dateStyle = NSDateFormatterLongStyle;
        _sharedDateFormatter.timeStyle = NSDateFormatterNoStyle;
    });
    return _sharedDateFormatter;
}

+ (NSDateFormatter *)sharedTimeFormater {
    static NSDateFormatter * _sharedTimeFormatter;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedTimeFormatter = [[NSDateFormatter alloc] init];
        _sharedTimeFormatter.dateStyle = NSDateFormatterNoStyle;
        _sharedTimeFormatter.timeStyle = NSDateFormatterShortStyle;
    });
    return _sharedTimeFormatter;
}

+ (NSDateFormatter *)sharedDateWeekFormater {
    static NSDateFormatter * _sharedDateWeekFormatter;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedDateWeekFormatter = [[NSDateFormatter alloc] init];
        _sharedDateWeekFormatter.dateFormat = [NSDateFormatter dateFormatFromTemplate:@"cccc" options:0 locale:nil];
    });
    return _sharedDateWeekFormatter;
}

@end
