@import Foundation;
@import AssetsLibrary;
#import "WPMediaCollectionDataSource.h"

/**
 An implementation of the WPDataSource protocol using the AssetsLibrary framework
 */
@interface WPALAssetDataSource : NSObject<WPMediaCollectionDataSource>

@end

/**
 An implementation of the WPMediaAsset protocol using the ALAsset class
 */
@interface ALAsset(WPMediaAsset)<WPMediaAsset>

@end

/**
 An implementation of the WPMediaGroup protocol using the ALAssetsGroup class
 */
@interface ALAssetsGroup(WPMediaGroup)<WPMediaGroup>

@end
