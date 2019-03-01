#
# Be sure to run `pod lib lint CoatySwift.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'CoatySwift'
  s.version          = '0.1.0'
  s.summary          = 'Collaborative IoT framework in Swift for iOS and macOS.'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
The Coaty framework enables realization of collaborative IoT applications and scenarios in a distributed, decentralized fashion. A Coaty application consists of Coaty agents that act independently and communicate with each other to achieve common goals. Coaty agents can run on IoT devices, mobile devices, in microservices, cloud or backend services.
                       DESC

  s.homepage         = 'https://coaty.io'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Siemens AG' => 'coaty.team@gmail.com' }
  s.source           = { :git => 'https://code.siemens.com/collaborative-iot/coaty/coaty-swift.git', :tag => s.version.to_s }

  s.ios.deployment_target = '8.0'

  s.source_files = 'CoatySwift/Classes/**/*'
  
  # s.resource_bundles = {
  #   'CoatySwift' => ['CoatySwift/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  # s.dependency 'AFNetworking', '~> 2.3'
  s.dependency 'CocoaMQTT', '~> 1.1.3'
  s.dependency 'RxSwift', '~> 4.0'
  s.dependency 'RxCocoa', '~> 4.0'
  s.dependency 'XCGLogger', '~> 6.1.0'

end
