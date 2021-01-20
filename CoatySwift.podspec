#
# Be sure to run `pod lib lint CoatySwift.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'CoatySwift'
  s.version          = '2.3.1'
  s.summary          = 'CoatySwift is a Swift implementation of the Coaty Collaborative IoT framework for iOS, iPadOS, and macOS.'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
  Using the Coaty [koʊti] framework as a middleware, you can build distributed applications out of decentrally organized application components, so called Coaty agents, which are loosely coupled and communicate with each other in (soft) real-time. The main focus is on IoT prosumer scenarios where smart agents act in an autonomous, collaborative, and ad-hoc fashion. CoatySwift agents can run on iOS, iPadOS, and macOS.
                       DESC

  s.homepage         = 'https://coaty.io'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Siemens AG' => 'coaty.team@gmail.com' }
  s.source           = { :git => 'https://github.com/coatyio/coaty-swift.git', :tag => s.version.to_s }
  s.documentation_url = 'https://coatyio.github.io/coaty-swift/api/index.html'
  s.swift_version = '5.0'

  s.ios.deployment_target = '9.0'
  s.osx.deployment_target = '10.14'

  s.source_files = 'CoatySwift/Classes/**/*'
    
  s.dependency 'CocoaMQTT', '~> 1.2.5'
  s.dependency 'RxSwift', '~> 5.1.1'
  s.dependency 'RxCocoa', '~> 5.1.1'
  s.dependency 'XCGLogger', '~> 7.0.1'

end

