# Aztec for iOS: Native HTML Editor

<p align="center">
<img width=200px height=200px src="RepoAssets/aztec.png" alt="Aztec's Logo'"/>
</p>

[![BuddyBuild](https://dashboard.buddybuild.com/api/statusImage?appID=57ee5274e349f601000457c7&branch=develop&build=latest)](https://dashboard.buddybuild.com/apps/57ee5274e349f601000457c7/build/latest)
[![Version](https://img.shields.io/cocoapods/v/WordPress-Aztec-iOS.svg?style=flat)](http://cocoapods.org/pods/WordPress-Aztec-iOS)
[![License](https://img.shields.io/cocoapods/l/WordPress-Aztec-iOS.svg?style=flat)](http://cocoapods.org/pods/WordPress-Aztec-iOS)
[![Platform](https://img.shields.io/cocoapods/p/WordPress-Aztec-iOS.svg?style=flat)](http://cocoapods.org/pods/WordPress-Aztec-iOS)

## Example

To run the example project, clone the repo, and run `carthage update` from the Example directory first.

## Requirements

- iOS 9 and above
- Xcode 8

## Installation

WordPress-Aztec-iOS is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod "WordPress-Aztec-iOS"
```

## Usage

After installing Aztec, import the module and use the `Aztec.TextView` view:

```swift
import Aztec

// ...

let textView = Aztec.TextView(defaultFont: Constants.defaultContentFont, defaultMissingImage: Constants.defaultMissingImage)
```

Note: Obj-C is not officially supported.

## License

WordPress-Aztec-iOS is available under the GPLv2 license. See the [LICENSE file](./LICENSE) for more info.
