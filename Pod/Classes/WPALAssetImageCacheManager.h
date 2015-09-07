#import <Foundation/Foundation.h>

@import AssetsLibrary;

@interface WPALAssetImageCacheManager : NSObject

+ (instancetype)sharedInstance;

- (NSUInteger)requestImageForAsset:(ALAsset *)asset
                        targetSize:(CGSize)targetSize
                             scale:(CGFloat)scale
                     resultHandler:(void (^)(UIImage *result, NSError *error))resultHandler;

- (void)cancelImageRequest:(NSUInteger)requestID;

@end
