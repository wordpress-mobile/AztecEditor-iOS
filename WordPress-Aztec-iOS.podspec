#
# Be sure to run `pod lib lint WordPress-Aztec-iOS.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'WordPress-Aztec-iOS'
  s.version          = '0.1.0'
  s.summary          = 'TBD.  This will be modified as soon as we can publish more info.'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
TBD.  This will be modified as soon as we can publish more info.
TBD.  This will be modified as soon as we can publish more info.
TBD.  This will be modified as soon as we can publish more info.
TBD.  This will be modified as soon as we can publish more info.
                       DESC

  s.homepage         = 'https://github.com/wordpress-mobile/WordPress-Aztec-iOS'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'GPLv2', :file => 'LICENSE' }
  s.author           = { 'Automattic' => 'mobile@automattic.com', 'Diego Rey Mendez' => 'diego.rey.mendez@automattic.com' }
  s.source           = { :git => 'https://github.com/wordpress-mobile/WordPress-Aztec-iOS.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/WordPress'

  s.ios.deployment_target = '8.3'

  s.module_name = "Aztec"
  s.source_files = 'WordPress-Aztec-iOS/Classes/**/*'
  s.private_header_files = 'WordPress-Aztec-iOS/Modulemaps/libxml2/*.{h}'
  
  # For more info about these, see: https://medium.com/swift-and-ios-writing/using-a-c-library-inside-a-swift-framework-d041d7b701d9#.wohyiwj5e
  #
  s.pod_target_xcconfig = {'SWIFT_INCLUDE_PATHS' => '$(SRCROOT)/../../WordPress-Aztec-iOS/Modulemaps/libxml2/**', 'HEADER_SEARCH_PATHS' => '$(SDKROOT)/usr/include/libxml2'}
  s.preserve_paths = 'WordPress-Aztec-iOS/Modulemaps/libxml2/module.modulemap'
  
  # s.resource_bundles = {
  #   'WordPress-Aztec-iOS' => ['WordPress-Aztec-iOS/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  # s.dependency 'AFNetworking', '~> 2.3'
end
