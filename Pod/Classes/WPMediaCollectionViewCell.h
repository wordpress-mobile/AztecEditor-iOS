@import UIKit;
#import "WPMediaCollectionDataSource.h"

@interface WPMediaCollectionViewCell : UICollectionViewCell

@property (nonatomic, strong) id<WPMediaAsset> asset;
@property (nonatomic, assign) NSInteger position;

@end
