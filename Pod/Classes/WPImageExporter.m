#import "WPImageExporter.h"

@import MobileCoreServices;
@import ImageIO;


@implementation WPImageExporter

+ (NSURL *)temporaryFileURLWithExtension:(NSString *)fileExtension
{
    NSAssert(fileExtension.length > 0, @"file Extension cannot be empty");
    NSString *fileName = [NSString stringWithFormat:@"%@_file.%@", NSProcessInfo.processInfo.globallyUniqueString, fileExtension];
    NSURL * fileURL = [[NSURL fileURLWithPath: NSTemporaryDirectory()] URLByAppendingPathComponent:fileName];
    return fileURL;
}

+ (BOOL)writeImage:(UIImage *)image withMetadata:(NSDictionary *)metadata toURL:(NSURL *)fileURL;
{
    NSMutableDictionary *properties = [[NSMutableDictionary alloc] initWithDictionary:@{ (NSString *)kCGImageDestinationLossyCompressionQuality: @(1)}];
    CGImageDestinationRef destination = CGImageDestinationCreateWithURL((CFURLRef)fileURL, kUTTypeJPEG, 0.9, nil);
    if (destination == NULL) {
        return NO;
    }
    CGImageRef imageRef = image.CGImage;
    CGImageDestinationSetProperties(destination, (CFDictionaryRef)properties);
    CGImageDestinationAddImage(destination, imageRef, (CFDictionaryRef)metadata);
    BOOL result = CGImageDestinationFinalize(destination);

    CFRelease(destination);
    return result;
}

@end
