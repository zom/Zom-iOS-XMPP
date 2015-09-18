# [Zom-iOS](https://github.com/zom/zom-iOS)

Zom is a whitelabel fork of [ChatSecure](https://github.com/chatsecure/chatsecure-ios) for the Tibetan community

## Getting Started

You'll need the Zom whitelabeling, ChatSecure source code, and dependencies. You'll also need CocoaPods if you don't have it already.

     $ git clone https://github.com/zom/Zom-iOS.git
     $ cd Zom-iOS
     $ git submodule update --init --recursive
     $ cd ChatSecure
     $ pod install
     $ cd ..
     $ cd Zom
     $ pod install
     $ cd ..
     
Copy over the `Secrets.plist` template:

     $ cp /Zom/OTRResources/Secrets-template.plist /Zom/OTRResources/Secrets.plist
     
Now open up the workspace:

     $ open Zom/Zom.xcworkspace
     
Run the Zom target inside Xcode on the simulator or on your device.