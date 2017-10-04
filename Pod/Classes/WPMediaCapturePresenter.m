#import "WPMediaCapturePresenter.h"
#import "WPMediaCollectionDataSource.h"

@import MobileCoreServices;
@import AVFoundation;

@interface WPMediaCapturePresenter () <UINavigationControllerDelegate, UIImagePickerControllerDelegate>
@property (nonatomic, strong, nullable) UIViewController *presentingViewController;
@end

@implementation WPMediaCapturePresenter

+ (BOOL)isCaptureAvailable
{
    return [UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera];
}

- (instancetype)initWithPresentingViewController:(UIViewController *)viewController
{
    if (self = [super init]) {
        _presentingViewController = viewController;
    }

    return self;
}

- (void)presentCapture
{
    NSString *avMediaType = AVMediaTypeVideo;
    AVAuthorizationStatus authorizationStatus = [AVCaptureDevice authorizationStatusForMediaType:avMediaType];
    if (authorizationStatus == AVAuthorizationStatusAuthorized) {
        [self presentCaptureViewController];
        return;
    }

    if (authorizationStatus == AVAuthorizationStatusNotDetermined) {
        [AVCaptureDevice requestAccessForMediaType:avMediaType completionHandler:^(BOOL granted) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (!granted)
                {
                    [self presentPermissionAlert];
                    return;
                }
                [self presentCaptureViewController];
            });
        }];
        return;
    }

    dispatch_async(dispatch_get_main_queue(), ^{
        [self presentPermissionAlert];
    });
}

- (void)presentPermissionAlert
{
    NSString *title = NSLocalizedString(@"Media Capture", @"Title for alert when access to media capture is not granted");
    NSString *message =NSLocalizedString(@"This app needs permission to access the Camera to capture new media, please change the privacy settings if you wish to allow this.", @"");
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"OK", "Confirmation of action") style:UIAlertActionStyleCancel handler:nil];
    [alertController addAction:okAction];

    NSString *otherButtonTitle = NSLocalizedString(@"Open Settings", @"Go to the settings app");
    UIAlertAction *otherAction = [UIAlertAction actionWithTitle:otherButtonTitle
                                                          style:UIAlertActionStyleDefault
                                                        handler:^(UIAlertAction *action) {
                                                            NSURL *settingsURL = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
                                                            [[UIApplication sharedApplication] openURL:settingsURL options:@{} completionHandler:nil];
                                                        }];
    [alertController addAction:otherAction];
    
    [self.presentingViewController presentViewController:alertController animated:YES completion:nil];
}

- (void)presentCaptureViewController
{
    UIImagePickerController *imagePickerController = [[UIImagePickerController alloc] init];
    NSMutableSet *mediaTypes = [NSMutableSet setWithArray:[UIImagePickerController availableMediaTypesForSourceType:
                                                           UIImagePickerControllerSourceTypeCamera]];
    NSMutableSet *mediaDesired = [NSMutableSet new];
    if (self.mediaType & WPMediaTypeImage) {
        [mediaDesired addObject:(__bridge NSString *)kUTTypeImage];
    }
    if (self.mediaType & WPMediaTypeVideo) {
        [mediaDesired addObject:(__bridge NSString *)kUTTypeMovie];

    }
    if (mediaDesired.count > 0){
        [mediaTypes intersectSet:mediaDesired];
    }

    imagePickerController.mediaTypes = [mediaTypes allObjects];
    imagePickerController.delegate = self;
    imagePickerController.sourceType = UIImagePickerControllerSourceTypeCamera;
    imagePickerController.cameraDevice = [self cameraDevice];
    imagePickerController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    imagePickerController.videoQuality = UIImagePickerControllerQualityTypeHigh;
    [self.presentingViewController presentViewController:imagePickerController animated:YES completion:nil];
}

- (UIImagePickerControllerCameraDevice)cameraDevice
{
    if (self.preferFrontCamera && [UIImagePickerController isCameraDeviceAvailable:UIImagePickerControllerCameraDeviceFront]) {
        return UIImagePickerControllerCameraDeviceFront;
    } else {
        return UIImagePickerControllerCameraDeviceRear;
    }
}

#pragma mark - UIImagePickerControllerDelegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    [picker dismissViewControllerAnimated:YES completion:^{
        if (self.completionBlock) {
            self.completionBlock(info);
        }
    }];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [picker dismissViewControllerAnimated:YES completion:^{
        if (self.completionBlock) {
            self.completionBlock(nil);
        }
    }];
}

@end
