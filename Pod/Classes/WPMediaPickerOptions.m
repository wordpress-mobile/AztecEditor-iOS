#import <Foundation/Foundation.h>
#import "WPMediaPickerOptions.h"

@implementation WPMediaPickerOptions

- (instancetype)init {
    self = [super init];
    if (self) {
        _allowCaptureOfMedia = YES;
        _preferFrontCamera = NO;
        _showMostRecentFirst = NO;
        _filter = WPMediaTypeVideo | WPMediaTypeImage;
        _allowMultipleSelection = YES;
        _scrollVertically = YES;
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone {
    WPMediaPickerOptions *options = [WPMediaPickerOptions new];
    options.allowCaptureOfMedia = self.allowCaptureOfMedia;
    options.preferFrontCamera = self.preferFrontCamera;
    options.showMostRecentFirst = self.showMostRecentFirst;
    options.filter = self.filter;
    options.allowMultipleSelection = self.allowMultipleSelection;
    options.scrollVertically = self.scrollVertically;

    return options;
}

@end
