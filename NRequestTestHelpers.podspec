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
        cs.resources = ['Source/Core/**/Test/**/*.{xcassets,json,imageset,png,strings,stringsdict}']
        cs.source_files = 'Source/Core/**/Test*.{storyboard,xib,swift}',
                          'Source/Core/**/Fake*.*',
                          'Source/Core/**/*+TestHelper.*'
        cs.exclude_files = 'Source/Core/**/*Spec.*',
                           'Source/Core/**/*Tests.*'

		cs.dependency 'NRequest/Core'

        cs.test_spec 'Tests' do |tests|
            #        tests.requires_app_host = true
            tests.source_files = 'Source/Core/**/*Spec.swift'
            tests.exclude_files = 'Source/Core/**/Test*.*',
                                  'Source/Core/**/Fake*.*',
                                  'Source/Core/**/*+TestHelper.*'
        end
    end

    spec.subspec 'Inject' do |is|
        is.resources = ['Source/Inject/**/Test/**/*.{xcassets,json,imageset,png,strings,stringsdict}']
        is.source_files = 'Source/Inject/**/Test*.{storyboard,xib,swift}',
                          'Source/Inject/**/Fake*.*',
                          'Source/Inject/**/*+TestHelper.*'
        is.exclude_files = 'Source/Inject/**/*Spec.*',
                           'Source/Inject/**/*Tests.*'

        is.dependency 'NInject'
        is.dependency 'NInjectTestHelpers'

		is.dependency 'NRequest/Inject'
        is.dependency 'NRequestTestHelpers/Core'

        is.test_spec 'Tests' do |tests|
            #        tests.requires_app_host = true
            tests.source_files = 'Source/Inject/**/*Spec.swift'
            tests.exclude_files = 'Source/Inject/**/Test*.*',
                                  'Source/Inject/**/Fake*.*',
                                  'Source/Inject/**/*+TestHelper.*'
        end
    end
end
