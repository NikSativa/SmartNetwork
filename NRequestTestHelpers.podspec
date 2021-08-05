Pod::Spec.new do |spec|
    spec.name         = "NRequestTestHelpers"
    spec.version      = "2.10.1"
    spec.summary      = "RESTKit"

    spec.source       = { :git => "git@github.com:NikSativa/NRequest.git" }
    spec.homepage     = "https://github.com/NikSativa/NRequest"

    spec.license          = 'MIT'
    spec.author           = { "Nikita Konopelko" => "nik.sativa@gmail.com" }
    spec.social_media_url = "https://www.facebook.com/Nik.Sativa"

    spec.ios.deployment_target = "10.0"
    spec.swift_version = '5.0'

    spec.frameworks = 'XCTest', 'Foundation', 'UIKit'

    spec.dependency 'Nimble'
    spec.dependency 'NSpry'
    spec.dependency 'Quick'

    spec.dependency 'NRequest'

    spec.dependency 'NCallback'
    spec.dependency 'NCallbackTestHelpers'

    #spec.scheme = {
    #  :code_coverage => true
    #}

    #spec.resources = ['TestHelpers/**/*.{storyboard,xib,xcassets,json,imageset,png,strings,stringsdict}']
    spec.source_files  = 'TestHelpers/**/*.swift'

    spec.test_spec 'Tests' do |tests|
        #tests.requires_app_host = true
        #tests.resources = ['TestHelpers/**/*.{storyboard,xib,xcassets,json,imageset,png,strings,stringsdict}']
        tests.source_files  = 'Tests/**/*.swift'
    end
end
