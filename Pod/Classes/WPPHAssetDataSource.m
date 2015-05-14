#import "WPPHAssetDataSource.h"
@import Photos;

@interface WPPHAssetDataSource() <PHPhotoLibraryChangeObserver>

@property (nonatomic, strong) PHAssetCollection *activeAssetsCollection;
@property (nonatomic, strong) PHFetchResult *assetsCollections;
@property (nonatomic, strong) PHFetchResult *assets;
@property (nonatomic, assign) BOOL ignoreMediaNotifications;
@property (nonatomic, assign) WPMediaType mediaTypeFilter;
@property (nonatomic, strong) NSMutableDictionary *observers;
@property (nonatomic, assign) BOOL refreshGroups;

@end

@implementation WPPHAssetDataSource

- (instancetype)init
{
    self = [super init];
    if (!self) {
        return nil;
    }
    _mediaTypeFilter = WPMediaTypeAll;
    _observers = [[NSMutableDictionary alloc] init];
    _refreshGroups = YES;
    [[PHPhotoLibrary sharedPhotoLibrary] registerChangeObserver:self];
    return self;
}

- (void)dealloc
{
    [[PHPhotoLibrary sharedPhotoLibrary] unregisterChangeObserver:self];
}

+ (PHImageManager *) sharedImageManager {
    static id _sharedImageManager = nil;
    static dispatch_once_t _onceToken;
    dispatch_once(&_onceToken, ^{
        _sharedImageManager = [[PHCachingImageManager alloc] init];
    });
    
    return _sharedImageManager;
}

- (void)photoLibraryDidChange:(PHChange *)changeInstance
{
    PHFetchResultChangeDetails *groupChangeDetails = [changeInstance changeDetailsForFetchResult:self.assetsCollections];
    PHFetchResultChangeDetails *assetsChangeDetails = [changeInstance changeDetailsForFetchResult:self.assets];
    
    if (!groupChangeDetails && !assetsChangeDetails) {
        return;
    }
    
    if (groupChangeDetails){
        self.refreshGroups = YES;
    }
    __weak __typeof__(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        [weakSelf loadDataWithSuccess:^{
            [weakSelf.observers enumerateKeysAndObjectsUsingBlock:^(NSUUID *key, WPMediaChangesBlock block, BOOL *stop) {
                block();
            }];
        } failure:nil];
    });

}

- (BOOL)shouldNotifyObservers:(NSNotification *)note
{
    return !self.ignoreMediaNotifications;
}

- (void)loadDataWithSuccess:(WPMediaChangesBlock)successBlock
                    failure:(WPMediaFailureBlock)failureBlock
{
    if (self.refreshGroups) {
        [self loadGroupsWithSuccess:^{
            self.refreshGroups = NO;
            [self loadAssetsWithSuccess:successBlock failure:failureBlock];
        } failure:failureBlock];
    } else {
        [self loadAssetsWithSuccess:successBlock failure:failureBlock];
    }
}

- (void)loadGroupsWithSuccess:(WPMediaChangesBlock)successBlock
                      failure:(WPMediaFailureBlock)failureBlock
{
    NSMutableArray * collectionsArray=[NSMutableArray array];
    PHFetchResult * cameraAlbum = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeSmartAlbum
                                                                           subtype:PHAssetCollectionSubtypeSmartAlbumUserLibrary
                                                                           options:nil];
    PHFetchResult * albums = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeAlbum
                                                                           subtype:PHAssetCollectionSubtypeAny
                                                                           options:nil];
    [collectionsArray addObjectsFromArray:[cameraAlbum objectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, cameraAlbum.count)]]];
    [collectionsArray addObjectsFromArray:[albums objectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, albums.count)]]];
    
    PHCollectionList *allAlbums = [PHCollectionList transientCollectionListWithCollections:collectionsArray title:@"Root"];
    self.assetsCollections = [PHAssetCollection fetchCollectionsInCollectionList:allAlbums options:nil];
    if (self.assetsCollections.count > 0){
        self.activeAssetsCollection = self.assetsCollections[0];
        if (successBlock) {
            successBlock();
        }
    } else {
        if (failureBlock) {
            failureBlock(nil);
        }

    }
}

- (void)loadAssetsWithSuccess:(WPMediaChangesBlock)successBlock
                      failure:(WPMediaFailureBlock)failureBlock
{
    PHFetchOptions *fetchOptions = [PHFetchOptions new];
    if (self.mediaTypeFilter != WPMediaTypeAll) {
        PHAssetMediaType mediaType = PHAssetMediaTypeUnknown;
        if(self.mediaTypeFilter == WPMediaTypeVideo){
            mediaType = PHAssetMediaTypeVideo;
        } else if (self.mediaTypeFilter == WPMediaTypeImage){
            mediaType = PHAssetMediaTypeImage;
        }
        fetchOptions.predicate = [NSPredicate predicateWithFormat:@"(mediaType == %d)", mediaType];
    }
    self.assets = [PHAsset fetchAssetsInAssetCollection:self.activeAssetsCollection options:fetchOptions];
    if (successBlock) {
        successBlock();
    }
}

#pragma mark - WPMediaCollectionDataSource

- (NSInteger)numberOfGroups
{
    return self.assetsCollections.count;
}

- (id<WPMediaGroup>)groupAtIndex:(NSInteger)index
{
    return [[WPPHAssetCollection alloc] initWithAssetCollection:self.assetsCollections[index]];
}

- (id<WPMediaGroup>)selectedGroup
{
    return [[WPPHAssetCollection alloc] initWithAssetCollection:self.activeAssetsCollection];
}

- (void)setSelectedGroup:(id<WPMediaGroup>)group
{
    NSParameterAssert([group isKindOfClass:[WPPHAssetCollection class]]);
    self.activeAssetsCollection = (PHAssetCollection *)[group originalGroup];
}

- (NSInteger)numberOfAssets
{
    return self.assets.count;
}

- (id<WPMediaAsset>)mediaAtIndex:(NSInteger)index
{
    return [[WPPHAssetMedia alloc] initWithAsset:self.assets[index]];
}

- (id<NSObject>)registerChangeObserverBlock:(WPMediaChangesBlock)callback
{
    NSUUID *blockKey = [NSUUID UUID];
    [self.observers setObject:[callback copy] forKey:blockKey];
    return blockKey;
    
}

- (void)unregisterChangeObserver:(id<NSObject>)blockKey
{
    [self.observers removeObjectForKey:blockKey];
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
    self.ignoreMediaNotifications = YES;
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
        self.ignoreMediaNotifications = NO;
        if (!success) {
            if (completionBlock){
                dispatch_async(dispatch_get_main_queue(), ^{
                    completionBlock(nil, error);
                });
            }
            return;
        }
        PHFetchResult * result = [PHAsset fetchAssetsWithLocalIdentifiers:@[assetIdentifier] options:nil];
        if (result.count < 1){
            if (completionBlock){
                dispatch_async(dispatch_get_main_queue(), ^{
                    completionBlock(nil, error);
                });
            }
            return;
        }
        [self loadAssetsWithSuccess:nil failure:nil];
        if (completionBlock) {
            dispatch_async(dispatch_get_main_queue(), ^{
                WPPHAssetMedia *assetMedia = [[WPPHAssetMedia alloc] initWithAsset:result[0]];
                completionBlock(assetMedia, nil);
            });
        }
    }];
}

- (void)setMediaTypeFilter:(WPMediaType)filter
{
    _mediaTypeFilter = filter;
}

@end

#pragma mark - WPPHAssetMedia

@interface WPPHAssetMedia()

@property (nonatomic, strong) PHAsset *asset;

@end

@implementation WPPHAssetMedia

- (instancetype)initWithAsset:(PHAsset *)asset
{
    self = [super init];
    if (!self) {
        return nil;
    }
    _asset = asset;
    return self;
}

- (UIImage *)thumbnailWithSize:(CGSize)size
{
    PHImageRequestOptions *options = [[PHImageRequestOptions alloc] init];
    CGFloat scale = [[UIScreen mainScreen] scale];
    CGSize realSize = CGSizeApplyAffineTransform(size, CGAffineTransformMakeScale(scale, scale));
    options.synchronous = YES;
    options.deliveryMode = PHImageRequestOptionsDeliveryModeOpportunistic;
    __block UIImage *thumbnail = nil;
    [[WPPHAssetDataSource sharedImageManager] requestImageForAsset:self.asset
                                                        targetSize:realSize
                                                       contentMode:PHImageContentModeAspectFill
                                                           options:options
                                                     resultHandler:^(UIImage *result, NSDictionary *info) {
                                                         thumbnail = result;
                                                     }];
    return thumbnail;
}

- (WPMediaType)mediaType
{
    if ([self.asset mediaType] == PHAssetMediaTypeVideo){
        return WPMediaTypeVideo;
    } else if ([self.asset mediaType] == PHAssetMediaTypeImage) {
        return WPMediaTypeImage;
    } else if ([self.asset mediaType] == PHAssetMediaTypeUnknown) {
        return WPMediaTypeOther;
    }
    
    return WPMediaTypeOther;
}

- (NSNumber *)duration
{
    NSNumber * duration = nil;
    if ([self.asset mediaType] == PHAssetMediaTypeVideo) {
        duration = @([self.asset duration]);
    }
    return duration;
}

- (id)originalAsset
{
    return self.asset;
}

- (NSString *)identifier
{
    return [self.asset localIdentifier];
}

- (NSDate *)date
{
    return [self.asset creationDate];
}

@end

#pragma mark - WPPHAssetCollection

@interface WPPHAssetCollection()

@property (nonatomic, strong) PHAssetCollection *assetCollection;

@end

@implementation WPPHAssetCollection

- (instancetype)initWithAssetCollection:(PHAssetCollection *)assetsGroup
{
    self = [super init];
    if (!self){
        return nil;
    }
    _assetCollection = assetsGroup;
    return self;
}

- (NSString *)name
{
    return [self.assetCollection localizedTitle];
}

- (UIImage *)thumbnailWithSize:(CGSize)size
{
    PHAsset * posterAsset = [[PHAsset fetchAssetsInAssetCollection:self.assetCollection options:nil] firstObject];
    WPPHAssetMedia * posterMedia = [[WPPHAssetMedia alloc] initWithAsset:posterAsset];
    return [posterMedia thumbnailWithSize:size];
}

- (id)originalGroup
{
    return self.assetCollection;
}

- (NSString *)identifier
{
    return [self.assetCollection localIdentifier];
}

- (NSInteger)numberOfAssets
{
    NSInteger count = [self.assetCollection estimatedAssetCount];
    if ( count == NSNotFound) {
        count = [[PHAsset fetchAssetsInAssetCollection:self.assetCollection options:nil] count];
    }
    return count;
}

@end
