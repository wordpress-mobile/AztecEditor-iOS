@import Foundation;

#import "WPMediaPickerViewController.h"

@interface WPALAssetDataSource : NSObject<WPMediaCollectionDataSource>

@end

@interface WPALAssetDetail : NSObject<WPMediaAsset>
- (instancetype)initWithAsset:(ALAsset *)asset;
@end
