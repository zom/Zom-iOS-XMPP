//
//  ZomAppDelegate.m
//  ChatSecure
//
//  Created by Christopher Ballinger on 6/10/15.
//  Copyright (c) 2015 Chris Ballinger. All rights reserved.
//

#import "ZomAppDelegate.h"
#import "Zom-Swift.h"
#import <ChatSecureCore/NSURL+ChatSecure.h>
#import <ChatSecureCore/OTRAppDelegate.h>
#import "OTRAssets+ZomLanguageHandling.h"
#import "UITableView+Zom.h"
#import "ZomOverrides.h"
#import "SharedConstants.h"
@import MobileCoreServices;

@interface OTRAppDelegate (Zom)
- (void)handleInvite:(NSString *)jidString fingerprint:(NSString *)fingerprint;
- (UISplitViewController *)setupDefaultSplitViewControllerWithLeadingViewController:(nonnull UIViewController *)leadingViewController;
- (void) showSubscriptionRequestForBuddy:(NSDictionary*)userInfo;
@end

@implementation ZomAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [UIApplication swizzle];
    GlobalTheme.shared = [[ZomTheme alloc] init];
    [GlobalTheme.shared setupAppearance];
    [OTRAssets setupLanguageHandling];
    [NSBundle setupLanguageHandling];
    [[NSUserDefaults standardUserDefaults] addObserver:self forKeyPath:kOTRSettingKeyLanguage options:NSKeyValueObservingOptionNew context:nil];
    [UITableView zom_initialize];
    [OTRXMPPAccount swizzle];
    [OTRAccountMigrator swizzle];
    [OTRXMPPRoomManager swizzle];
    [OTRBaseLoginViewController swizzle];
    [ShareControllerURLSource swizzle];
    [OTRBuddy swizzle];
    
    // Auto-pin the home.zom.im cert
    //
    NSArray *servers = [OTRXMPPServerInfo defaultServerList];
    for (OTRXMPPServerInfo *server in servers) {
        if ([[server server] isEqualToString:@"home.zom.im"]) {
            NSString *certString = [server certificate];
            NSData *certData = [[NSData alloc] initWithBase64EncodedString:certString options:0];
            
            NSArray *storedCerts = [OTRCertificatePinning storedCertificatesWithHostName:@"home.zom.im"];
            
            // If we have not stored it, or if we have a diff (i.e. it
            // has been updated)
            BOOL foundIt = NO;
            if (storedCerts != nil) {
                for (NSData *cert in storedCerts) {
                    if ([cert isEqualToData:certData]) {
                        foundIt = YES;
                        break;
                    }
                }
            }
            if (!foundIt) {
                SecCertificateRef ref = [OTRCertificatePinning certForData:certData];
                [OTRCertificatePinning addCertificate:ref withHostName:@"home.zom.im"];
            }
            break;
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

    // ViewController in development
//    YapDatabaseConnection *db = [OTRDatabaseManager sharedInstance].uiConnection;
//    __block OTRBuddy *buddy = nil;
//    [db readWithBlock:^(YapDatabaseReadTransaction * _Nonnull transaction) {
//        buddy = (OTRBuddy *)[[transaction ext:OTRAllBuddiesDatabaseViewExtensionName]
//                             objectAtIndex:0 inGroup:OTRBuddyGroup];
//    }];
//
//    ZomVerificationViewController *vc = [[ZomVerificationViewController alloc] initWithBuddy:buddy];
//    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
//    self.window.rootViewController = nav;
    // END ViewController in development

    return ret;
}

- (UIViewController *)setupDefaultSplitViewControllerWithLeadingViewController:(nonnull UIViewController *)leadingViewController {
    
    /* Leading view controller is a NavController that contains the ConversationController */
    /* We want to replace the conversationController with a tab controller */
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Tabs" bundle:[NSBundle mainBundle]];
    self.mainTabViewController = [storyboard instantiateInitialViewController];
    
    UINavigationController *nav = [[ZomRootNavigationViewController alloc] initWithRootViewController:self.mainTabViewController];
    [self.mainTabViewController didMoveToParentViewController:nav];
    
    UISplitViewController *ret = [super setupDefaultSplitViewControllerWithLeadingViewController:nav];
    
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
    if (ret == NO) {
        // Shared audio/image file?
        NSError *error;
        NSFileManager *fm = NSFileManager.defaultManager;

        // Check if this comes from the new Share Extension.
        if ([[url absoluteString] isEqualToString:ZomShareUrl])
        {
            NSURL *sharePath = [[fm containerURLForSecurityApplicationGroupIdentifier:ZomAppGroupId]
                                URLByAppendingPathComponent:ZomShareFolder];

            NSArray *files = [fm contentsOfDirectoryAtURL:sharePath includingPropertiesForKeys:nil
                                                  options:0 error:nil];

            if (files && files.count > 0)
            {
                return [ZomImportManager.shared
                        handleImportWithUrl:files[0]
                        type:(__bridge NSString *)kUTTypeImage
                        viewController:[[self splitViewCoordinator] splitViewController]];
            }
        }

        // Check, if this comes from the e-mail attachment handler feature.
        else if ([url checkResourceIsReachableAndReturnError:&error]) {
            NSString *type;
            if ([url getResourceValue:&type forKey:NSURLTypeIdentifierKey error:&error]) {
                if (UTTypeConformsTo((__bridge CFStringRef _Nonnull)(type), kUTTypeAudio) || UTTypeConformsTo((__bridge CFStringRef _Nonnull)(type), kUTTypeImage) || UTTypeConformsTo((__bridge CFStringRef _Nonnull)(type), kUTTypeMovie)) {
                    return [ZomImportManager.shared handleImportWithUrl:url type:type viewController:[[self splitViewCoordinator] splitViewController]];
                }
            }
        }
    }
    return ret;
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
        [[OTRDatabaseManager sharedInstance].readConnection readWithBlock:^(YapDatabaseReadTransaction * _Nonnull transaction) {
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
    
    // Recreate the UI. Does this have unwanted side effects?
    //
    [super application:[UIApplication sharedApplication] didFinishLaunchingWithOptions:nil];
}

- (void) showSubscriptionRequestForBuddy:(NSDictionary*)userInfo {
    [super showSubscriptionRequestForBuddy:userInfo];
    [self.mainTabViewController setSelectedIndex:0]; // Select the conversations list
}

@end
