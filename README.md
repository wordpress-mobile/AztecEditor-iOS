# Aztec for iOS: Native HTML Editor

<p align="center">
<img width=200px height=200px src="RepoAssets/aztec.png" alt="Aztec's Logo'"/>
</p>

[![Travis](https://travis-ci.org/wordpress-mobile/AztecEditor-iOS.svg?branch=develop)](https://travis-ci.org/wordpress-mobile/AztecEditor-iOS)
[![Version](https://img.shields.io/cocoapods/v/WordPress-Aztec-iOS.svg?style=flat)](http://cocoapods.org/pods/WordPress-Aztec-iOS)
[![License](https://img.shields.io/cocoapods/l/WordPress-Aztec-iOS.svg?style=flat)](http://cocoapods.org/pods/WordPress-Aztec-iOS)
[![Platform](https://img.shields.io/cocoapods/p/WordPress-Aztec-iOS.svg?style=flat)](http://cocoapods.org/pods/WordPress-Aztec-iOS)

## Requirements

- iOS 9 and above
- Xcode 9.3 and above

## Running the Example App

To run the Example app, you first need to make sure its dependencies are installed:

- Make sure you have [Carthage](https://github.com/Carthage/Carthage) installed (we're currently using version 0.23.0).
- Using the command line:

```bash
cd Example
carthage update --platform iOS
```

Once Carthage finishes, you should open the file `Aztec.xcworkspace` from the root directory of Aztec.

Make sure the `AztecExample` target it selected, and press CMD + R to run it.

## Integrating the Library with Carthage

WordPress-Aztec-iOS is available through [Carthage](https://github.com/Carthage/Carthage). To install
it, simply add the following line to your Cartfile:

```bash
github "wordpress-mobile/AztecEditor-iOS" "develop"
```

Follow [these instructions](https://github.com/Carthage/Carthage#getting-started) to build `Aztec.framework`.

Then:

1. Open your project, head to **Build Settings** for your target and add `$(SDKROOT)/usr/include/libxml2/` to your **Header Search Paths**.
2. Go to `Build Phases` > `Link Binary With Libraries` and add `Aztec.framework`.
3. Add `import Aztec` to your project's source.

## Integrating the Library with CocoaPods

WordPress-Aztec-iOS is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```bash
pod "WordPress-Aztec-iOS"
```

## Usage

After installing Aztec, import the module and use the `Aztec.TextView` view:

```swift
import Aztec

// ...

let textView = Aztec.TextView(
    defaultFont: UIFont,
    defaultParagraphStyle: ParagraphStyle = ParagraphStyle.default,
    defaultMissingImage: UIImage) {
```

## License

WordPress-Aztec-iOS is available under the GPLv2 license. See the [LICENSE file](./LICENSE) for more info.
