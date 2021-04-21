Pod::Spec.new do |spec|
    spec.name         = "NRequest"
    spec.version      = "1.0.0"
    spec.summary      = "RESTKit"

    spec.source       = { :git => "git@github.com:NikSativa/NRequest.git" }
    spec.homepage     = "https://github.com/NikSativa/NRequest"

    spec.license          = 'MIT'
    spec.author           = { "Nikita Konopelko" => "nik.sativa@gmail.com" }
    spec.social_media_url = "https://www.facebook.com/Nik.Sativa"

    spec.ios.deployment_target = "10.0"
    spec.swift_version = '5.0'

    spec.frameworks = 'Foundation', 'UIKit'

    spec.default_subspec = 'Core'

    spec.dependency 'NCallback'

    spec.subspec 'Core' do |cs|
        cs.resources = ['Source/Core/**/*.{storyboard,xib,xcassets,json,imageset,png,strings,stringsdict}']
        cs.source_files  = 'Source/Core/**/*.swift'
    end

    spec.subspec 'Inject' do |is|
        is.resources = ['Source/Inject/**/*.{storyboard,xib,xcassets,json,imageset,png,strings,stringsdict}']
        is.source_files  = 'Source/Inject/**/*.swift'

        is.dependency 'NInject'
        is.dependency 'NRequest/Core'
    end
end
