@import Foundation;

#import "WPMediaPickerViewController.h"

@interface WPALAssetDataSource : NSObject<WPMediaCollectionDataSource>

@end

@interface WPALAssetDetail : NSObject<WPMediaDetail>
- (instancetype)initWithAsset:(ALAsset *)asset;
@end
