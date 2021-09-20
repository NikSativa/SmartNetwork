Pod::Spec.new do |spec|
  spec.name         = "NRequest"
  spec.version      = "3.0.1"
  spec.summary      = "RESTKit"

  spec.source       = { :git => "git@github.com:NikSativa/NRequest.git" }
  spec.homepage     = "https://github.com/NikSativa/NRequest"

  spec.license          = 'MIT'
  spec.author           = { "Nikita Konopelko" => "nik.sativa@gmail.com" }
  spec.social_media_url = "https://www.facebook.com/Nik.Sativa"

  spec.ios.deployment_target = "10.0"
  spec.swift_version = '5.0'

  spec.frameworks = 'Foundation', 'UIKit'
  spec.dependency 'NQueue'
  spec.dependency 'NCallback'

  spec.source_files  = 'Source/**/*.swift'
end
