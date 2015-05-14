@import Foundation;
@import Photos;

#import <WPMediaPicker/WPMediaPicker.h>

@interface WPPHAssetDataSource : NSObject<WPMediaCollectionDataSource>

@end

@interface WPPHAssetMedia : NSObject<WPMediaAsset>

- (instancetype)initWithAsset:(PHAsset *)asset;

@end

@interface WPPHAssetCollection : NSObject<WPMediaGroup>

- (instancetype)initWithAssetCollection:(PHAssetCollection *)assetCollection;

@end
