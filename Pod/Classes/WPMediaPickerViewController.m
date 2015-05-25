#import "WPMediaPickerViewController.h"
#import "WPMediaCollectionViewController.h"
#import "WPALAssetDataSource.h"
#import "WPPHAssetDataSource.h"

@interface WPMediaPickerViewController () <UINavigationControllerDelegate>

@end

@implementation WPMediaPickerViewController

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        _allowCaptureOfMedia = YES;
        _showMostRecentFirst = NO;
        _allowMultipleSelection = YES;
        _filter = WPMediaTypeAll;
    }

    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Do any additional setup after loading the view.
    [self setupNavigationController];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)setupNavigationController
{
    WPMediaCollectionViewController *vc = [[WPMediaCollectionViewController alloc] init];
    vc.allowCaptureOfMedia = self.allowCaptureOfMedia;
    vc.showMostRecentFirst = self.showMostRecentFirst;
    vc.filter = self.filter;
    vc.allowMultipleSelection = self.allowMultipleSelection;
    if (!self.dataSource) {
        self.dataSource = [self defaulDataSource];
    }
    vc.dataSource = self.dataSource;
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
    nav.delegate = self;

    [nav willMoveToParentViewController:self];
    [nav.view setFrame:self.view.bounds];
    [self.view addSubview:nav.view];
    [self addChildViewController:nav];
    [nav didMoveToParentViewController:self];
}

- (id<WPMediaCollectionDataSource>) defaulDataSource {
    static id<WPMediaCollectionDataSource> assetSource = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        assetSource = [[WPALAssetDataSource alloc] init];
    });
    return assetSource;
}

@end
