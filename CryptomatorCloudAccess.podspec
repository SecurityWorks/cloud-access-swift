Pod::Spec.new do |s|
  s.name             = 'CryptomatorCloudAccess'
  s.version          = ENV['LIB_VERSION'] || '0.0.1-snapshot'
  s.summary          = 'CryptomatorCloudAccess is used in Cryptomator for iOS to access different cloud providers.'

  s.homepage         = 'https://github.com/cryptomator/cloud-access-swift'
  s.license          = { :type => 'AGPLv3', :file => 'LICENSE.txt' }
  s.author           = { 'Philipp Schmid' => 'philipp.schmid@skymatic.de',
                         'Sebastian Stenzel' => 'sebastian.stenzel@skymatic.de',
                         'Tobias Hagemann' => 'tobias.hagemann@skymatic.de' }
  s.source           = { :git => 'https://github.com/cryptomator/cloud-access-swift.git', :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/Cryptomator'

  s.source_files = 'Sources/CryptomatorCloudAccess/CryptomatorCloudAccess.h'
  s.ios.deployment_target = '9.0'
  s.osx.deployment_target = '10.12'
  s.swift_version = '5.0'

  s.subspec 'Core' do |ss|
    ss.source_files = 'Sources/CryptomatorCloudAccess/Core/**/*.swift'
    ss.dependency 'PromisesSwift', '~> 1.2.0'
  end

  s.subspec 'LocalFileSystem' do |ss|
    ss.dependency 'CryptomatorCloudAccess/Core'
    ss.source_files = 'Sources/CryptomatorCloudAccess/LocalFileSystem/**/*.swift'
  end

  s.subspec 'Crypto' do |ss|
    ss.dependency 'CryptomatorCloudAccess/Core'
    ss.source_files = 'Sources/CryptomatorCloudAccess/Crypto/**/*.swift'
    ss.dependency 'CryptomatorCryptoLib', '~> 0.9.0'
    ss.dependency 'GRDB.swift', '~> 4.14.0'
  end

  s.subspec 'WebDAV' do |ss|
    ss.dependency 'CryptomatorCloudAccess/Core'
    ss.source_files = 'Sources/CryptomatorCloudAccess/WebDAV/**/*.swift'
  end
end
