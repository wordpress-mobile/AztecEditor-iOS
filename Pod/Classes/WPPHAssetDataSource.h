@import Foundation;
@import Photos;

#import "WPMediaCollectionDataSource.h"

/**
 An implementation of the WPDataSource protocol using the Photos framework
 */
NS_CLASS_AVAILABLE_IOS(8_0) @interface WPPHAssetDataSource : NSObject<WPMediaCollectionDataSource>

+ (instancetype)sharedInstance;

@end

/**
 An implementation of the WPMediaAsset protocol using the PHAsset class
 */
@interface PHAsset(WPMediaAsset)<WPMediaAsset>

@end

/**
 An implementation of the WPMediaGroup protocol using the PHAssetCollection class
 */
@interface PHAssetCollectionForWPMediaGroup : NSObject<WPMediaGroup>

- (instancetype)initWithCollection:(PHAssetCollection *)collection mediaType:(WPMediaType)mediaType dispatchQueue:(dispatch_queue_t)queue;

- (instancetype)initWithCollection:(PHAssetCollection *)collection mediaType:(WPMediaType)mediaType;

@end
