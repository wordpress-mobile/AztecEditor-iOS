@import UIKit;
@import AssetsLibrary;

typedef NS_ENUM(NSInteger, WPMediaType){
    WPMediaTypeImage,
    WPMediaTypeVideo,
    WPMediaTypeOther,
    WPMediaTypeAll
};

@protocol WPMediaGroup <NSObject>

- (NSString *)name;
- (UIImage *)thumbnailWithSize:(CGSize)size;
- (id)originalGroup;
- (NSString *)identifier;
- (NSInteger)numberOfAssets;

@end

@protocol WPMediaAsset <NSObject>

- (UIImage *)thumbnailWithSize:(CGSize)size;
- (WPMediaType)mediaType;
- (NSNumber *)duration;
- (id)originalAsset;
- (NSString *)identifier;
- (NSDate *)date;

@end

typedef void (^WPMediaChangesBlock)();
typedef void (^WPMediaFailureBlock)(NSError *error);
typedef void (^WPMediaAddedBlock)(id<WPMediaAsset> media, NSError *error);

@protocol WPMediaCollectionDataSource <NSObject>

- (NSInteger)numberOfGroups;

- (id<WPMediaGroup>)groupAtIndex:(NSInteger)index;

- (void)selectGroupAtIndex:(NSInteger)index;

- (id<WPMediaGroup>)selectedGroup;

- (void)setSelectedGroup:(id<WPMediaGroup>)group;

- (id<WPMediaAsset>) mediaAtIndex:(NSInteger)index;

- (void)registerChangeObserverBlock:(WPMediaChangesBlock)callback;

- (void)loadDataWithSuccess:(WPMediaChangesBlock)successBlock
                    failure:(WPMediaFailureBlock)failureBlock;

- (void)addImage:(UIImage *)image metadata:(NSDictionary *)metadata completionBlock:(WPMediaAddedBlock)completionBlock;

- (void)addVideoFromURL:(NSURL *)url  completionBlock:(WPMediaAddedBlock)completionBlock;

@end

@protocol WPMediaPickerViewControllerDelegate;

@interface WPMediaPickerViewController : UIViewController

@property (nonatomic, weak) id<WPMediaPickerViewControllerDelegate> delegate;

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
@property (nonatomic, strong) ALAssetsFilter *assetsFilter;

/**
 If set the picker will allow the selection of multiple items. By default this value is YES.
 */
@property (nonatomic, assign) BOOL allowMultipleSelection;


@end

/**
 *  The `WPMediaPickerViewControllerDelegate` protocol defines methods that allow you to to interact with the assets picker interface
 *  and manage the selection and highlighting of assets in the picker.
 *
 *  The methods of this protocol notify your delegate when the user selects, finish picking assets, or cancels the picker operation.
 *
 *  The delegate methods are responsible for dismissing the picker when the operation completes.
 *  To dismiss the picker, call the `dismissViewControllerAnimated:completion:` method of the presenting controller
 *  responsible for displaying `WPMediaPickerController` object.
 *
 *  The picked assets can be processed by accessing the `defaultRepresentation` property.
 *  It returns an `ALAssetRepresentation` object which encapsulates one of the representations of `ALAsset` object.
 */
@protocol WPMediaPickerViewControllerDelegate <NSObject>

/**
 *  @name Closing the Picker
 */

/**
 *  Tells the delegate that the user finish picking photos or videos.
 *
 *  @param picker The controller object managing the assets picker interface.
 *  @param assets An array containing picked `WPMediaAsset` objects.
 *
 */
- (void)mediaPickerController:(WPMediaPickerViewController *)picker didFinishPickingAssets:(NSArray *)assets;

@optional

/**
 *  Tells the delegate that the user cancelled the pick operation.
 *
 *  @param picker The controller object managing the assets picker interface.
 *
 */
- (void)mediaPickerControllerDidCancel:(WPMediaPickerViewController *)picker;

/**
 *  @name Enabling Assets
 */

/**
 *  Ask the delegate if the specified asset shoule be shown.
 *
 *  @param picker The controller object managing the assets picker interface.
 *  @param asset  The asset to be shown.
 *
 *  @return `YES` if the asset should be shown or `NO` if it should not.
 *
 */
- (BOOL)mediaPickerController:(WPMediaPickerViewController *)picker shouldShowAsset:(id<WPMediaAsset>*)asset;

/**
 *  Ask the delegate if the specified asset should be enabled for selection.
 *
 *  @param picker The controller object managing the assets picker interface.
 *  @param asset  The asset to be enabled.
 *
 *  @return `YES` if the asset should be enabled or `NO` if it should not.
 *
 */
- (BOOL)mediaPickerController:(WPMediaPickerViewController *)picker shouldEnableAsset:(id<WPMediaAsset>)asset;

/**
 *  @name Managing the Selected Assets
 */

/**
 *  Asks the delegate if the specified asset should be selected.
 *
 *  @param picker The controller object managing the assets picker interface.
 *  @param asset  The asset to be selected.
 *
 *  @return `YES` if the asset should be selected or `NO` if it should not.
 *
 */
- (BOOL)mediaPickerController:(WPMediaPickerViewController *)picker shouldSelectAsset:(id<WPMediaAsset>)asset;

/**
 *  Tells the delegate that the asset was selected.
 *
 *  @param picker The controller object managing the assets picker interface.
 *  @param asset  The asset that was selected.
 *
 */
- (void)mediaPickerController:(WPMediaPickerViewController *)picker didSelectAsset:(id<WPMediaAsset>)asset;

/**
 *  Asks the delegate if the specified asset should be deselected.
 *
 *  @param picker The controller object managing the assets picker interface.
 *  @param asset  The asset to be deselected.
 *
 *  @return `YES` if the asset should be deselected or `NO` if it should not.
 *
 *  @see assetsPickerController:shouldSelectAsset:
 */
- (BOOL)mediaPickerController:(WPMediaPickerViewController *)picker shouldDeselectAsset:(id<WPMediaAsset>)asset;

/**
 *  Tells the delegate that the item at the specified path was deselected.
 *
 *  @param picker The controller object managing the assets picker interface.
 *  @param asset  The asset that was deselected.
 *
 */
- (void)mediaPickerController:(WPMediaPickerViewController *)picker didDeselectAsset:(id<WPMediaAsset>)asset;

@end