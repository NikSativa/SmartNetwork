Pod::Spec.new do |spec|
  spec.name         = "NRequestTestHelpers"
  spec.version      = "3.1.1"
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
  spec.dependency 'NCallback'
  spec.dependency 'NCallbackTestHelpers'

  spec.scheme = {
    :code_coverage => true
  }

  spec.source_files  = 'TestHelpers/**/*.swift'

  spec.test_spec 'Tests' do |tests|
    tests.dependency 'Quick'
    tests.dependency 'Nimble'
    tests.dependency 'NSpry_Nimble'

    tests.source_files  = 'Tests/**/*.swift'
  end
end
