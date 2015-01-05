Pod::Spec.new do |s|
  s.name             = "WPMediaPicker"
  s.version          = "0.1.0"
  s.summary          = "WPMediaPicker is an iOS controller that allows capture and picking of media assets."
  s.description      = <<-DESC
                       WPMediaPicker is an iOS controller that allows capture and picking of media assets.
                       It allows:
                       * Multiple selection of media.
                       * Capture of new media while selecting
                       DESC
  s.homepage         = "https://github.com/wordpress-mobile/WPMediaPicker"
  s.screenshots      = "https://github.com/wordpress-mobile/WPMediaPicker/screenshots_1.jpg"
  s.license          = 'MIT'
  s.author           = { "WordPress" => "mobile@automattic.com" }
  s.source           = { :git => "https://github.com/wordpress-mobile/WPMediaPicker.git", :tag => s.version.to_s }

  s.platform     = :ios, '7.0'
  s.requires_arc = true

  s.source_files = 'Pod/Classes'
  s.resource_bundles = {
    'WPMediaPicker' => ['Pod/Assets/*.png']
  }

  s.public_header_files = 'Pod/Classes/**/*.h'
  s.frameworks = 'UIKit', 'AssetsLibrary', 'AVFoundation'
end
