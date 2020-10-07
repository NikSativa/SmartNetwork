Pod::Spec.new do |spec|
    spec.name         = "NRequestTestHelpers"
    spec.version      = "1.0.0"
    spec.summary      = "RESTKit"

    spec.source       = { :git => "https://bitbucket.org/tech4star/nrequest.git" }
    spec.homepage     = "https://bitbucket.org/tech4star/nrequest.git"

    spec.license          = 'MIT'
    spec.author           = { "Nikita Konopelko" => "nik.sativa@gmail.com" }
    spec.social_media_url = "https://www.facebook.com/Nik.Sativa"

    spec.ios.deployment_target = "10.0"
    spec.swift_version = '5.0'

    spec.frameworks = 'XCTest', 'Foundation', 'UIKit'

    spec.default_subspec = 'Core'

    spec.dependency 'NCallback'
    spec.dependency 'NCallbackTestHelpers'

    spec.dependency 'Nimble'
    spec.dependency 'Spry'
    spec.dependency 'Quick'
    spec.dependency 'Spry+Nimble'

    spec.scheme = {
      :code_coverage => true
    }

    spec.subspec 'Core' do |cs|
        cs.resources = ['TestHelpers/**/Test/**/*.{xcassets,json,imageset,png,strings,stringsdict}']
        cs.source_files = 'TestHelpers/**/Test*.{storyboard,xib,swift}',
                          'TestHelpers/**/Fake*.*',
                          'TestHelpers/**/*+TestHelper.*'

		cs.dependency 'NRequest/Core'
        cs.test_spec 'Tests' do |tests|
            #        tests.requires_app_host = true
            tests.source_files = 'Tests/Specs/Core/**/*Spec.swift'
        end
    end

    spec.subspec 'Inject' do |is|
        is.resources = ['TestHelpers/**/Test/**/*.{xcassets,json,imageset,png,strings,stringsdict}']
        is.source_files = 'TestHelpers/**/Test*.{storyboard,xib,swift}',
                          'TestHelpers/**/Fake*.*',
                          'TestHelpers/**/*+TestHelper.*'

        is.dependency 'NInject'
        is.dependency 'NInjectTestHelpers'

		is.dependency 'NRequest/Inject'
        is.dependency 'NRequestTestHelpers/Core'

        is.test_spec 'Tests' do |tests|
            #        tests.requires_app_host = true
            tests.source_files = 'Tests/Specs/Inject/**/*Spec.swift'
        end
    end
end
