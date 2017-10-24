# WPMediaPicker

[![CI Status](https://travis-ci.org/wordpress-mobile/MediaPicker-iOS.svg?style=flat)](https://travis-ci.org/wordpress-mobile/MediaPicker-iOS)
[![Version](https://img.shields.io/cocoapods/v/WPMediaPicker.svg?style=flat)](http://cocoadocs.org/docsets/WPMediaPicker)
[![License](https://img.shields.io/cocoapods/l/WPMediaPicker.svg?style=flat)](http://cocoadocs.org/docsets/WPMediaPicker)
[![Platform](https://img.shields.io/cocoapods/p/WPMediaPicker.svg?style=flat)](http://cocoadocs.org/docsets/WPMediaPicker)

WPMediaPicker is an iOS controller that allows capture and picking of media assets.
It allows:
 * Allows selection of multiple media objects in one go.
 * Capture of new media while inside the picker.
 * Use different data sources for the media library.
 * Switch between different albums.
 * Filtering by media types.
 * Preview of media (images and video) in full screen.
 * Show the media picker inside as a keyboard input view.
 * Super quick and memory optimized.
 * Allow horizontal and vertical scroll of assets.

![Screenshot](screenshots_1.jpg "Screenshot")

## Installation

WPMediaPicker is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

pod "WPMediaPicker"

## Usage

To use the picker do the following:

### Import header

```` objective-c
#import <WPMediaPicker/WPMediaPicker.h>
````

### Create and present the picker in modal mode

```` objective-c
WPNavigationMediaPickerViewController * mediaPicker = [[WPNavigationMediaPickerViewController alloc] init];
mediaPicker.delegate = self;
[self presentViewController:mediaPicker animated:YES completion:nil];
````

### Implement didFinishPickingAssets delegate

The delegate is responsible for dismissing the picker when the operation completes. To dismiss the picker, call the [dismissViewControllerAnimated:completion:](https://developer.apple.com/library/ios/documentation/uikit/reference/UIViewController_Class/index.html#//apple_ref/occ/instm/UIViewController/dismissViewControllerAnimated:completion:) method of the presenting controller responsible for displaying the `WPNavigationMediaPickerController` object. Please refer to the demo app.

```` objective-c
- (void)mediaPickerController:(WPMediaPickerViewController *)picker didFinishPickingAssets:(NSArray<WPMediaAsset> *)assets
{
  [self dismissViewControllerAnimated:YES completion:nil];    
}
````

### Other methods to display the picker

The example above shows the recommended way to show the picker in a modal. There are currently three available controllers to show the picker depending on your application needs:

 * [WPMediaPickerViewController](Pod/Classes/WPMediaPickerViewController.h), this is the base collection view controller that displays the media. It can be used inside another view controllers using containment.
 * [WPInputMediaPickerViewController](Pod/Classes/WPInputMediaPickerViewController.h), a wrapper of the WPMediaPickerController to be used has an inputView of an UIControl. 
 * [WPNavigationMediaPickerViewController](Pod/Classes/WPNavigationMediaPickerViewController.h), a convenience wrapper of the `WPMediaPickerViewController` inside a UINavigationController to show in a modal context.

### How to configure the appearance of the picker

Just use the standard appearance methods from UIKit. Here is an example how to configure the main components

```` objective-c
//Configure navigation bar background color
[[UINavigationBar appearanceWhenContainedInInstancesOfClasses:@[[WPNavigationMediaPickerViewController class]]] setBarTintColor:[UIColor colorWithRed:0/255.0f green:135/255.0f blue:190/255.0f alpha:1.0f]];
//Configure navigation bar items text color
[[UINavigationBar appearanceWhenContainedInInstancesOfClasses:@[[WPNavigationMediaPickerViewController class]]] setTintColor:[UIColor whiteColor]];
//Configure navigation bar title text color
[[UINavigationBar appearanceWhenContainedInInstancesOfClasses:@[[WPNavigationMediaPickerViewController class]]] setTitleTextAttributes:@{NSForegroundColorAttributeName: [UIColor whiteColor]} ];
//Configure background color for media scroll view
[[UICollectionView appearanceWhenContainedInInstancesOfClasses:@[[WPMediaCollectionViewController class]]] setBackgroundColor:[UIColor colorWithRed:233/255.0f green:239/255.0f blue:243/255.0f alpha:1.0f]];
//Configure background color for media cell while loading image.
[[WPMediaCollectionViewCell appearanceWhenContainedInInstancesOfClasses:@[[WPMediaCollectionViewController class]]] setBackgroundColor:[UIColor colorWithRed:243/255.0f green:246/255.0f blue:248/255.0f alpha:1.0f]];
//Configure color for activity indicator while loading media collection
[[UIActivityIndicatorView appearanceWhenContainedInInstancesOfClasses:@[[WPMediaCollectionViewController class]]] setColor:[UIColor grayColor]];
````

### How to use a custom data source for the picker

If you have a custom database of media and you want to display it using the WPMediaPicker you need to to implement the following protocols around your data:

 * [WPMediaCollectionDataSource](Pod/Classes/WPMediaCollectionDataSource.h)
 * [WPMediaGroup](Pod/Classes/WPMediaCollectionDataSource.h)
 * [WPMediaAsset](Pod/Classes/WPMediaCollectionDataSource.h)

You can view the protocols documentation for more implementation details. 
After you have implemented it you can use it by simple doing the following:

```` objective-c
self.customDataSource = [[WPCustomAssetDataSource alloc] init];
mediaPicker.dataSource = self.customDataSource;
````

### Sample Project

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Requirements

 * ARC 
 * Photos, AVFoundation, ImageIO
 * XCode 9 or above
 * iOS 10 or above

## Author

WordPress, mobile@automattic.com

## License

WPMediaPicker is available under the GPL license. See the [LICENSE file](./LICENSE) for more info.

