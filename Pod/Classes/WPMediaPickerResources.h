@import Foundation;
@import UIKit;

@interface WPMediaPickerResources : NSObject

+ (NSBundle *)resourceBundle;

+ (UIImage *)imageNamed:(NSString *)imageName withExtension:(NSString *)extension;

@end
