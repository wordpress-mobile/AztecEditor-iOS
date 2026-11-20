# frozen_string_literal: true

Pod::Spec.new do |s|
  s.name          = 'WordPress-Aztec-iOS'
  s.version       = '1.20.0'

  s.summary       = 'The native HTML Editor.'
  s.description   = <<-DESC
                    The native HTML Editor by Automattic Inc.

                    This library provides a UITextView subclass with HTML visual editing capabilities.
  DESC

  s.homepage      = 'https://github.com/wordpress-mobile/AztecEditor-iOS'
  s.license       = { type: 'MPLv2', file: 'LICENSE.md' }
  s.author        = { 'The WordPress Mobile Team' => 'mobile@wordpress.org' }

  s.ios.deployment_target = '15.0'
  s.swift_version = '5.0'

  s.source        = { git: 'https://github.com/wordpress-mobile/AztecEditor-iOS.git', tag: s.version.to_s }
  s.module_name = 'Aztec'
  s.source_files = [
    'Sources/Aztec/Classes/**/*',
    'Sources/HTMLParser/**/*'
  ]
  s.resource_bundles = {
    'WordPress-Aztec-iOS': [
      'Sources/Aztec/Assets/**/*'
    ]
  }
  s.xcconfig = {
    'OTHER_LDFLAGS' => '-lxml2',
    'HEADER_SEARCH_PATHS' => '/usr/include/libxml2'
  }

  s.test_spec 'Tests' do |test_spec|
    test_spec.source_files = [
      'Tests/AztecTests/**/*.{h,m,swift}',
      'Tests/HTMLParserTests/**/*.{h,m,swift}'
    ]
    test_spec.resources = [
      'Tests/AztecTests/Resources/**/*.{dat,png,jpg,jpeg,json,xctestplan,html}',
      'Tests/HTMLParserTests/Resources/**/*.{dat,png,jpg,jpeg,json,xctestplan,html}'
    ]
    test_spec.preserve_paths = [
      'Tests/AztecTests/**/*.xctestplan',
      'Tests/HTMLParserTests/**/*.xctestplan'
    ]
    test_spec.frameworks = 'XCTest'
  end
end
