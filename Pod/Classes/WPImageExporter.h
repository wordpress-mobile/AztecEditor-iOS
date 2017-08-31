#import <Foundation/Foundation.h>

@interface WPImageExporter : NSObject

+ (BOOL)writeImage:(UIImage *)image metadata:(NSDictionary *)metadata toURL:(NSURL *)url;

+ (NSURL *)URLForTemporaryFileWithFileExtension:(NSString *)fileExtension;

@end
