#source 'https://mirrors.tuna.tsinghua.edu.cn/git/CocoaPods/Specs.git'

# Uncomment the next line to define a global platform for your project
platform :ios, '12.0'

# Comment the next line if you don't want to use dynamic frameworks
use_frameworks!

project "ReverseiOS"

#######################################
#               Pods                  #
#######################################

def app
  pod 'FLEX', '~> 4.4.1'
  pod 'LookinServer'
end


#######################################
#               Targets               #
#######################################

target "ReverseiOS" do
end

target "MyHook" do
  app
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      if config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'].to_f < 12.0
        config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '12.0'
      end
    end
  end
end
