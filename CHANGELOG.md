1.19.8
-------
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
