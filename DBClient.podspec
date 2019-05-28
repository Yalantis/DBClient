Pod::Spec.new do |s|
  s.name             = 'DBClient'
  s.version          = '1.4'
  s.requires_arc = true
  s.summary          = 'CoreData & Realm wrapper written on Swift'
  s.homepage         = ''
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Yalantis' => 'mail@yalantis.com' }
  s.source           = { :git => 'https://github.com/Yalantis/DBClient.git', :tag => s.version }
  s.social_media_url = 'https://yalantis.com/'
  s.homepage = 'https://yalantis.com/'

  s.ios.deployment_target = '10.0'
  s.swift_version = '5'

  s.dependency 'YALResult', '1.4'
  
  s.default_subspec = 'Core'

  s.subspec 'Core' do |spec|
	spec.source_files = ['DBClient/Core/*.swift']
  end

  s.subspec 'CoreData' do |spec|
  	spec.dependency 'DBClient/Core'
    spec.source_files = ['DBClient/CoreData/*.swift']
    spec.frameworks = ['CoreData']
  end

  s.subspec 'Realm' do  |spec|
  	spec.dependency 'DBClient/Core'
    spec.source_files = ['DBClient/Realm/*.swift']
    spec.dependency 'RealmSwift', '~> 3.15.0'
  end
end
