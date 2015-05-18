@import Foundation;
@import Photos;

#import <WPMediaPicker/WPMediaPicker.h>

/**
 An implementation of the WPDataSource protocol using the Photos framework
 */
NS_CLASS_AVAILABLE_IOS(8_0) @interface WPPHAssetDataSource : NSObject<WPMediaCollectionDataSource>

@end

/**
 An implementation of the WPMediaAsset protocol using the PHAsset class
 */
NS_CLASS_AVAILABLE_IOS(8_0) @interface WPPHAssetMedia : NSObject<WPMediaAsset>

- (instancetype)initWithAsset:(PHAsset *)asset;

@end

/**
 An implementation of the WPMediaGroup protocol using the PHAssetCollection class
 */
NS_CLASS_AVAILABLE_IOS(8_0) @interface WPPHAssetCollection : NSObject<WPMediaGroup>

- (instancetype)initWithAssetCollection:(PHAssetCollection *)assetCollection;

@end
