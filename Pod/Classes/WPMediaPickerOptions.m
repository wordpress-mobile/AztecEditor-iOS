#import <Foundation/Foundation.h>
#import "WPMediaPickerOptions.h"

@implementation WPMediaPickerOptions

static CGSize CameraPreviewSize =  {88.0, 88.0};

- (instancetype)init {
    self = [super init];
    if (self) {
        _allowCaptureOfMedia = YES;
        _preferFrontCamera = NO;
        _showMostRecentFirst = NO;
        _filter = WPMediaTypeVideo | WPMediaTypeImage;
        _cameraPreviewSize = CameraPreviewSize;
        _allowMultipleSelection = YES;
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone {
    WPMediaPickerOptions *options = [WPMediaPickerOptions new];
    options.allowCaptureOfMedia = self.allowCaptureOfMedia;
    options.preferFrontCamera = self.preferFrontCamera;
    options.showMostRecentFirst = self.showMostRecentFirst;
    options.filter = self.filter;
    options.cameraPreviewSize = self.cameraPreviewSize;
    options.allowMultipleSelection = self.allowMultipleSelection;

    return options;
}

@end
