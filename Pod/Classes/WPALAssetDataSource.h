@import Foundation;
@import AssetsLibrary;
#import "WPMediaPickerViewController.h"

@interface WPALAssetDataSource : NSObject<WPMediaCollectionDataSource>

@end

@interface WPALAssetDetail : NSObject<WPMediaAsset>
- (instancetype)initWithAsset:(ALAsset *)asset;
@end

@interface WPALAssetGroup : NSObject<WPMediaGroup>

- (instancetype)initWithAssetsGroup:(ALAssetsGroup *)assetsGroup;

@end
