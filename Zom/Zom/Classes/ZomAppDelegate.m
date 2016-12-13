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
#import "OTRAssets+ZomLanguageHandling.h"
#import "UITableView+Zom.h"

@interface OTRAppDelegate (Zom)
- (void)handleInvite:(NSString *)jidString fingerprint:(NSString *)fingerprint;
- (UISplitViewController *)setupDefaultSplitViewControllerWithLeadingViewController:(nonnull UIViewController *)leadingViewController;
@end

@interface OTRConversationViewController (Zom)
- (void) showOnboardingIfNeeded;
@end

@implementation ZomAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [OTRAssets setupLanguageHandling];
    [UITableView zom_initialize];
    
    BOOL ret = [super application:application didFinishLaunchingWithOptions:launchOptions];
    if (ret) {
        // For iPads, conversation controller is not necessarily shown until we pull out the side pane. The problem is that
        // onboarding does not start until we do. We need to kick that code into action sooner on these devices.
        if (UI_USER_INTERFACE_IDIOM() != UIUserInterfaceIdiomPhone && ![self.window.rootViewController isKindOfClass:OTRDatabaseUnlockViewController.class]) {
            [self.conversationViewController showOnboardingIfNeeded];
        }
    }
    return ret;
}

- (UIViewController *)setupDefaultSplitViewControllerWithLeadingViewController:(nonnull UIViewController *)leadingViewController {
    
    /* Leading view controller is a NavController that contains the ConversationController */
    /* We want to replace the conversationController with a tab controller */
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Tabs" bundle:nil];
    ZomMainTabbedViewController *tabsController = [storyboard instantiateInitialViewController];
    
    UINavigationController *nav = (UINavigationController *)leadingViewController;
    [nav setViewControllers:[NSArray arrayWithObject:tabsController]];
    [tabsController didMoveToParentViewController:nav];
    
    UISplitViewController *ret = [super setupDefaultSplitViewControllerWithLeadingViewController:leadingViewController];
    
    [tabsController createTabs]; // Only do this once the split view controller is created, we need that as a delegate
    if (![ret isCollapsed]) {
        ZomCompactTraitViewController *compact = [ZomCompactTraitViewController new];
        [compact addChildViewController:ret];
        ret.view.frame = compact.view.frame;
        [compact.view addSubview:ret.view];
        [ret didMoveToParentViewController:compact];
        return compact;
    }
    return ret;
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url
  sourceApplication:(NSString *)sourceApplication annotation:(id)annotation
{
    BOOL ret = [super application:application openURL:url sourceApplication:sourceApplication annotation:annotation];
    if (ret == NO) {
        ret = ([self handleUniversalLink:url] == true);
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

- (OTRAccount *)getDefaultAccount {
    NSArray *accounts = [OTRAccountsManager allAccountsAbleToAddBuddies];
    if (accounts != nil && accounts.count > 0)
    {
        return (OTRAccount *)accounts[0];
    }
    return nil;
}

@end
