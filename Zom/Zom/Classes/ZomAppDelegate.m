//
//  ZomAppDelegate.m
//  ChatSecure
//
//  Created by Christopher Ballinger on 6/10/15.
//  Copyright (c) 2015 Chris Ballinger. All rights reserved.
//

#import "ZomAppDelegate.h"
#import "ZomTheme.h"
#import "Zom-Swift.h"
#import <ChatSecureCore/NSURL+ChatSecure.h>
#import <ChatSecureCore/OTRAppDelegate.h>

@interface OTRAppDelegate (Zom)
- (void)handleInvite:(NSString *)jidString fingerprint:(NSString *)fingerprint;
@end
    
@implementation ZomAppDelegate

#pragma mark - Theming

- (Class) themeClass {
    return [ZomTheme class];
}

#pragma mark - Overrides

- (Class) conversationViewControllerClass
{
    return [ZomConversationViewController class];
}

- (Class) messagesViewControllerClass
{
    return [ZomMessagesViewController class];
}

#pragma mark - Universal Links

- (BOOL)application:(UIApplication *)application continueUserActivity:(NSUserActivity *)userActivity restorationHandler:(void (^)(NSArray * _Nullable))restorationHandler
{
    if (![self handleUniversalLink:userActivity.webpageURL]) {
        [[UIApplication sharedApplication] openURL:userActivity.webpageURL];
    }
    return TRUE;
}

- (bool)handleUniversalLink:(NSURL *)url {
    
    NSURLComponents *components = [[NSURLComponents alloc] initWithURL:url resolvingAgainstBaseURL:YES];
    NSString *host = components.host;
    if ([host isEqualToString:@"zom.im"] && [url otr_isInviteLink]) {

        __block NSString *username = nil;
        __block NSString *fingerprint = nil;
        [url otr_decodeShareLink:^(NSString *uName, NSString *fPrint) {
            username = uName;
            fingerprint = fPrint;
        }];
        if (username.length) {
            [super handleInvite:username fingerprint:fingerprint];
        }
        return true;
    }
    return false;
}


@end
