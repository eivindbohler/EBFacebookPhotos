Pod::Spec.new do |s|
  s.name     = 'EBFacebookPhotos'
  s.version  = '0.0.7'
  s.license  = 'MIT'
  s.summary  = 'A small library to help fetch Facebook albums and photos as efficiently as easily as possible.'
  s.homepage = 'http://eivindbohler.com'
  s.author   = { 'Eivind R. Bohler' => 'eivind.bohler@gmail.com' }
  s.source   = { :git => 'https://github.com/eivindbohler/EBFacebookPhotos.git', :tag => '0.0.7' }
  s.platform = :ios, "5.1"  
  s.source_files = 'EBFacebookPhotos/EBFacebookPhotos.{h,m}'
  s.framework = 'Foundation', 'CoreGraphics', 'UIKit'
  s.requires_arc = true
  
  s.dependency 'AFNetworking', '>= 1.2.0'
  s.dependency 'Facebook-iOS-SDK', '>= 3.2.1'
end
