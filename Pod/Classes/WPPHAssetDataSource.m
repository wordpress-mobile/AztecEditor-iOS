#import "WPPHAssetDataSource.h"
#import "WPIndexMove.h"
@import Photos;

@interface WPPHAssetDataSource() <PHPhotoLibraryChangeObserver>

@property (nonatomic, strong) PHAssetCollection *activeAssetsCollection;
@property (nonatomic, strong) PHFetchResult *assetsCollections;
@property (nonatomic, strong) PHFetchResult *assets;
@property (nonatomic, strong) PHFetchResult *albums;
@property (nonatomic, strong) NSMutableArray<PHAssetCollectionForWPMediaGroup *> *cachedCollections;
@property (nonatomic, assign) WPMediaType mediaTypeFilter;
@property (nonatomic, strong) NSMutableDictionary *observers;
@property (nonatomic, assign) BOOL refreshGroups;
@property (nonatomic, assign) BOOL ascendingOrdering;

@end

@implementation WPPHAssetDataSource

+ (instancetype)sharedInstance
{
    static WPPHAssetDataSource *assetSource = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        assetSource = [[WPPHAssetDataSource alloc] init];
    });
    return assetSource;
}


- (instancetype)init
{
    self = [super init];
    if (!self) {
        return nil;
    }
    _mediaTypeFilter = WPMediaTypeVideoOrImage;
    _observers = [[NSMutableDictionary alloc] init];
    _refreshGroups = YES;
    _cachedCollections = [[NSMutableArray alloc] init];
    [[PHPhotoLibrary sharedPhotoLibrary] registerChangeObserver:self];
    return self;
}

- (void)dealloc
{
    [[PHPhotoLibrary sharedPhotoLibrary] unregisterChangeObserver:self];
}

+ (PHCachingImageManager *) sharedImageManager
{
    static PHCachingImageManager *_sharedImageManager = nil;
    static dispatch_once_t _onceToken;
    dispatch_once(&_onceToken, ^{
        _sharedImageManager = [[PHCachingImageManager alloc] init];
        [_sharedImageManager setAllowsCachingHighQualityImages:NO];
    });
    
    return _sharedImageManager;
}

- (void)photoLibraryDidChange:(PHChange *)changeInstance
{
    dispatch_async(dispatch_get_main_queue(), ^{
        PHFetchResultChangeDetails *groupChangeDetails = [changeInstance changeDetailsForFetchResult:self.assetsCollections];
        PHFetchResultChangeDetails *assetsChangeDetails = [changeInstance changeDetailsForFetchResult:self.assets];
        PHFetchResultChangeDetails *albumChangeDetails = [changeInstance changeDetailsForFetchResult:self.albums];

        if (!groupChangeDetails && !assetsChangeDetails && !albumChangeDetails) {
            return;
        }

        [self loadGroupsWithSuccess:nil failure:nil];
        
        BOOL incrementalChanges = assetsChangeDetails.hasIncrementalChanges;
        // Capture removed, changed, and moved indexes before fetching results for incremental chaanges.
        // The adjustedIndex depends on the *old* asset count.
        NSIndexSet *removedIndexes = [self adjustedIndexesForIndexSet:assetsChangeDetails.removedIndexes];
        NSIndexSet *changedIndexes = [self adjustedIndexesForIndexSet:assetsChangeDetails.changedIndexes];
        NSMutableArray *moves = [NSMutableArray array];
        if  (assetsChangeDetails.hasMoves) {
            [assetsChangeDetails enumerateMovesWithBlock:^(NSUInteger fromIndex, NSUInteger toIndex) {
                NSInteger fromIdx = [self adjustedIndexForIndex:fromIndex];
                NSInteger toIdx = [self adjustedIndexForIndex:toIndex];
                [moves addObject:[[WPIndexMove alloc] init:fromIdx to:toIdx]];
            }];
        }
        if (incrementalChanges) {
            self.assets = assetsChangeDetails.fetchResultAfterChanges;
        }
        // Capture inserted indexes *after* fetching results after changes.
        // The adjustedIndex depends on the *new* asset count.
        NSIndexSet *insertedIndexes = [self adjustedIndexesForIndexSet:assetsChangeDetails.insertedIndexes];

        [self.observers enumerateKeysAndObjectsUsingBlock:^(NSUUID *key, WPMediaChangesBlock block, BOOL *stop) {
            block(incrementalChanges, removedIndexes, insertedIndexes, changedIndexes, moves);
        }];
    });
}

- (void)loadDataWithSuccess:(WPMediaSuccessBlock)successBlock
                    failure:(WPMediaFailureBlock)failureBlock
{
    [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
        if ([PHPhotoLibrary authorizationStatus] == PHAuthorizationStatusDenied ||
            [PHPhotoLibrary authorizationStatus] == PHAuthorizationStatusRestricted) {
            if (failureBlock) {
                NSError *error = [NSError errorWithDomain:WPMediaPickerErrorDomain code:WPMediaErrorCodePermissionsFailed userInfo:nil];
                failureBlock(error);
            }
            return;
        }
        if (self.refreshGroups) {
            [[[self class] sharedImageManager] stopCachingImagesForAllAssets];
            [self loadGroupsWithSuccess:^{
                self.refreshGroups = NO;
                [self loadAssetsWithSuccess:successBlock failure:failureBlock];
            } failure:failureBlock];
        } else {
            [self loadAssetsWithSuccess:successBlock failure:failureBlock];
        }
    }];
}

- (NSArray *)smartAlbumsToShow {
    NSMutableArray *smartAlbumsOrder = [NSMutableArray arrayWithArray:@[
                                                                        @(PHAssetCollectionSubtypeSmartAlbumUserLibrary),
                                                                        @(PHAssetCollectionSubtypeSmartAlbumRecentlyAdded),
                                                                        @(PHAssetCollectionSubtypeSmartAlbumFavorites),
                                                                        @(PHAssetCollectionSubtypeSmartAlbumPanoramas),
                                                                        @(PHAssetCollectionSubtypeSmartAlbumVideos),
                                                                        @(PHAssetCollectionSubtypeSmartAlbumSlomoVideos),
                                                                        @(PHAssetCollectionSubtypeSmartAlbumTimelapses),
                                                                        ]];
    // Add iOS 9's new albums
    NSOperatingSystemVersion iOS9 = {9,0,0};
    if ( [[NSProcessInfo processInfo] isOperatingSystemAtLeastVersion:iOS9]) {
        [smartAlbumsOrder insertObject:@(PHAssetCollectionSubtypeSmartAlbumSelfPortraits) atIndex:3];
        [smartAlbumsOrder addObject:@(PHAssetCollectionSubtypeSmartAlbumScreenshots)];
    }
    return [NSArray arrayWithArray:smartAlbumsOrder];
}

- (void)loadGroupsWithSuccess:(WPMediaSuccessBlock)successBlock
                      failure:(WPMediaFailureBlock)failureBlock
{
    PHFetchOptions *fetchOptions = [PHFetchOptions new];
    fetchOptions.predicate = [[self class] predicateForFilterMediaType:self.mediaTypeFilter];
    NSMutableArray *collectionsArray=[NSMutableArray array];
    for (NSNumber *subType in [self smartAlbumsToShow]) {
        PHFetchResult * smartAlbum = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeSmartAlbum
                                                                           subtype:[subType intValue]
                                                                           options:nil];
        PHAssetCollection *collection = (PHAssetCollection *)smartAlbum.firstObject;
        if ([PHAsset fetchAssetsInAssetCollection:collection options:fetchOptions].count > 0 || [subType intValue] == PHAssetCollectionSubtypeSmartAlbumUserLibrary){
            [collectionsArray addObjectsFromArray:[smartAlbum objectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, smartAlbum.count)]]];
        }
    }
    
    self.albums = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeAlbum
                                                           subtype:PHAssetCollectionSubtypeAny
                                                           options:nil];

    [self.albums enumerateObjectsUsingBlock:^(PHAssetCollection *collection, NSUInteger index, BOOL *stop){
        if ([PHAsset fetchAssetsInAssetCollection:collection options:fetchOptions].count > 0) {
            [collectionsArray addObject:collection];
        }
    }];
    
    PHCollectionList *allAlbums = [PHCollectionList transientCollectionListWithCollections:collectionsArray title:@"Root"];
    self.assetsCollections = [PHAssetCollection fetchCollectionsInCollectionList:allAlbums options:nil];
    [self.cachedCollections removeAllObjects];
    for (PHAssetCollection *assetColletion in self.assetsCollections) {
        [self.cachedCollections addObject:[[PHAssetCollectionForWPMediaGroup alloc] initWithCollection:assetColletion mediaType:self.mediaTypeFilter]];
    }
    if (self.assetsCollections.count > 0){
        if (!self.activeAssetsCollection || [self.assetsCollections indexOfObject:self.activeAssetsCollection] == NSNotFound) {
            self.activeAssetsCollection = [self.assetsCollections firstObject];
        }
        if (successBlock) {
            successBlock();
        }
    } else {
        if (failureBlock) {
            failureBlock(nil);
        }

    }
}

+ (NSPredicate *)predicateForFilterMediaType:(WPMediaType)mediaType
{
    switch (mediaType) {
        case WPMediaTypeVideoOrImage:
            return [NSPredicate predicateWithFormat:@"(mediaType == %d) || (mediaType == %d)", PHAssetMediaTypeImage, PHAssetMediaTypeVideo];
            break;
        case WPMediaTypeImage:
            return [NSPredicate predicateWithFormat:@"(mediaType == %d)", PHAssetMediaTypeImage];
            break;
        case WPMediaTypeVideo:
            return [NSPredicate predicateWithFormat:@"(mediaType == %d)", PHAssetMediaTypeVideo];
            break;
        case WPMediaTypeAudio:
            return [NSPredicate predicateWithFormat:@"(mediaType == %d)", PHAssetMediaTypeAudio];
            break;
        case WPMediaTypeOther:
            return [NSPredicate predicateWithFormat:@"(mediaType == %d)", PHAssetMediaTypeUnknown];
            break;
        case WPMediaTypeAll:
            return [NSPredicate predicateWithFormat:@"(mediaType == %d) || (mediaType == %d) || (mediaType == %d)", PHAssetMediaTypeImage, PHAssetMediaTypeVideo, PHAssetMediaTypeAudio];
            break;
    }
}

- (void)loadAssetsWithSuccess:(WPMediaSuccessBlock)successBlock
                      failure:(WPMediaFailureBlock)failureBlock
{
    PHFetchOptions *fetchOptions = [PHFetchOptions new];
    fetchOptions.predicate = [[self class] predicateForFilterMediaType:self.mediaTypeFilter];
    // NOTE: Omit specifying fetchOptions.sortDescriptors so the sort order will match the Photos app.
    self.assets = [PHAsset fetchAssetsInAssetCollection:self.activeAssetsCollection options:fetchOptions];
    if (successBlock) {
        successBlock();
    }
}

#pragma mark - WPMediaCollectionDataSource

- (NSInteger)numberOfGroups
{
    return self.cachedCollections.count;
}

- (id<WPMediaGroup>)groupAtIndex:(NSInteger)index
{
    return self.cachedCollections[index];
}

- (id<WPMediaGroup>)selectedGroup
{
    return [[PHAssetCollectionForWPMediaGroup alloc] initWithCollection:self.activeAssetsCollection mediaType:self.mediaTypeFilter];
}

- (void)setSelectedGroup:(id<WPMediaGroup>)group
{
    NSParameterAssert([group isKindOfClass:[PHAssetCollectionForWPMediaGroup class]]);
    self.activeAssetsCollection = [group baseGroup];
}

- (NSInteger)numberOfAssets
{
    return self.assets.count;
}

- (id<WPMediaAsset>)mediaAtIndex:(NSInteger)index
{
    NSInteger count = [self numberOfAssets];
    if (count == 0) {
        return nil;
    }

    NSInteger idx = [self adjustedIndexForIndex:index];
    if (idx < 0 || idx >= count ) {
        return nil;
    }

    return self.assets[idx];
}

- (NSInteger)adjustedIndexForIndex:(NSInteger)index
{
    if (self.ascendingOrdering) {
        return index;
    }

    // Adjust the index so items are returned in reverse order.
    // We do this, rather than specifying the sort order in PHFetchOptions,
    // to preserve the sort order of assets in the Photos app (only in reverse).
    NSInteger count = [self numberOfAssets];
    return (count - 1) - index;
}

- (NSIndexSet *)adjustedIndexesForIndexSet:(NSIndexSet *)indexes
{
    NSMutableIndexSet *adjustedSet = [NSMutableIndexSet new];
    [indexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL * _Nonnull stop) {
        [adjustedSet addIndex:[self adjustedIndexForIndex:idx]];
    }];

    // Returns a non-mutable copy.
    return [[NSIndexSet alloc] initWithIndexSet:adjustedSet];
}

- (id<WPMediaAsset>)mediaWithIdentifier:(NSString *)identifier
{
    PHFetchResult *result = [PHAsset fetchAssetsWithLocalIdentifiers:@[identifier] options:nil];
    PHAsset *asset = (PHAsset *)[result lastObject];
    return asset;
}

- (id<NSObject>)registerChangeObserverBlock:(WPMediaChangesBlock)callback
{
    NSUUID *blockKey = [NSUUID UUID];
    [self.observers setObject:[callback copy] forKey:blockKey];
    return blockKey;
    
}

- (void)unregisterChangeObserver:(id<NSObject>)blockKey
{
    if (blockKey) {
        [self.observers removeObjectForKey:blockKey];
    }
}

- (void)addImage:(UIImage *)image
        metadata:(NSDictionary *)metadata
 completionBlock:(WPMediaAddedBlock)completionBlock
{
    [self addAssetWithChangeRequest:^PHAssetChangeRequest *{
        return [PHAssetChangeRequest creationRequestForAssetFromImage:image];
    } completionBlock:completionBlock];
}

- (void)addVideoFromURL:(NSURL *)url
        completionBlock:(WPMediaAddedBlock)completionBlock
{
    [self addAssetWithChangeRequest:^PHAssetChangeRequest *{
        return [PHAssetChangeRequest creationRequestForAssetFromVideoAtFileURL:url];
    } completionBlock:completionBlock];
}

- (void)addAssetWithChangeRequest:(PHAssetChangeRequest *(^)())changeRequestBlock
        completionBlock:(WPMediaAddedBlock)completionBlock
{
    NSParameterAssert(changeRequestBlock);
    __block NSString * assetIdentifier = nil;
    [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
        // Request creating an asset from the image.
        PHAssetChangeRequest *createAssetRequest = changeRequestBlock();
        PHObjectPlaceholder *assetPlaceholder = [createAssetRequest placeholderForCreatedAsset];
        assetIdentifier = [assetPlaceholder localIdentifier];
        if ([self.activeAssetsCollection canPerformEditOperation:PHCollectionEditOperationAddContent]) {
            // Request editing the album.
            PHAssetCollectionChangeRequest *albumChangeRequest = [PHAssetCollectionChangeRequest changeRequestForAssetCollection:self.activeAssetsCollection];
            [albumChangeRequest addAssets:@[ assetPlaceholder ]];
        }
    } completionHandler:^(BOOL success, NSError *error) {
        if (!success) {
            if (completionBlock){
                dispatch_async(dispatch_get_main_queue(), ^{
                    completionBlock(nil, error);
                });
            }
            return;
        }
        PHFetchOptions *fetchOptions = [[PHFetchOptions alloc] init];
        fetchOptions.predicate = [NSPredicate predicateWithFormat:@"(localIdentifier == %@)", assetIdentifier];
        PHFetchResult * result = [PHAsset fetchAssetsInAssetCollection:self.activeAssetsCollection options:fetchOptions];
        if (result.count < 1){
            if (completionBlock){
                dispatch_async(dispatch_get_main_queue(), ^{
                    completionBlock(nil, error);
                });
            }
            return;
        }
        if (completionBlock) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completionBlock([result firstObject], nil);
            });
        }
    }];
}

- (void)setMediaTypeFilter:(WPMediaType)filter
{
    _mediaTypeFilter = filter;
    //if we change the filter we need to update the groups to reflect the new filter
    _refreshGroups = YES;
}

@end

#pragma mark - WPPHAssetMedia

@implementation PHAsset(WPMediaAsset)


- (WPMediaRequestID)imageWithSize:(CGSize)size completionHandler:(WPMediaImageBlock)completionHandler
{
    PHImageRequestOptions *options = [[PHImageRequestOptions alloc] init];
    options.synchronous = NO;
    options.deliveryMode = PHImageRequestOptionsDeliveryModeOpportunistic;
    options.resizeMode = PHImageRequestOptionsResizeModeFast;
    options.networkAccessAllowed = YES;
    CGSize requestSize = size;
    if (CGSizeEqualToSize(requestSize, CGSizeZero)) {
        requestSize.width = self.pixelWidth;
        requestSize.height = self.pixelHeight;
    }
    return [[WPPHAssetDataSource sharedImageManager] requestImageForAsset:self
                                                        targetSize:requestSize
                                                       contentMode:PHImageContentModeAspectFill
                                                           options:options
                                                     resultHandler:^(UIImage *result, NSDictionary *info) {
         NSError *error = info[PHImageErrorKey];
         NSNumber *canceled = info[PHImageCancelledKey];
         if (error || canceled){
             if (completionHandler && ![canceled boolValue]){
                 completionHandler(nil, error);
             }
             return;
         }
         if (completionHandler){
             completionHandler(result, nil);
         }
    }];
}

- (void)cancelImageRequest:(WPMediaRequestID)requestID
{
    [[WPPHAssetDataSource sharedImageManager] cancelImageRequest:requestID];
}

/**
 Returns an url that points for the video stream. This is only valid for a MediaAsset of the type.

 @return the url for the video, or nil if the asset is not of video type.
 */
- (WPMediaRequestID)videoAssetWithCompletionHandler:(WPMediaAssetBlock)completionHandler
{
    PHVideoRequestOptions *options = [[PHVideoRequestOptions alloc] init];    
    options.networkAccessAllowed = YES;
    options.deliveryMode = PHVideoRequestOptionsDeliveryModeHighQualityFormat;
    return [[WPPHAssetDataSource sharedImageManager] requestAVAssetForVideo:self
                                                                  options:options
                                                            resultHandler:^(AVAsset *result, AVAudioMix *audioMix, NSDictionary *info) {
                                                                NSError *error = info[PHImageErrorKey];
                                                                NSNumber *canceled = info[PHImageCancelledKey];
                                                                if (error || canceled){
                                                                    if (completionHandler && ![canceled boolValue]){
                                                                        completionHandler(nil, error);
                                                                    }
                                                                    return;
                                                                }
                                                                if (completionHandler){
                                                                    completionHandler(result, nil);
                                                                }
                                                            }];
}


- (WPMediaType)assetType
{
    if ([self mediaType] == PHAssetMediaTypeVideo){
        return WPMediaTypeVideo;
    } else if ([self mediaType] == PHAssetMediaTypeImage) {
        return WPMediaTypeImage;
    } else if ([self mediaType] == PHAssetMediaTypeAudio) {
        return WPMediaTypeAudio;
    } else if ([self mediaType] == PHAssetMediaTypeUnknown) {
        return WPMediaTypeOther;
    }
    
    return WPMediaTypeOther;
}

- (id)baseAsset
{
    return self;
}

- (NSString *)identifier
{
    return [self localIdentifier];
}

- (NSDate *)date
{
    return [self creationDate];
}

- (CGSize)pixelSize
{
    return CGSizeMake((CGFloat)self.pixelWidth, (CGFloat)self.pixelHeight);
}

- (NSString *)fileExtension
{
    return [[[[PHAssetResource assetResourcesForAsset:self] firstObject] originalFilename] pathExtension];
}

@end

#pragma mark - WPPHAssetCollection

@interface PHAssetCollectionForWPMediaGroup()

@property(nonatomic, strong) PHAssetCollection *collection;
@property(nonatomic) NSUInteger assetCount;
@property(nonatomic, strong) PHAsset *posterAsset;
@property(nonatomic, assign) WPMediaType mediaType;

@end

@implementation PHAssetCollectionForWPMediaGroup

- (instancetype)initWithCollection:(PHAssetCollection *)collection mediaType:(WPMediaType)mediaType
{
    self = [super init];
    if (self) {
        _collection = collection;
        _mediaType = mediaType;

        PHFetchOptions *fetchOptions = [PHFetchOptions new];
        fetchOptions.predicate = [WPPHAssetDataSource predicateForFilterMediaType:_mediaType];
        PHFetchResult *result = [PHAsset fetchKeyAssetsInAssetCollection:_collection options:fetchOptions];
        _posterAsset = [result lastObject];

        _assetCount = [[PHAsset fetchAssetsInAssetCollection:_collection options:fetchOptions] count];

    }
    return self;
}

- (NSString *)name
{
    return [self.collection localizedTitle];
}


- (WPMediaRequestID)imageWithSize:(CGSize)size completionHandler:(WPMediaImageBlock)completionHandler
{
    return [self.posterAsset imageWithSize:size completionHandler:completionHandler];
}

- (void)cancelImageRequest:(WPMediaRequestID)requestID
{
    [self.posterAsset cancelImageRequest:requestID];
}

- (id)baseGroup
{
    return self.collection;
}

- (NSString *)identifier
{
    return [self.collection localIdentifier];
}

- (NSInteger)numberOfAssetsOfType:(WPMediaType)mediaType
{
    NSInteger count = self.collection.estimatedAssetCount;
    if (count != NSNotFound) {
        return count;
    }

    return self.assetCount;
}

@end
