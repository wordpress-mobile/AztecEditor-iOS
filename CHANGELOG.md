# Change Log
All notable changes to this project will be documented in this file.
`WPMediaPicker` adheres to [Semantic Versioning](http://semver.org/).

#### 0.x Releases
- `0.17` Releases - [0.17](#17)
- `0.16` Releases - [0.16](#16)
- `0.15` Releases - [0.15](#15)

---

## [0.17](https://github.com/wordpress-mobile/MediaPicker-iOS/releases/tag/0.17)
Released on 2017-05-26. All issues associated with this milestone can be found using this
[filter](https://github.com/wordpress-mobile/MediaPicker-iOS/pulls?utf8=✓&q=is%3Apr%20is%3Aclosed%20milestone%3A0.17).

#### Added
- Two new `WPMediaPickerViewControllerDelegate` methods: `mediaPickerControllerWillBeginLoadingData` and `mediaPickerControllerDidEndLoadingData` to inform the delegate when loading of data from the data source has begun / ended.

## [0.16](https://github.com/wordpress-mobile/MediaPicker-iOS/releases/tag/0.16)
Released on 2017-05-04. All issues associated with this milestone can be found using this
[filter](https://github.com/wordpress-mobile/MediaPicker-iOS/pulls?utf8=✓&q=is%3Apr%20is%3Aclosed%20milestone%3A0.16).

#### Added
- A title to the default asset preview view controller, showing the date of the asset.
- The media picker can now handle non-image and non-video assets, such as PDFs. The cells in the picker will show a placeholder icon, the file type, and filename.
- The media picker will show a placeholder icon if an image or video fails to load.

### Fixed
- Video is now captured in high quality.
- The picker's layout is now improved on iPad, for more consistent cell spacing.
- The group picker should now be much faster to load and scroll for PHAssetCollections.
- Date / time formatting code has been refactored / cleaned up a little, and should now better handle different locales.
- Optimized the loading and caching of group thumbnails.

---

## [0.15](https://github.com/wordpress-mobile/MediaPicker-iOS/releases/tag/0.15)
Released on 2017-03-29. All issues associated with this milestone can be found using this
[filter](https://github.com/wordpress-mobile/MediaPicker-iOS/issues?utf8=✓&q=milestone%3A0.15).

#### Added
- A new toolbar to WPVideoPlayerView to allow control of play/pause of video assets.

### Fixed
- Fixed scrolling issues when opening the picker.

---
