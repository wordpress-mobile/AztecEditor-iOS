@import UIKit;
#import "WPMediaCollectionDataSource.h"

@interface WPMediaCapturePresenter : NSObject

/// Only image and video types are supported
@property (nonatomic) WPMediaType mediaType;

/// Present front camera if available
@property (nonatomic) BOOL preferFrontCamera;

/// Called when the capture view has been dismissed.
/// mediaInfo will be populated if an image / video was captured.
@property (nonatomic, copy, nullable) void (^completionBlock)(NSDictionary * _Nullable mediaInfo);

+ (BOOL)isCaptureAvailable;

/// @param viewController The view controller to present the capture view from.
- (nonnull instancetype)initWithPresentingViewController:(nonnull UIViewController *)viewController;

/// Present the capture interface
- (void)presentCapture;

@end
