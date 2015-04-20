#import "WPMediaPickerResources.h"

static NSString *const ResourcesBundleName = @"WPMediaPicker";

@implementation WPMediaPickerResources

+ (NSBundle *)resourceBundle
{
    static NSBundle *_bundle = nil;
    static dispatch_once_t _onceToken;
    dispatch_once(&_onceToken, ^{
        NSString * bundlePath = [[NSBundle mainBundle] pathForResource:ResourcesBundleName ofType:@"bundle"];
        _bundle = [NSBundle bundleWithPath:bundlePath];
    });
    return _bundle;
}

+ (UIImage *)imageNamed:(NSString *)imageName withExtension:(NSString *)extension
{
    NSString *path = [[self resourceBundle] pathForResource:imageName ofType:extension];
    UIImage *image = [UIImage imageWithContentsOfFile:path];

    return image;
}

@end
