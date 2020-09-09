Pod::Spec.new do |spec|
    spec.name         = "NRequest"
    spec.version      = "1.0.0"
    spec.summary      = "RESTKit"

    spec.source       = { :git => "https://bitbucket.org/tech4star/nrequest.git" }
    spec.homepage     = "https://bitbucket.org/tech4star/nrequest.git"

    spec.license          = 'MIT'
    spec.author           = { "Nikita Konopelko" => "nik.sativa@gmail.com" }
    spec.social_media_url = "https://www.facebook.com/Nik.Sativa"

    spec.ios.deployment_target = "10.0"
    spec.swift_version = '5.0'

    spec.dependency 'NCallback'

    spec.resources = ['Source/**/*.{storyboard,xib,xcassets,json,imageset,png,strings,stringsdict}']
    spec.source_files  = 'Source/**/*.swift'
    spec.exclude_files = 'Source/**/Test/**/*.*'

    spec.frameworks = 'Foundation', 'UIKit'
end
