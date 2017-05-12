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
- (void) showSubscriptionRequestForBuddy:(NSDictionary*)userInfo;
@end

@interface OTRConversationViewController (Zom)
- (void) showOnboardingIfNeeded;
@end

@implementation ZomAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [OTRAssets setupLanguageHandling];
    [NSBundle setupLanguageHandling];
    [[NSUserDefaults standardUserDefaults] addObserver:self forKeyPath:kOTRSettingKeyLanguage options:NSKeyValueObservingOptionNew context:nil];
    [UITableView zom_initialize];

    // Auto-pin the home.zom.im cert
    //
    NSArray *storedCerts = [OTRCertificatePinning storedCertificatesWithHostName:@"home.zom.im"];
    if (storedCerts == nil || [storedCerts count] == 0) {
        NSArray *servers = [OTRXMPPServerInfo defaultServerList];
        for (OTRXMPPServerInfo *server in servers) {
            if ([[server server] isEqualToString:@"home.zom.im"]) {
                NSString *cert = [server certificate];
                NSData *temp = [[NSData alloc] initWithBase64EncodedString:cert options:0];
                SecCertificateRef ref = [OTRCertificatePinning certForData:temp];
                [OTRCertificatePinning addCertificate:ref withHostName:@"home.zom.im"];
                break;
            }
        }
    }
    
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
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Tabs" bundle:[NSBundle mainBundle]];
    self.mainTabViewController = [storyboard instantiateInitialViewController];
    
    UINavigationController *nav = (UINavigationController *)leadingViewController;
    [nav setViewControllers:[NSArray arrayWithObject:self.mainTabViewController]];
    [self.mainTabViewController didMoveToParentViewController:nav];
    
    UISplitViewController *ret = [super setupDefaultSplitViewControllerWithLeadingViewController:leadingViewController];
    
    [self.mainTabViewController createTabs]; // Only do this once the split view controller is created, we need that as a delegate
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
        __block XMPPJID *jid = nil;
        __block NSString *fingerprint = nil;
        NSString *otr = [OTRAccount fingerprintStringTypeForFingerprintType:OTRFingerprintTypeOTR];
        [url otr_decodeShareLink:^(XMPPJID * _Nullable inJid, NSArray<NSURLQueryItem*> * _Nullable queryItems) {
            jid = inJid;
            [queryItems enumerateObjectsUsingBlock:^(NSURLQueryItem * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                if ([obj.name isEqualToString:otr]) {
                    fingerprint = obj.value;
                    *stop = YES;
                }
            }];
        }];
        if (jid) {
            [OTRProtocolManager handleInviteForJID:jid otrFingerprint:fingerprint buddyAddedCallback:nil];
        }
        return true;
    }
    return false;
}

- (OTRAccount *)getDefaultAccount {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if ([defaults objectForKey:@"zom_DefaultAccount"] != nil) {
        NSString *accountUniqueId = [defaults objectForKey:@"zom_DefaultAccount"];
        
        __block OTRAccount *account = nil;
        [[OTRDatabaseManager sharedInstance].readOnlyDatabaseConnection readWithBlock:^(YapDatabaseReadTransaction * _Nonnull transaction) {
            account = [OTRAccount fetchObjectWithUniqueID:accountUniqueId transaction:transaction];
        }];
        if (account != nil) {
            return account;
        }
    }
    NSArray *accounts = [OTRAccountsManager allAccounts];
    if (accounts != nil && accounts.count > 0)
    {
        return (OTRAccount *)accounts[0];
    }
    return nil;
}


- (void)setDefaultAccount:(OTRAccount *)account {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if (account != nil) {
        [defaults setValue:account.uniqueId forKey:@"zom_DefaultAccount"];
    } else {
        [defaults removeObjectForKey:@"zom_DefaultAccount"];
    }
    [defaults synchronize];
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(__unused id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
    // Change language of main bundle resources
    OTRLanguageSetting *langSetting = (OTRLanguageSetting *)[[OTRSettingsManager new] settingForOTRSettingKey:kOTRSettingKeyLanguage];
    [NSBundle setLanguage:[langSetting value]];
    
    UIViewController *root = self.window.rootViewController;
    if ([root isKindOfClass:ZomCompactTraitViewController.class]) {
        root = ((ZomCompactTraitViewController*)root).childViewControllers[0];
    }
    if ([root isKindOfClass:UISplitViewController.class]) {
        root = ((UISplitViewController*)root).childViewControllers[0];
    }
    if ([root isKindOfClass:UINavigationController.class] &&
        [((UINavigationController *)root).viewControllers[0] isKindOfClass:ZomMainTabbedViewController.class]) {
        
        // Create new tabs controller
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Tabs" bundle:[NSBundle mainBundle]];
        ZomMainTabbedViewController *tabsController = [storyboard instantiateInitialViewController];
        UINavigationController *nav = (UINavigationController *)root;
        [nav setViewControllers:[NSArray arrayWithObject:tabsController]];
        [tabsController didMoveToParentViewController:nav];
        [tabsController createTabs];
        //ZomMainTabbedViewController *tabs = (ZomMainTabbedViewController *)(((UINavigationController *)root).viewControllers[0]);
        //[tabs reload];
    }
    //[self application:[UIApplication sharedApplication] didFinishLaunchingWithOptions:nil];
    //if ([change[NSKeyValueChangeNewKey] isEqual:[NSNull null]]) {
    //} else {
    //}
}

- (void) showSubscriptionRequestForBuddy:(NSDictionary*)userInfo {
    [super showSubscriptionRequestForBuddy:userInfo];
    [self.mainTabViewController setSelectedIndex:0]; // Select the conversations list
}

@end
