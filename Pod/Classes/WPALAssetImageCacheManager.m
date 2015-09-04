#import "WPALAssetImageCacheManager.h"
#import "WPMediaCollectionDataSource.h"

@import AVFoundation;
@import ImageIO;

#pragma mark - WPAssetResizeOperation

@interface WPAssetResizeOperation : NSOperation

- (instancetype)initWithAsset:(ALAsset *)asset
                   targetSize:(CGSize)targetSize
                        scale:(CGFloat)scale
              completionBlock:(WPMediaImageBlock)completionBlock;

@property (nonatomic, strong) ALAsset *asset;
@property (nonatomic, assign) CGSize targetSize;
@property (nonatomic, assign) CGFloat scale;
@property (nonatomic, copy) WPMediaImageBlock block;

@end

@implementation WPAssetResizeOperation

- (instancetype)initWithAsset:(ALAsset *)asset
                   targetSize:(CGSize)targetSize
                        scale:(CGFloat)scale
              completionBlock:(WPMediaImageBlock)completionBlock
{
    self = [super init];
    if (self) {
        _asset = asset;
        _targetSize = targetSize;
        _scale = scale;
        _block = [completionBlock copy];
    }
    return self;
}

- (void)main
{
    CGSize realSize = CGSizeApplyAffineTransform(self.targetSize, CGAffineTransformMakeScale(self.scale, self.scale));
    UIImage *result;
    if ([self.asset valueForProperty:ALAssetPropertyType] == ALAssetTypePhoto){
        result = [self resizedImageWithSize:realSize];
    } else {
        result = [UIImage imageWithCGImage:self.asset.thumbnail];
    }
    if (self.block){
        if (result) {
            self.block(result, nil);
        } else {
            self.block(nil, nil);
        }
    }
}

-(UIImage *)resizedImageWithSize:(CGSize)targetSize {
    ALAssetRepresentation *representation = [self.asset defaultRepresentation];
    size_t bufferSize = (size_t)representation.size;
    uint8_t *buffer = malloc(bufferSize);
    if ([representation getBytes:buffer fromOffset:0 length:bufferSize error:nil] == 0){
        free(buffer);
        return nil;
    }
    NSData *data = [NSData dataWithBytesNoCopy:buffer length:bufferSize];
    CGImageSourceRef sourceRef = CGImageSourceCreateWithData((__bridge CFDataRef)data, NULL);
    
    NSDictionary *resizeOptions = @{
                                    (id)kCGImageSourceCreateThumbnailWithTransform : @YES,
                                    (id)kCGImageSourceCreateThumbnailFromImageAlways : @YES,
                                    (id)kCGImageSourceThumbnailMaxPixelSize : @(MAX(targetSize.width, targetSize.height)),
                                    };
    
    CGImageRef resizedImageRef = CGImageSourceCreateThumbnailAtIndex(sourceRef, 0, (__bridge CFDictionaryRef)resizeOptions);
    UIImage *resizedImage = [UIImage imageWithCGImage:resizedImageRef scale:self.scale orientation:UIImageOrientationUp];
    CGImageRelease(resizedImageRef);
    CFRelease(sourceRef);
    return resizedImage;
}

@end

@interface WPALAssetImageCacheManager()

@property (nonatomic, strong) NSOperationQueue *operationQueue;
@property (nonatomic, strong) NSCache *cache;
@property (nonatomic, strong) NSMutableDictionary *runningOperations;

@end

@implementation WPALAssetImageCacheManager

+ (instancetype)sharedInstance {
    static id _sharedInstance = nil;
    static dispatch_once_t _onceToken;
    dispatch_once(&_onceToken, ^{
        _sharedInstance = [[self alloc] init];
    });
    
    return _sharedInstance;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _operationQueue = [[NSOperationQueue alloc] init];
        _operationQueue.maxConcurrentOperationCount = 1;
        _cache = [[NSCache alloc] init];
        _runningOperations = [NSMutableDictionary dictionary];
    }
    return self;
}

- (NSUInteger)requestImageForAsset:(ALAsset *)asset
                        targetSize:(CGSize)targetSize
                             scale:(CGFloat)scale
                     resultHandler:(void (^)(UIImage *result, NSError *error))resultHandler
{
    NSString *identifier = [[asset valueForProperty:ALAssetPropertyAssetURL] absoluteString];
    UIImage *result = [self.cache objectForKey:identifier];
    if (result) {
        if (resultHandler) {
            resultHandler(result, nil);
        }
        return 0;
    }
    NSNumber *operationKey = @(arc4random());
    while (self.runningOperations[operationKey] != nil) {
        operationKey = @(arc4random());
    }
    WPAssetResizeOperation *resizeOperation = [[WPAssetResizeOperation alloc] initWithAsset:asset
                                                                                 targetSize:targetSize
                                                                                      scale:scale
                                                                            completionBlock:^(UIImage *result, NSError *error) {
                                                                                if (result) {
                                                                                    [self.cache setObject:result forKey:identifier];
                                                                                }
                                                                                if (resultHandler) {
                                                                                    resultHandler(result, error);
                                                                                }
                                                                            }];
    self.runningOperations[operationKey] = resizeOperation;
    [resizeOperation setCompletionBlock:^{
        [self.runningOperations removeObjectForKey:operationKey];
    }];
    [self.operationQueue addOperation:resizeOperation];
    
    return [operationKey unsignedIntegerValue];
}

- (void)cancelImageRequest:(NSUInteger)requestID
{
    NSOperation *operation =  (NSOperation *)self.runningOperations[@(requestID)];
    if (operation) {
        [operation cancel];
    }
}

@end
