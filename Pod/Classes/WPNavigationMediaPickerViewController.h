@import UIKit;
#import "WPMediaCollectionDataSource.h"

@protocol WPMediaPickerViewControllerDelegate;

@interface WPNavigationMediaPickerViewController : UIViewController

@property (nonatomic, weak) _Nullable id<WPMediaPickerViewControllerDelegate> delegate;

/**
 The object that acts as the data source of the media picker.
 
 @Discussion
 If no object is defined before the picker is show then the picker will use a shared data source that access the user media library.
*/
@property (nonatomic, weak) _Nullable id<WPMediaCollectionDataSource> dataSource;

/**
 If set the picker will show a cell that allows capture of new media, that can be used immediatelly
 */
@property (nonatomic, assign) BOOL allowCaptureOfMedia;

/**
 If the media picker allows media capturing, it will use the front camera by default when possible
 */
@property (nonatomic, assign) BOOL preferFrontCamera;

/**
 If set the picker will allow the selection of multiple items. By default this value is YES.
 */
@property (nonatomic, assign) BOOL allowMultipleSelection;

/**
 If set the picker will show the most recent items on the top left. If not set it will show on the bottom right. Either way it will always scroll to the most recent item when showing the picker.
 */
@property (nonatomic, assign) BOOL showMostRecentFirst;

/**
 *  Sets what kind of elements the picker show: allAssets, allPhotos, allVideos
 */
@property (nonatomic, assign) WPMediaType filter;


/**
 Pushes a given ViewController into the internal UINavigationController. Useful for post-processing steps.
 */
- (void)showAfterViewController:(nonnull UIViewController *)viewController;

@property (nonatomic, strong, readonly) UICollectionViewFlowLayout * _Nonnull layout;

@end
