# WPMediaPicker

[![CI Status](http://img.shields.io/travis/wordpress-mobile/WPMediaPicker.svg?style=flat)](https://travis-ci.org/wordpress-mobile/WPMediaPicker)
[![Version](https://img.shields.io/cocoapods/v/WPMediaPicker.svg?style=flat)](http://cocoadocs.org/docsets/WPMediaPicker)
[![License](https://img.shields.io/cocoapods/l/WPMediaPicker.svg?style=flat)](http://cocoadocs.org/docsets/WPMediaPicker)
[![Platform](https://img.shields.io/cocoapods/p/WPMediaPicker.svg?style=flat)](http://cocoadocs.org/docsets/WPMediaPicker)

WPMediaPicker is an iOS controller that allows capture and picking of media assets.
It allows:
 * Multiple selection of media.
 * Capture of new media while selecting

![Screenshot](screenshots_1.jpg "Screenshot")
## Usage

To use the picker do the following:

### Import header

```` objective-c
#import <WPMediaPicker/WPMediaPickerViewController.h>
````

### Create and present WPMediaPickerViewController

```` objective
WPMediaPickerViewController * mediaPicker = [[WPMediaPickerViewController alloc] init];
mediaPicker.delegate = self;
[self presentViewController:mediaPicker animated:YES completion:nil];
````

### Implement didFinishPickingAssets delegate

The delegate is responsible for dismissing the picker when the operation completes. To dismiss the picker, call the [dismissViewControllerAnimated:completion:](https://developer.apple.com/library/ios/documentation/uikit/reference/UIViewController_Class/index.html#//apple_ref/occ/instm/UIViewController/dismissViewControllerAnimated:completion:) method of the presenting controller responsible for displaying `WPMediaPickerController` object. Please refer to the demo app.

```` objective-c
- (void)mediaPickerController:(WPMediaPickerViewController *)picker didFinishPickingAssets:(NSArray *)assets
{
  [self dismissViewControllerAnimated:YES completion:nil];  
  // assets contains ALAsset objects.
}
````

### Sample Project

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Requirements

 * ARC 
 * AssetsLibrary and MediaPlayer frameworks.
 * XCode 5
 * iOS 7

## Installation

WPMediaPicker is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

    pod "WPMediaPicker"

## Author

WordPress, mobile@automattic.com

## License

WPMediaPicker is available under the MIT license. See the LICENSE file for more info.

