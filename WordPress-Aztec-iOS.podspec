#
# Be sure to run `pod lib lint WordPress-Aztec-iOS.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'WordPress-Aztec-iOS'
  s.version          = '1.0.0-beta.18.1'
  s.summary          = 'The native HTML Editor.'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
                       The native HTML Editor by Automattic Inc.
                       DESC

  s.homepage         = 'https://github.com/wordpress-mobile/WordPress-Aztec-iOS'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'GPLv2', :file => 'LICENSE' }
  s.author           = { 'Automattic' => 'mobile@automattic.com', 'Diego Rey Mendez' => 'diego.rey.mendez@automattic.com', 'Sergio Estevao' => 'sergioestevao@gmail.com', 'Jorge Leandro Perez' => 'jorge.perez@automattic.com' }
  s.social_media_url = "http://twitter.com/WordPressiOS"
  s.source           = { :git => 'https://github.com/wordpress-mobile/WordPress-Aztec-iOS.git', :tag => s.version.to_s }
  s.ios.deployment_target = '9.0'

  s.module_name = "Aztec"
  s.source_files = 'Aztec/Classes/**/*'
  s.resources = 'Aztec/Assets/**/*'

  s.xcconfig = {'OTHER_LDFLAGS' => '-lxml2',
  				'HEADER_SEARCH_PATHS' -> '/usr/include/libxml2'}

end
