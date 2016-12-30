Pod::Spec.new do |s|
  s.name             = "DBClient"
  s.version          = "0.1.1"
  s.requires_arc = true
  s.summary          = "CoreData & Realm wrapper written on Swift"
  s.homepage         = ""
  s.license          = 'MIT'
  s.author           = { "Yalantis" => "mail@yalantis.com" }
  s.source           = { :git => "https://git.yalantis.com/roman.kyrylenko/DBClient.git" }
  s.social_media_url = 'https://yalantis.com/'
  s.homepage = 'https://yalantis.com/'

  s.ios.deployment_target = "10.0"
  s.source_files = ['Source/Core/*']
  s.dependency "Bolts-Swift", "~> 1.3.0"
  s.frameworks = ['Foundation']

  s.default_subspec = "CoreData"
  
  s.subspec "CoreData" do  |spec|
    spec.source_files = ['CoreData/*']
    spec.frameworks = ['CoreData']
  end

  s.subspec "Realm" do  |spec|
    spec.source_files = ['Realm/*']
    spec.dependency "RealmSwift", "~> 2.1.1"
  end

end