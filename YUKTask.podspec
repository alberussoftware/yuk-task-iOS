#
# Be sure to run `pod lib lint YUKTask.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name                  = 'YUKTask'
  s.version               = '0.1.5'
  s.summary               = 'Improved, fully generic version of Operation for iOS'
  s.homepage              = 'https://github.com/alberussoftware/yuk-task-iOS'
  s.license               = { :type => 'Apache 2.0', :file => 'LICENSE' }
  s.author                = { 'jeudesprits' => 'jeudesprits@icloud.com' }
  s.source                = { :git => 'https://github.com/alberussoftware/yuk-task-iOS.git', :tag => s.version.to_s }
  s.social_media_url      = 'https://twitter.com/jeudesprits'
  s.ios.deployment_target = '13.0'
  s.swift_version         = '5.3'
  s.source_files          = 'Sources/YUKTask/**/*'
  s.frameworks            = 'Foundation'
  s.dependency              'YUKLock'
end
