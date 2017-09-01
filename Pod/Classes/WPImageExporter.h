#import <Foundation/Foundation.h>

/**
 This class implements two helper methods to facilitate export of UIImage to files.
 */
@interface WPImageExporter : NSObject

/**
 Retrieve an URL for a file on the temporary folder using the extension provided

 @param fileExtension the extension to use.
 @return an URL for a temporary file.
 */
+ (NSURL *)temporaryFileURLWithExtension:(NSString *)fileExtension;

/**
 Writes an UIImage with the provided metadata to the designated URL using the JPG format.

 @param image the image to save
 @param metadata the metadata of the image
 @return the URL of the image if it was saved properly.
 */
+ (BOOL)writeImage:(UIImage *)image withMetadata:(NSDictionary *)metadata toURL:(NSURL *)fileURL;

@end
