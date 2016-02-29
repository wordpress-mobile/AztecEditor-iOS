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

    self.backgroundColor = [UIColor blackColor];
    _sessionQueue = dispatch_queue_create("org.wordpress.WPMediaCapturePreviewCollectionView", DISPATCH_QUEUE_SERIAL);
    _previewView = [[UIView alloc] initWithFrame:self.bounds];
    _previewView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self addSubview:_previewView];
    
    UIImage *cameraImage = [WPMediaPickerResources imageNamed:@"camera" withExtension:@"png"];
    UIImageView *imageView = [[UIImageView alloc] initWithImage:cameraImage];
    imageView.center = CGPointMake(CGRectGetWidth(self.frame) / 2.0, CGRectGetHeight(self.frame) / 2.0);
    imageView.contentMode = UIViewContentModeScaleAspectFill;
    imageView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
    [self addSubview:imageView];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.captureVideoPreviewLayer.frame = self.previewView.bounds;
}

- (void)stopCaptureOnCompletion:(void (^)(void))block
{
    if (!self.session) {
        dispatch_async(dispatch_get_main_queue(), block);
        return;
    }
    self.captureVideoPreviewLayer.connection.enabled = NO;
    dispatch_async(self.sessionQueue, ^{
        if ([self.session isRunning]){
            [self.session stopRunning];
        }
        dispatch_async(dispatch_get_main_queue(), block);
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
            self.session.sessionPreset = AVCaptureSessionPreset1280x720;
            
            AVCaptureDevice *device =
            [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
            
            NSError *error = nil;
            AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:device error:&error];
            if (input) {
                [self.session addInput:input];
            } else {
                NSLog(@"Error: %@", error);
                return;
            }
        }
        if (!self.session.isRunning){
            [self.session startRunning];
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.captureVideoPreviewLayer removeFromSuperlayer];
                CALayer *viewLayer = self.previewView.layer;
                self.captureVideoPreviewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.session];
                self.captureVideoPreviewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
                self.captureVideoPreviewLayer.frame = viewLayer.bounds;
                [viewLayer addSublayer:_captureVideoPreviewLayer];
            });
        }
    });
}

- (void)deviceOrientationDidChange:(NSNotification *)notification
{
    if (self.captureVideoPreviewLayer.connection.supportsVideoOrientation) {
        self.captureVideoPreviewLayer.connection.videoOrientation = (AVCaptureVideoOrientation)[[UIApplication sharedApplication] statusBarOrientation];
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

@end
