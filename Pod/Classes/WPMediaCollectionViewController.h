@import UIKit;
#import "WPMediaGroupPickerViewController.h"

@interface WPMediaCollectionViewController : UICollectionViewController

/**
 If set the picker will show a cell that allows capture of new media, that can be used immediatelly
 */
@property (nonatomic, assign) BOOL allowCaptureOfMedia;

/**
 If set the picker will show the most recent items on the top left. If not set it will show on the bottom right. Either way it will always scroll to the most recent item when showing the picker.
 */
@property (nonatomic, assign) BOOL showMostRecentFirst;

/**
 *  Sets what kind of elements the picker show: allAssets, allPhotos, allVideos
 */
@property (nonatomic, assign) WPMediaType filter;

/**
 If set the picker will allow the selection of multiple items. By default this value is YES.
 */
@property (nonatomic, assign) BOOL allowMultipleSelection;

/**
  The object that acts as the data source of the media picker.
 */
@property (nonatomic, weak) id<WPMediaCollectionDataSource> dataSource;

@end
