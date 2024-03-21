# Changelog

The format of this document is inspired by [Keep a Changelog](https://keepachangelog.com/en/1.0.0/) and the project follows [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

<!-- This is a comment, you won't see it when GitHub renders the Markdown file.

When releasing a new version:

1. Remove any empty section (those with `_None._`)
2. Update the `## Unreleased` header to `## [<version_number>](https://github.com/wordpress-mobile/AztecEditor-iOS/releases/tag/<version_number>)`
3. Add a new "Unreleased" section for the next iteration, by copy/pasting the following template:

## Unreleased

### Breaking Changes

_None._

### New Features

_None._

### Bug Fixes

_None._

### Internal Changes

_None._

-->

## Unreleased

### Breaking Changes

_None._

### New Features

_None._

### Bug Fixes

_None._

### Internal Changes

_None._

## 1.19.11

### Bug Fixes

- Improve Mark formatting. [#1352]

## 1.19.10

### Bug Fixes

- Fixed crash when attempting to render Gutenberg comment. [#1383]
- Fixed crash when underlining text with special glyphs. [#1384]

## 1.19.9

### Breaking Changes

_None._

### New Features

_None._

### Bug Fixes

* Worked around a crash that could occur when calling String.paragraphRange(for:) on iOS 17. [#1373]

### Internal Changes

- Add this changelog file. [#1365]

---

_Versions below this precede the Keep a Changelog-inspired formatting._


1.19.8
-------
* Fix Li tag when switching the list style.
* Retain Heading attribute when headings are autocorrected.

1.19.7
-------
* Add variable to control whether typing attributes should be recalculated when deleting backward.
* Allow using the default font for the PreFormatter/HeaderFormatter.

1.19.6
-------
* Add support for Mark inline formatting.

1.19.5
-------
* Add support for the Mark HTML tag.

1.19.4
-------
* Fix Carthage build for Xcode 12
* Replace gridicons with SFSymbols on the Example app

1.19.3
-------
* Expose UIColor hexString helpers to be used by subclasses of Aztec components.

1.19.2
-------
* Fix drawing of underlines when they include newlines.

1.19.1
-------
* Fix a bug where collapse of whitespaces was happening for empty HTML nodes.

1.19.0
-------
* Add support for the sup and sub HTML tags.
* Fix invokation of the delegate method `shouldChangeTextIn` when pasting new content.

1.18.0
-------
* Added an option to not colapse whitespaces when saving the HTML.

1.17.1
-----
* Fix drawing of underlines when they include the last character of content.

1.17.0
-----
 * Fix drawing of underlines when they have a nbsp and span to the end of a line

1.16.0
-----
 * Improve display of ordered lists with large bullet numbers
 * Fix bug where links with text that had a mix of Latin and non-Latin characters were getting split.

1.15.0
-----
 * Allow to use headers fonts without bold effect applied
 * Support for multilevel blockquotes
 * Fix presentation of placeholder images in dark mode.
 * Fix bug that didn't set default text color when changing text color

1.14.1
-----
* Support for xcode 10.

1.14.0
-----
* Support standard HTML colors by name.
* Add support for reverse and start attributes for ordered lists.

1.13.0
-----
* Fix a bug when copying and pasting from other apps when running dark mode.
* Improve list indentation for markers.
