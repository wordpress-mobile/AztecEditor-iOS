@import Foundation;
@import AssetsLibrary;
#import "WPMediaCollectionDataSource.h"

@interface WPALAssetDataSource : NSObject<WPMediaCollectionDataSource>

@end

@interface WPALAssetMedia : NSObject<WPMediaAsset>

- (instancetype)initWithAsset:(ALAsset *)asset;

@end

@interface WPALAssetGroup : NSObject<WPMediaGroup>

- (instancetype)initWithAssetsGroup:(ALAssetsGroup *)assetsGroup;

@end
