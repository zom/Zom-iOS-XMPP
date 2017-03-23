//
//  ZomAppDelegate.h
//  ChatSecure
//
//  Created by Christopher Ballinger on 6/10/15.
//  Copyright (c) 2015 Chris Ballinger. All rights reserved.
//

@import ChatSecureCore;

@class ZomMainTabbedViewController;

@interface ZomAppDelegate : OTRAppDelegate

- (OTRAccount *)getDefaultAccount;
- (void) setDefaultAccount:(OTRAccount *)account;
@property (nonatomic, strong) ZomMainTabbedViewController *mainTabViewController;

@end
