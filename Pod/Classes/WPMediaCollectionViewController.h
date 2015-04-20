@import UIKit;

@interface WPMediaCollectionViewController : UICollectionViewController

/**
 If set the picker will show a cell that allows capture of new media, that can be used immediatelly
 */
@property (nonatomic, assign) BOOL allowCaptureOfMedia;

/**
 If set the picker will show the most recent items on the top left. If not set it will show on the bottom right. Either way it will always scroll to the most recent item when showing the picker.
 */
@property (nonatomic, assign) BOOL showMostRecentFirst;

@end
