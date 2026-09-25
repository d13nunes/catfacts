platform :ios, '15.0'
use_frameworks!

target 'CatFacts' do
    pod 'Alamofire', '~> 5.2'
end

# Pod specs declare their own (older) minimums; align them with the app so Xcode doesn't warn or fail on unsupported targets.
post_install do |installer|
    installer.pods_project.targets.each do |target|
        target.build_configurations.each do |config|
            config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '15.0'
        end
    end
end
