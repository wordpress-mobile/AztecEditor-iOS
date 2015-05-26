#import "WPALAssetDataSource.h"

@interface WPALAssetDataSource  ()

@property (nonatomic, strong) ALAssetsGroup *assetsGroup;
@property (nonatomic, strong) NSMutableArray *groups;
@property (nonatomic, strong) NSMutableArray *assets;
@property (nonatomic, assign) BOOL ignoreMediaNotifications;
@property (nonatomic, assign) WPMediaType filter;
@property (nonatomic, strong) ALAssetsFilter *assetsFilter;
@property (nonatomic, strong) NSMutableDictionary *observers;
@property (nonatomic, assign) BOOL refreshGroups;

@end

@implementation WPALAssetDataSource

- (instancetype)init
{
    self = [super init];
    if (!self) {
        return nil;
    }
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleLibraryNotification:)
                                                 name:ALAssetsLibraryChangedNotification
                                               object:self.assetsLibrary];
    _groups = [[NSMutableArray alloc] init];
    _assets = [[NSMutableArray alloc] init];
    _filter = WPMediaTypeAll;
    _assetsFilter = [ALAssetsFilter allAssets];
    _observers = [[NSMutableDictionary alloc] init];
    _refreshGroups = YES;
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)handleLibraryNotification:(NSNotification *)note
{
    if (![self shouldNotifyObservers:note]) {
        return;
    }
    if (self.ignoreMediaNotifications) {
        return;
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
    if (!note.userInfo ||
        note.userInfo[ALAssetLibraryUpdatedAssetGroupsKey] ||
        [note.userInfo[ALAssetLibraryInsertedAssetGroupsKey] count] > 0 ||
        [note.userInfo[ALAssetLibraryDeletedAssetGroupsKey] count] > 0
        )
    {
        self.refreshGroups = YES;
        return YES;
    }

    NSURL *currentGroupID = [self.assetsGroup valueForProperty:ALAssetsGroupPropertyURL];
    NSSet *groupsChanged = note.userInfo[ALAssetLibraryUpdatedAssetGroupsKey];
    NSSet *assetsChanged = note.userInfo[ALAssetLibraryUpdatedAssetsKey];
    if (  groupsChanged && [groupsChanged containsObject:currentGroupID]
        && assetsChanged.count > 0
        ) {
        return YES;
    }
    
    return NO;
}

- (ALAssetsLibrary *)assetsLibrary
{
    static dispatch_once_t onceToken;
    static ALAssetsLibrary *_assetsLibrary;
    dispatch_once(&onceToken, ^{
        _assetsLibrary = [[ALAssetsLibrary alloc] init];
    });
    return _assetsLibrary;
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
    [self.groups removeAllObjects];
    [self.assetsLibrary enumerateGroupsWithTypes:ALAssetsGroupAll usingBlock:^(ALAssetsGroup *group, BOOL *stop) {
        if(!group){
            if (successBlock) {
                successBlock();
            }
            return;
        }
        [self.groups addObject:group];
        if (!self.assetsGroup){
            if ([[group valueForProperty:ALAssetsGroupPropertyType] intValue] == ALAssetsGroupSavedPhotos){
                self.assetsGroup = group;
            }
        }
    } failureBlock:^(NSError *error) {
        NSLog(@"Error: %@", [error localizedDescription]);
        if (failureBlock) {
            failureBlock(error);
        }
    }];
}

- (void)loadAssetsWithSuccess:(WPMediaChangesBlock)successBlock
                      failure:(WPMediaFailureBlock)failureBlock
{

    [self.assets removeAllObjects];
    [self.assetsGroup setAssetsFilter:self.assetsFilter];
    ALAssetsGroupEnumerationResultsBlock assetEnumerationBlock = ^(ALAsset *asset, NSUInteger index, BOOL *stop) {
        if (asset){
            [self.assets addObject:asset];
        } else {
            if (successBlock) {
                successBlock();
            }
        }
    };
    [self.assetsGroup enumerateAssetsWithOptions: 0
                                      usingBlock:assetEnumerationBlock];
}

#pragma mark - WPMediaCollectionDataSource

- (NSInteger)numberOfGroups
{
    return self.groups.count;
}

- (id<WPMediaGroup>)groupAtIndex:(NSInteger)index
{
   return self.groups[index];
}

- (id<WPMediaGroup>)selectedGroup
{
    return self.assetsGroup;
}

- (void)setSelectedGroup:(id<WPMediaGroup>)group
{
    NSParameterAssert([group isKindOfClass:[ALAssetsGroup class]]);
    self.assetsGroup = [group baseGroup];
}

- (NSInteger)indexOfSelectedGroup
{
    for (int i = 0; i < self.groups.count; i++) {
        ALAssetsGroup *group = (ALAssetsGroup *)self.groups[i];
        NSURL *loopGroupURL = [group valueForProperty:ALAssetsGroupPropertyURL];
        if ([loopGroupURL isEqual:[self.assetsGroup valueForProperty:ALAssetsGroupPropertyURL]]) {
            return i;
        }
    }
    return NSNotFound;
}

- (NSInteger)numberOfAssets
{
    return self.assets.count;
}

- (id<WPMediaAsset>)mediaAtIndex:(NSInteger)index
{
    return self.assets[index];
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
    self.ignoreMediaNotifications = YES;
    [self.assetsLibrary writeImageToSavedPhotosAlbum:[image CGImage]
                                            metadata:metadata
                                     completionBlock:^(NSURL *assetURL, NSError *error)
    {
        [self addMediaFromAssetURL:assetURL error:error completionBlock:completionBlock];
    }];
}

- (void)addVideoFromURL:(NSURL *)url
        completionBlock:(WPMediaAddedBlock)completionBlock
{
    self.ignoreMediaNotifications = YES;
    [self.assetsLibrary writeVideoAtPathToSavedPhotosAlbum:url
                                           completionBlock:^(NSURL *assetURL, NSError *error)
    {
        [self addMediaFromAssetURL:assetURL error:error completionBlock:completionBlock];
    }];
}

-(void)addMediaFromAssetURL:(NSURL *)assetURL
                      error:(NSError *)error
            completionBlock:(WPMediaAddedBlock)completionBlock
{
    if (error){
        self.ignoreMediaNotifications = NO;
        if (completionBlock){
            completionBlock(nil, error);
        }
        return;
    }
    [self.assetsLibrary assetForURL:assetURL resultBlock:^(ALAsset *asset) {
        [self.assets addObject:asset];
        if ([self.assetsGroup isEditable]) {
            [self.assetsGroup addAsset:asset];
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            if (completionBlock) {
                completionBlock(asset, nil);
            }
            self.ignoreMediaNotifications = NO;
        });
    } failureBlock:^(NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (completionBlock) {
                completionBlock(nil, error);
            }
            self.ignoreMediaNotifications = NO;
        });
    }];
}

- (void) setMediaTypeFilter:(WPMediaType)filter
{
    self.filter = filter;
    switch (self.filter) {
        case WPMediaTypeAll:
            self.assetsFilter = [ALAssetsFilter allAssets];
            break;
        case WPMediaTypeImage:
            self.assetsFilter = [ALAssetsFilter allPhotos];
            break;
        case WPMediaTypeVideo:
            self.assetsFilter = [ALAssetsFilter allVideos];
            break;
        default:
            self.assetsFilter = [ALAssetsFilter allAssets];
            break;
    }}

- (WPMediaType)mediaTypeFilter
{
    return self.filter;
}

@end

#pragma mark - WPALAssetMedia

@implementation ALAsset(WPMediaAsset)

- (WPMediaRequestID)imageWithSize:(CGSize)size completionHandler:(WPMediaImageBlock)completionHandler;
{
    CGImageRef thumbnailImageRef = [self thumbnail];
    UIImage *result = [UIImage imageWithCGImage:thumbnailImageRef];
    if (result.size.width < size.width && result.size.height < size.height) {
        result = [UIImage imageWithCGImage:[self.defaultRepresentation fullResolutionImage]];
    }
    if (completionHandler){
        if (result) {
            completionHandler(result, nil);
        } else {
            completionHandler(nil, nil);
        }
    }
    return 0;
}

- (void)cancelImageRequest:(WPMediaRequestID)requestID
{
    //This implementation doens't actually makes work async so nothing to cancel here.
}

- (WPMediaType)assetType
{
    if ([self valueForProperty:ALAssetPropertyType] == ALAssetTypeVideo){
        return WPMediaTypeVideo;
    } else if ([self valueForProperty:ALAssetPropertyType] == ALAssetTypePhoto) {
        return WPMediaTypeImage;
    } else if ([self valueForProperty:ALAssetPropertyType] == ALAssetTypeUnknown) {
        return WPMediaTypeOther;
    }
    
    return WPMediaTypeOther;
}

- (NSTimeInterval)duration
{
    NSTimeInterval duration = 0;
    if ([self valueForProperty:ALAssetPropertyType] == ALAssetTypeVideo) {
        duration = [[self valueForProperty:ALAssetPropertyDuration] doubleValue];
    }
    return duration;
}

- (id)baseAsset
{
    return self;
}

- (NSString *)identifier
{
    return [[self valueForProperty:ALAssetPropertyAssetURL] absoluteString];
}

- (NSDate *)date
{
    return [self valueForProperty:ALAssetPropertyDate];
}

@end

#pragma mark - WPALAssetGroup

@implementation ALAssetsGroup(WPALAssetGroup)

- (NSString *)name
{
    return [self valueForProperty:ALAssetsGroupPropertyName];
}

- (WPMediaRequestID)imageWithSize:(CGSize)size completionHandler:(WPMediaImageBlock)completionHandler;
{
    UIImage *result = [UIImage imageWithCGImage:[self posterImage]];
    if (completionHandler){
        if (result) {
            completionHandler(result, nil);
        } else {
            completionHandler(nil, nil);
        }
    }
    return 0;
}

- (void)cancelImageRequest:(WPMediaRequestID)requestID
{
    //This implementation doens't actually makes work async so nothing to cancel here.
}

- (id)baseGroup
{
    return self;
}

- (NSString *)identifier
{
    return [[self valueForProperty:ALAssetsGroupPropertyURL] absoluteString];
}

@end

