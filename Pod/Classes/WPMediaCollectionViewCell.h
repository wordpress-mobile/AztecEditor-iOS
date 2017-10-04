@import UIKit;
#import "WPMediaCollectionDataSource.h"

@interface WPMediaCollectionViewCell : UICollectionViewCell

@property (nonatomic, strong) id<WPMediaAsset> asset;

@property (nonatomic, assign) NSInteger position;

@property (nonatomic, strong) UIColor *placeholderTintColor UI_APPEARANCE_SELECTOR;

@property (nonatomic, strong) UIColor *loadingBackgroundColor UI_APPEARANCE_SELECTOR;

@property (nonatomic, strong) UIColor *placeholderBackgroundColor UI_APPEARANCE_SELECTOR;

@property (nonatomic, strong) UIColor *positionLabelUnselectedTintColor UI_APPEARANCE_SELECTOR;

@property (nonatomic, assign) BOOL hiddenSelectionIndicator;

@end

