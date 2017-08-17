#import "WPDateTimeHelpers.h"

@implementation WPDateTimeHelpers

+ (NSString *)userFriendlyStringDateFromDate:(NSDate *)date {
    NSAssert(date != nil, @"Date cannot be nil");
    NSDate *now = [NSDate date];
    NSString *dateString = [[[self class] sharedDateFormatter] stringFromDate:date];

    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDate *oneWeekAgo = [calendar dateByAddingUnit:NSCalendarUnitWeekOfYear value:-1 toDate:now options:0];
    if ([calendar isDateInToday:date]) {
        dateString = NSLocalizedString(@"Today", @"Reference to the current day.");
    } else if ([calendar isDateInYesterday:date]) {
        dateString = NSLocalizedString(@"Yesterday", @"Reference to the previous day.");
    } else if ([date compare:oneWeekAgo] == NSOrderedDescending) {
        dateString = [[[[self class] sharedDateWeekFormatter] stringFromDate:date] capitalizedStringWithLocale:nil];
    }
    return dateString;
}

+ (NSString *)userFriendlyStringTimeFromDate:(NSDate *)date {
    NSAssert(date != nil, @"Date cannot be nil");
    return [[[self class] sharedTimeFormatter] stringFromDate:date];
}

+ (NSDateFormatter *)sharedDateFormatter {
    static NSDateFormatter * _sharedDateFormatter;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedDateFormatter = [[NSDateFormatter alloc] init];
        _sharedDateFormatter.dateStyle = NSDateFormatterLongStyle;
        _sharedDateFormatter.timeStyle = NSDateFormatterNoStyle;
    });
    return _sharedDateFormatter;
}

+ (NSDateFormatter *)sharedTimeFormatter {
    static NSDateFormatter * _sharedTimeFormatter;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedTimeFormatter = [[NSDateFormatter alloc] init];
        _sharedTimeFormatter.dateStyle = NSDateFormatterNoStyle;
        _sharedTimeFormatter.timeStyle = NSDateFormatterShortStyle;
    });
    return _sharedTimeFormatter;
}

+ (NSDateFormatter *)sharedDateWeekFormatter {
    static NSDateFormatter * _sharedDateWeekFormatter;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedDateWeekFormatter = [[NSDateFormatter alloc] init];
        _sharedDateWeekFormatter.dateFormat = [NSDateFormatter dateFormatFromTemplate:@"cccc" options:0 locale:nil];
    });
    return _sharedDateWeekFormatter;
}

+ (NSDateComponentsFormatter *)sharedDateComponentsFormatter {
    static NSDateComponentsFormatter *_sharedDateComponentsFormatter;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedDateComponentsFormatter = [NSDateComponentsFormatter new];
        _sharedDateComponentsFormatter.zeroFormattingBehavior = NSDateComponentsFormatterZeroFormattingBehaviorPad;
        _sharedDateComponentsFormatter.allowedUnits = (NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond);
    });

    return _sharedDateComponentsFormatter;
}

+ (NSString *)stringFromTimeInterval:(NSTimeInterval)timeInterval
{
    NSTimeInterval interval = ceil(timeInterval);
    NSInteger hours = (interval / 3600);

    if (hours > 0) {
        [[self class] sharedDateComponentsFormatter].allowedUnits = (NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond);
    } else {
        [[self class] sharedDateComponentsFormatter].allowedUnits = (NSCalendarUnitMinute | NSCalendarUnitSecond);
    }

    return [[[self class] sharedDateComponentsFormatter] stringFromTimeInterval:interval];
}

@end
