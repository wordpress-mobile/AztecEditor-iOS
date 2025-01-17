# frozen_string_literal: true

Pod::Spec.new do |s|
  s.name          = 'WordPress-Aztec-iOS'
  s.version       = '1.19.11'

  s.summary       = 'The native HTML Editor.'
  s.description   = <<-DESC
                    The native HTML Editor by Automattic Inc.

                    This library provides a UITextView subclass with HTML visual editing capabilities.
  DESC

  s.homepage      = 'https://github.com/wordpress-mobile/AztecEditor-iOS'
  s.license       = { type: 'MPLv2', file: 'LICENSE.md' }
  s.author        = { 'The WordPress Mobile Team' => 'mobile@wordpress.org' }

  s.ios.deployment_target = '12.0'
  s.swift_version = '5.0'

  s.source        = { git: 'https://github.com/wordpress-mobile/AztecEditor-iOS.git', tag: s.version.to_s }
  s.module_name = 'Aztec'
  s.source_files = 'Aztec/Classes/**/*'
  s.resource_bundles = {
    'WordPress-Aztec-iOS': [
      'Aztec/Assets/**/*'
    ]
  }
  s.xcconfig = {
    'OTHER_LDFLAGS' => '-lxml2',
    'HEADER_SEARCH_PATHS' => '/usr/include/libxml2'
  }
end
