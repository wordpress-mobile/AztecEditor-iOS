typedef NS_ENUM(NSInteger, WPMediaType){
    WPMediaTypeImage,
    WPMediaTypeVideo,
    WPMediaTypeOther,
    WPMediaTypeAll
};

static NSString * const WPMediaPickerErrorDomain = @"WPMediaPickerErrorDomain";

typedef NS_ENUM(NSInteger, WPMediaPickerErrorCode){
    WPMediaErrorCodePermissionsFailed,
    WPMediaErrorCodePermissionsUnknow
};

@protocol WPMediaAsset;

typedef void (^WPMediaChangesBlock)();
typedef void (^WPMediaFailureBlock)(NSError *error);
typedef void (^WPMediaAddedBlock)(id<WPMediaAsset> media, NSError *error);
typedef void (^WPMediaImageBlock)(UIImage *result, NSError *error);
typedef int32_t WPMediaRequestID;


/**
 * The WPMediaGroup protocol is adopted by an object that mediates between a media collection and it's representation on
 * an visualization like WPMediaGroupPickerViewController.
 */
@protocol WPMediaGroup <NSObject>

- (NSString *)name;

/**
 *  Assynchronously fetches an image that represents the group
 *
 *  @param size, the target size for the image, this may not be respected if the requested size is not available
 *
 *  @param completionHandler, a block that is invoked when the image is available or when an error occurs.
 *
 *  @return an unique ID of the fecth operation
 */
- (WPMediaRequestID)imageWithSize:(CGSize)size completionHandler:(WPMediaImageBlock)completionHandler;

- (void)cancelImageRequest:(WPMediaRequestID)requestID;

/**
 *  The original object that represents a group on the underlying media implementation
 *
 *  @return a object from the underlying media implementation
 */
- (id)baseGroup;

/**
 *  An unique identifer for the media group
 *
 *  @return a string that uniquely identifies the group
 */
- (NSString *)identifier;

/**
 *  The numbers of assets that exist in the group
 *
 *  @return The numbers of assets that exist in the group
 */
- (NSInteger)numberOfAssets;

@end

/**
 * The WPMediaAsset protocol is adopted by an object that mediates between a concrete media asset and it's representation on 
 * a WPMediaCollectionViewCell.
 */
@protocol WPMediaAsset <NSObject>

/**
 *  Assynchronously fetches an image that represents the asset with the requested size
 *
 *  @param size, the target size for the image, this may not be respected if the requested size is not available
 *
 *  @param completionHandler, a block that is invoked when the image is available or when an error occurs.
 *
 *  @return an unique ID of the fecth operation that can be used to cancel it.
 */
- (WPMediaRequestID)imageWithSize:(CGSize)size completionHandler:(WPMediaImageBlock)completionHandler;

/**
 *  Cancels a previous ongoing request for an asset image
 *
 *  @param requestID an identifier returned by the imageWithSize:completionHandler: method.
 */
- (void)cancelImageRequest:(WPMediaRequestID)requestID;

/**
 *  The media type of the asset. This could be an image, video, or another unknow type.
 *
 *  @return a WPMEdiaType object.
 */
- (WPMediaType)assetType;

/**
 *  The duration of a video media asset. The is only available on video assets.
 *
 *  @return The duration of a video asset. Always zero if the asset is not a video.
 */
- (NSTimeInterval)duration;

/**
 *  The original object that represents an asset on the underlying media implementation
 *
 *  @return a object from the underlying media implementation
 */
- (id)baseAsset;

/**
 *  A unique identifier for the media asset
 *
 *  @return a string that uniquely identifies the media asset
 */
- (NSString *)identifier;

/**
 *  The date when the asset was created.
 *
 *  @return  a NSDate object that represents the creation date of the asset.
 */
- (NSDate *)date;

@end

/**
 *  The WPMediaCollectionDataSource protocol is adopted by an object that mediates between a media library implementation
 * and a WPMediaPickerViewController / WPMediaCollectionViewController. The data source provides information about the media groups
 * that exist and the media assets inside. It also provides methods to add new media assets to the library and observe changes that
 * happen outside it's interface.
 */
@protocol WPMediaCollectionDataSource <NSObject>

/**
 *  Asks the data source for the number of groups existing on the media library.
 *
 *  @return the number of groups existing on the media library.
 */
- (NSInteger)numberOfGroups;

/**
 *  Asks the data source for the group at a selected index.
 *
 *  @param an index location the group requested.
 *
 *  @return an object implementing WPMediaGroup protocol.
 */
- (id<WPMediaGroup>)groupAtIndex:(NSInteger)index;

/**
 *  Ask the data source for the current active group of the library
 *
 *  @return an object implementing WPMediaGroup protocol.
 */
- (id<WPMediaGroup>)selectedGroup;

/**
 *  Ask the data source to select a specific group and update it's assets for that group.
 *
 *  @param an object implementing the WPMediaGroup protocol
 */
- (void)setSelectedGroup:(id<WPMediaGroup>)group;

/**
 *  Asks the data source for the number of assets existing on the currect selected group
 *
 *  @return the number of assets existing on the current selected group.
 */
- (NSInteger)numberOfAssets;

/**
 *  Asks the data source for the asset at the selected index.
 *
 *  @param an index location of the asset requested.
 *
 *  @return an object implementing the WPMediaAsset protocol
 */
- (id<WPMediaAsset>)mediaAtIndex:(NSInteger)index;

/**
 *  Returns the object with the matching identifier if it exists on the datasource
 *
 *  @param identifier a unique identifier for the media
 *
 *  @return the media object if it exists or nil if it's not found.
 */
- (id<WPMediaAsset>)mediaWithIdentifier:(NSString *)identifier;

/**
 *  Asks the data source to be notify about changes on the media library using the given callback block.
 *
 *  @discussion the callback object is retained by the data source so it needs to 
 * be unregistered on the end to avoid leaks or retain cycles.
 *
 *  @param callback a WPMediaChangesBlock that is invoked every time a change is detected.
 *
 *  @return an opaque object that identifies the callback register. This should be used to later unregister the block
 */
- (id<NSObject>)registerChangeObserverBlock:(WPMediaChangesBlock)callback;

/**
 *  Asks the data source to unregister the block that is identified by the block key.
 *
 *  @param blockKey the unique identifier of the block. This must have been obtained 
 * by a call to registerChangesObserverBlock
 */
- (void)unregisterChangeObserver:(id<NSObject>)blockKey;

/**
 *  Asks the data source to reload the data available of the media library. This should be invoked after changing the 
 *  current active group or if a change is detected.
 *
 *  @param successBlock a block that is invoked when the data is loaded with success.
 *  @param failureBlock a block that is invoked when the are is any kind of error when loading the data.
 */
- (void)loadDataWithSuccess:(WPMediaChangesBlock)successBlock
                    failure:(WPMediaFailureBlock)failureBlock;

/**
 *  Requests to the data source to add an image to the library.
 *
 *  @param image           an UIImage object with the asset to add
 *  @param metadata        the metadata information of the image to add.
 *  @param completionBlock a block that is invoked when the image is added. 
 * On success the media parameter is returned with a new object implemeting the WPMedia protocol
 * If an error occurs the media is nil and the error parameter contains a value
 */
- (void)addImage:(UIImage *)image metadata:(NSDictionary *)metadata completionBlock:(WPMediaAddedBlock)completionBlock;

/**
 *  Requests to the data source to add a video to the library.
 *
 *  @param url             an url pointing to a file that contains the video to be added to the library.
 *  @param completionBlock  a block that is invoked when the image is added.
 * On success the media parameter is returned with a new object implemeting the WPMedia protocol
 * If an error occurs the media is nil and the error parameter contains a value
 */
- (void)addVideoFromURL:(NSURL *)url  completionBlock:(WPMediaAddedBlock)completionBlock;

/**
 *  Filter the assets acording to their media type.
 *
 *  @param filter the WMMediaType to filter objects to. The default value is WPMediaTypeAll
 */
- (void)setMediaTypeFilter:(WPMediaType)filter;

/**
 *
 *
 *  @return The media type filter that is being used.
 */
- (WPMediaType)mediaTypeFilter;

@end

