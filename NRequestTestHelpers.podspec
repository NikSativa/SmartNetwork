Pod::Spec.new do |spec|
  spec.name         = "NRequestTestHelpers"
  spec.version      = "3.2.3"
  spec.summary      = "RESTKit"

  spec.source       = { :git => "git@github.com:NikSativa/NRequest.git" }
  spec.homepage     = "https://github.com/NikSativa/NRequest"

  spec.license          = 'MIT'
  spec.author           = { "Nikita Konopelko" => "nik.sativa@gmail.com" }
  spec.social_media_url = "https://www.facebook.com/Nik.Sativa"

  spec.ios.deployment_target = '11.0'
  spec.swift_version = '5.5'

  spec.frameworks = 'XCTest', 'Foundation', 'UIKit'
  spec.weak_framework = 'NCallback'

  spec.dependency 'NSpry'
  spec.dependency 'NRequest'
  spec.dependency 'NQueue'
  spec.dependency 'NQueueTestHelpers'

  #  spec.scheme = {
  #    :code_coverage => true
  #  }

  spec.default_subspec = 'Core'

  spec.subspec 'Core' do |sub|
    sub.resources = ['TestHelpers/Core/**/*.{xcassets,json,imageset,png,strings,stringsdict}']
    sub.source_files = 'TestHelpers/Core/**/*.{storyboard,xib,swift}'
  end

  spec.subspec 'Extra' do |sub|
    sub.resources = ['TestHelpers/Extra/**/*.{xcassets,json,imageset,png,strings,stringsdict}']
    sub.source_files = 'TestHelpers/Extra/**/*.swift'

    sub.dependency 'Nimble'

    sub.frameworks = 'XCTest', 'Foundation', 'UIKit'
  end

  spec.test_spec 'Tests' do |tests|
    tests.dependency 'Quick'
    tests.dependency 'Nimble'
    tests.dependency 'NSpry_Nimble'

    tests.dependency 'NQueue'
    tests.dependency 'NQueueTestHelpers'
    tests.dependency 'NCallback'
    tests.dependency 'NCallbackTestHelpers'

    tests.source_files  = 'Tests/**/*.swift'
  end
end
