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

@interface OTRConversationViewController (Zom)
- (void) showOnboardingIfNeeded;
@end

@implementation ZomAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    BOOL ret = [super application:application didFinishLaunchingWithOptions:launchOptions];
    if (ret) {
        // For iPads, conversation controller is not necessarily shown until we pull out the side pane. The problem is that
        // onboarding does not start until we do. We need to kick that code into action sooner on these devices.
        if (UI_USER_INTERFACE_IDIOM() != UIUserInterfaceIdiomPhone && ![self.window.rootViewController isKindOfClass:OTRDatabaseUnlockViewController.class]) {
            [self.conversationViewController showOnboardingIfNeeded];
        }
//        UIViewController *root = self.window.rootViewController;
//        UITabBarController *tabController = [[UITabBarController alloc] init];
//        self.window.rootViewController = tabController;
//        root.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"1" image:[UIImage imageNamed:@"AppIcon.png"] tag:0];
//        
//        UIViewController *controller = [[ZomChooseAccountViewController alloc] init];
//        controller.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"2" image:[UIImage imageNamed:@"AppIcon.png"] tag:0];
//    
//        [tabController setViewControllers:[NSArray arrayWithObjects:root, controller, nil]];
    }
    return ret;
}

#pragma mark - Theming

- (Class) themeClass {
    return [ZomTheme class];
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
