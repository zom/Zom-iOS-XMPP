# [Zom-iOS](https://github.com/zom/zom-iOS)

[![Build Status](https://travis-ci.org/zom/Zom-iOS.svg?branch=master)](https://travis-ci.org/zom/Zom-iOS)

Zom is a whitelabel fork of [ChatSecure](https://github.com/chatsecure/chatsecure-ios)

## Getting Started

You'll need the most recent version of Xcode, CocoaPods, Zom whitelabeling, ChatSecure source code, and dependencies. Also don't forget to add your SSH public key to GitHub or you'll get errors during the submodule step.

     $ git clone https://github.com/zom/Zom-iOS.git
     $ cd Zom-iOS
     $ git submodule update --init --recursive
     $ bash ./ChatSecure/Submodules/CPAProxy/scripts/build-all.sh
     $ bash ./ChatSecure/Submodules/OTRKit/scripts/build-all.sh
     $ bash Zom/copy_podfile.sh
     $ gem install bundler
     $ bundler install
     $ bundler exec pod install --project-directory=ChatSecure
     $ bundler exec pod install --project-directory=Zom
     
     
Copy over the `Secrets.plist` template:

     $ cp ./Zom/OTRResources/Secrets-template.plist ./Zom/OTRResources/Secrets.plist
     
Now open up the workspace:

     $ open Zom/Zom.xcworkspace
     
Run the Zom target inside Xcode on the simulator or on your device.
