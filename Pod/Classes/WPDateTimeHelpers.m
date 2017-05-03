#import "WPDateTimeHelpers.h"

@implementation WPDateTimeHelpers

+ (NSString *)userFriendlyStringDateFromDate:(NSDate *)date {
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

+ (NSString *)stringFromTimeInterval:(NSTimeInterval)timeInterval
{
    NSInteger roundedHours = floor(timeInterval / 3600);
    NSInteger roundedMinutes = floor((timeInterval - (3600 * roundedHours)) / 60);
    NSInteger roundedSeconds = ceil(timeInterval - (roundedHours * 60 * 60) - (roundedMinutes * 60));
    if (roundedSeconds == 60) {
        roundedSeconds = 0;
        roundedMinutes += 1;
    }
    if (roundedMinutes == 60) {
        roundedMinutes = 0;
        roundedHours += 1;
    }

    if (roundedHours > 0) {
        return [NSString stringWithFormat:@"%ld:%02ld:%02ld", (long)roundedHours, (long)roundedMinutes, (long)roundedSeconds];
    } else {
        return [NSString stringWithFormat:@"%ld:%02ld", (long)roundedMinutes, (long)roundedSeconds];
    }
}


@end
