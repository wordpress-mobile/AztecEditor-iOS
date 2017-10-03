#import "WPMediaCapturePreviewCollectionView.h"
#import "WPMediaPickerResources.h"
@import AVFoundation;

@interface WPMediaCapturePreviewCollectionView ()

@property (nonatomic, strong) AVCaptureSession *session;
@property (nonatomic, strong) dispatch_queue_t sessionQueue;
@property (nonatomic, strong) UIView *previewView;
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *captureVideoPreviewLayer;

@end

@implementation WPMediaCapturePreviewCollectionView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (void)commonInit
{
    [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deviceOrientationDidChange:) name:UIDeviceOrientationDidChangeNotification object:nil];
    self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.backgroundColor = [UIColor blackColor];
    _sessionQueue = dispatch_queue_create("org.wordpress.WPMediaCapturePreviewCollectionView", DISPATCH_QUEUE_SERIAL);
    _previewView = [[UIView alloc] initWithFrame:self.bounds];
    _previewView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self addSubview:_previewView];
    
    UIImage *cameraImage = [[WPMediaPickerResources imageNamed:@"gridicons-camera-large" withExtension:@"png"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    UIImageView *imageView = [[UIImageView alloc] initWithImage:cameraImage];
    imageView.tintColor = [UIColor whiteColor];
    imageView.center = CGPointMake(CGRectGetWidth(self.frame) / 2.0, CGRectGetHeight(self.frame) / 2.0);
    imageView.contentMode = UIViewContentModeScaleAspectFill;
    imageView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
    [self addSubview:imageView];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.previewView.frame = self.bounds;
    self.captureVideoPreviewLayer.frame = self.previewView.bounds;
}

- (void)stopCaptureOnCompletion:(void (^)(void))block
{
    if (!self.session) {
        if (block) {
            dispatch_async(dispatch_get_main_queue(), block);
        }
        return;
    }

    dispatch_async(self.sessionQueue, ^{
        if ([self.session isRunning]){
            [self.session stopRunning];
            self.session = nil;
            [self.captureVideoPreviewLayer removeFromSuperlayer];
            self.captureVideoPreviewLayer = nil;
        }
        if (block) {
            dispatch_async(dispatch_get_main_queue(), block);
        }
    });
}

- (void)startCapture
{
    dispatch_async(self.sessionQueue, ^{
        AVAuthorizationStatus status = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
        if ( status != AVAuthorizationStatusAuthorized &&
            status != AVAuthorizationStatusNotDetermined)
        {
            return;
        }

        if (!self.session){
            self.session = [[AVCaptureSession alloc] init];
            self.session.sessionPreset = AVCaptureSessionPresetHigh;
            
            AVCaptureDevice *device = [self captureDevice];
            
            NSError *error = nil;
            AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:device error:&error];
            if (input) {
                [self.session addInput:input];
            } else {
                NSLog(@"Error: %@", error);
                return;
            }
        }
        if (!self.session.isRunning ||  !self.captureVideoPreviewLayer.connection.enabled){
            [self.session startRunning];
            if (!self.captureVideoPreviewLayer || !self.captureVideoPreviewLayer.connection.enabled) {
                AVCaptureVideoPreviewLayer * newLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.session];
                dispatch_async(dispatch_get_main_queue(), ^{
                        [self.captureVideoPreviewLayer removeFromSuperlayer];
                        self.captureVideoPreviewLayer = newLayer;
                        CALayer *viewLayer = self.previewView.layer;
                        self.captureVideoPreviewLayer.frame = viewLayer.bounds;
                        self.captureVideoPreviewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
                        self.captureVideoPreviewLayer.connection.videoOrientation = [self videoOrientationForInterfaceOrientation:[[UIApplication sharedApplication] statusBarOrientation]];
                        [viewLayer addSublayer:self.captureVideoPreviewLayer];
                });
            }
        }
    });
}

- (void)deviceOrientationDidChange:(NSNotification *)notification
{
    if (self.captureVideoPreviewLayer.connection.supportsVideoOrientation) {
        self.captureVideoPreviewLayer.connection.videoOrientation = [self videoOrientationForInterfaceOrientation:[[UIApplication sharedApplication] statusBarOrientation]];
    }
}

- (AVCaptureVideoOrientation)videoOrientationForInterfaceOrientation:(UIInterfaceOrientation)orientation
{
    switch (orientation) {
        case UIInterfaceOrientationPortrait:
            return AVCaptureVideoOrientationPortrait;
        case UIInterfaceOrientationPortraitUpsideDown:
            return AVCaptureVideoOrientationPortraitUpsideDown;
        case UIInterfaceOrientationLandscapeLeft:
            return AVCaptureVideoOrientationLandscapeLeft;
        case UIInterfaceOrientationLandscapeRight:
            return AVCaptureVideoOrientationLandscapeRight;
        default:return AVCaptureVideoOrientationPortrait;
    }
}

- (BOOL)isAccessibilityElement
{
    return YES;
}

- (NSString *)accessibilityLabel
{
    return NSLocalizedString(@"Camera", @"Accessibility label for the camera tile in the collection view");
}

- (AVCaptureDevice *)captureDevice
{
    if (self.preferFrontCamera) {
        AVCaptureDevice *device = [[AVCaptureDeviceDiscoverySession discoverySessionWithDeviceTypes:@[AVCaptureDeviceTypeBuiltInWideAngleCamera]
                                                                                          mediaType:AVMediaTypeVideo position:AVCaptureDevicePositionFront].devices firstObject];
            if (device) {
                return device;
            }
    }
    return [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
}

@end
