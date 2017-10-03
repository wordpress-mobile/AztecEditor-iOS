# Change Log
All notable changes to this project will be documented in this file.
`WPMediaPicker` adheres to [Semantic Versioning](http://semver.org/).

#### 0.x Releases
- `0.23` Release  - [0.23](#23)
- `0.22` Release  - [0.22](#22)
- `0.21` Release  - [0.21](#21)
- `0.20` Release  - [0.20](#20)
- `0.19` Release  - [0.19](#19)
- `0.18` Releases - [0.18](#18)
- `0.17` Releases - [0.17](#17)
- `0.16` Releases - [0.16](#16)
- `0.15` Releases - [0.15](#15)

---
## [0.23](https://github.com/wordpress-mobile/MediaPicker-iOS/releases/tag/0.23)
Released on 2017-10-02. All issues associated with this milestone can be found using this
[filter](https://github.com/wordpress-mobile/MediaPicker-iOS/pulls?utf8=✓&q=is%3Apr%20is%3Aclosed%20milestone%3A0.23).

### Fixed
- Fixed layout issues for the iPhoneX. #242
- Updated collection cell design for audio & doc files. #245

## [0.22](https://github.com/wordpress-mobile/MediaPicker-iOS/releases/tag/0.22)
Released on 2017-09-21. All issues associated with this milestone can be found using this
[filter](https://github.com/wordpress-mobile/MediaPicker-iOS/pulls?utf8=✓&q=is%3Apr%20is%3Aclosed%20milestone%3A0.22).

### Fixed
- Fixed crash on photos permission check. #239

## [0.21](https://github.com/wordpress-mobile/MediaPicker-iOS/releases/tag/0.21)
Released on 2017-09-06. All issues associated with this milestone can be found using this
[filter](https://github.com/wordpress-mobile/MediaPicker-iOS/pulls?utf8=✓&q=is%3Apr%20is%3Aclosed%20milestone%3A0.21).

### Fixed
- Fixed some crashes and bugs on the demo app. #219 #221
- Fixed bugs related to selection of assets and refresh. #225 #223
- Improved performance when capturing new media inside the picker. #211
- Photos captured using the picker were not saving metadata. #226

## [0.20](https://github.com/wordpress-mobile/MediaPicker-iOS/releases/tag/0.20)
Released on 2017-08-25. All issues associated with this milestone can be found using this
[filter](https://github.com/wordpress-mobile/MediaPicker-iOS/pulls?utf8=✓&q=is%3Apr%20is%3Aclosed%20milestone%3A0.20).

### Added
- New design for the picker media cells. #203 #205
- New design and interaction for album selector. #207

### Fixed
- Improved performance of loading albums and assets on the picker. #209
- Fixed selection bug when capturing new cell. #214
- Improved performance when capturing new media inside the picker. #211

## [0.19](https://github.com/wordpress-mobile/MediaPicker-iOS/releases/tag/0.19)
Released on 2017-07-26. All issues associated with this milestone can be found using this
[filter](https://github.com/wordpress-mobile/MediaPicker-iOS/pulls?utf8=✓&q=is%3Apr%20is%3Aclosed%20milestone%3A0.19).

#### Fixed
- Fixed some retain cycles that were causing issues with double notifications.
- Refactor options on the picker to allow better refresh of picker.
- Allow selected assets to be pre-selected on the picker.

## [0.18](https://github.com/wordpress-mobile/MediaPicker-iOS/releases/tag/0.18)
Released on 2017-06-16. All issues associated with this milestone can be found using this
[filter](https://github.com/wordpress-mobile/MediaPicker-iOS/pulls?utf8=✓&q=is%3Apr%20is%3Aclosed%20milestone%3A0.18).

#### Fixed
- Fixed unit tests compilation and started running them on Travis CI
- Improved startup time of the picker
- Fix long  standing issue when certain updates when switching groups where crashing the picker.

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
