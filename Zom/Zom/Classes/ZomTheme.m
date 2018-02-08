//
//  ZomTheme.m
//  ChatSecure
//
//  Created by Christopher Ballinger on 6/10/15.
//  Copyright (c) 2015 Chris Ballinger. All rights reserved.
//

#import "ZomTheme.h"
#import "Zom-Swift.h"
#import "ZomOverrides.h"

#define DEFAULT_ZOM_COLOR @"#FFE7275A"

@implementation ZomTheme

- (instancetype) init {
    if (self = [super init]) {
        UIColor *themeColor = [ZomTheme colorWithHexString:DEFAULT_ZOM_COLOR];
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSString *themeColorString = [defaults stringForKey:@"zom_ThemeColor"];
        if (themeColorString != nil) {
            themeColor = [ZomTheme colorWithHexString:themeColorString];
        }
        self.lightThemeColor = [ZomTheme colorWithHexString:@"#fff1f2f3"];
        self.mainThemeColor = themeColor;
        self.buttonLabelColor = [UIColor whiteColor];
    }
    return self;
}

/** Set global app appearance via UIAppearance */
- (void) setupGlobalTheme {
    [[UIView appearance] setTintColor:self.mainThemeColor];
    
    [[UINavigationBar appearance] setTranslucent:NO];
    [[UINavigationBar appearance] setTintColor:[UIColor whiteColor]];
    [[UINavigationBar appearance] setBarTintColor:self.mainThemeColor];
    [[UINavigationBar appearance] setBackgroundColor:self.mainThemeColor];
    // On iOS 11 bar button items are descendants of button...
    [[UIButton appearanceWhenContainedIn:UINavigationBar.class, nil] setTintColor:[UIColor whiteColor]];
    [[UITabBar appearance] setTintColor:[UIColor whiteColor]];
    [[UITabBar appearance] setBarTintColor:self.mainThemeColor];
    [[UITabBar appearance] setBackgroundColor:self.mainThemeColor];
    [[UINavigationBar appearance] setTitleTextAttributes:@{
                                                           NSForegroundColorAttributeName: [UIColor whiteColor]
                                                           }];
    [[UIBarButtonItem appearance] setTitleTextAttributes:@{
                                                           NSForegroundColorAttributeName: [UIColor whiteColor]
                                                           } forState:UIControlStateNormal];
    [[UITableView appearance] setBackgroundColor:self.lightThemeColor];
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
    [[UISwitch appearance] setOnTintColor:self.mainThemeColor];
    [[UILabel appearanceWhenContainedIn:ZomTableViewSectionHeader.class, nil] setTextColor:self.mainThemeColor];

    [[UIButton appearanceWhenContainedIn:UITableView.class, nil] setBackgroundColor:self.mainThemeColor];
    [[UIButton appearanceWhenContainedIn:UITableView.class, nil] setTintColor:[UIColor whiteColor]];
    [[UIButton appearanceWhenContainedIn:UITableViewCell.class, UITableView.class, nil] setBackgroundColor:nil];
    [[UIButton appearanceWhenContainedIn:UITableViewCell.class, UITableView.class, nil] setTintColor:nil];
    
    // Migration button style
    [[UIButton appearanceWhenContainedIn:UIView.class, UITableView.class, ZomConversationViewController.class, nil] setBackgroundColor:UIColor.clearColor];
    [[UIButton appearanceWhenContainedIn:UIView.class, UITableView.class, ZomConversationViewController.class, nil] setTintColor:self.mainThemeColor];

    // Group compose cell button
    [[UIButton appearanceWhenContainedIn:OTRComposeGroupBuddyCell.class, UICollectionView.class, UITableView.class, UIViewController.class, nil] setBackgroundColor:UIColor.clearColor];
    [[UIButton appearanceWhenContainedIn:OTRComposeGroupBuddyCell.class, UICollectionView.class, UITableView.class, UIViewController.class, nil] setTintColor:UIColor.lightGrayColor];
    
    // Checkmark icon in group compose view
    [[UIImageView appearanceWhenContainedIn: OTRBuddyInfoCheckableCell.class, UITableView.class, UIViewController.class, nil] setTintColor:self.mainThemeColor];

    // Group compose QR button
   [[UIButton appearanceWhenContainedIn:UIView.class, UITableView.class, ZomComposeGroupViewController.class, nil] setBackgroundColor:UIColor.whiteColor];
    [[UIButton appearanceWhenContainedIn:UIView.class, UITableView.class, ZomComposeGroupViewController.class, nil] setTintColor:UIColor.blackColor];
    
    // Buttons on photo overlay
    [[UIBarButtonItem appearanceWhenContainedIn:UIToolbar.class, UIView.class, ZomPhotosViewController.class, nil] setTintColor:UIColor.whiteColor];
    [[UIButton appearanceWhenContainedIn:UIToolbar.class, UIView.class, ZomPhotosViewController.class, nil] setTintColor:UIColor.whiteColor];
    UIColor *photosBarColor = [[UIColor blackColor] colorWithAlphaComponent:0.7];
    [[UINavigationBar appearanceWhenContainedIn:ZomPhotosViewController.class, nil] setTintColor:[UIColor whiteColor]];
    [[UINavigationBar appearanceWhenContainedIn:ZomPhotosViewController.class, nil] setTranslucent:YES];
    [[UINavigationBar appearanceWhenContainedIn:ZomPhotosViewController.class, nil] setBarTintColor:photosBarColor];
    [[UINavigationBar appearanceWhenContainedIn:ZomPhotosViewController.class, nil] setBackgroundColor:photosBarColor];
    
    UIPageControl *pageControl = [UIPageControl appearance];
    pageControl.pageIndicatorTintColor = self.mainThemeColor;
    pageControl.currentPageIndicatorTintColor = [UIColor blackColor];
    pageControl.backgroundColor = [UIColor whiteColor];
}

+ (UIImage *)imageFromColor:(UIColor *)color {
    CGRect rect = CGRectMake(0, 0, 1, 1);
    UIGraphicsBeginImageContext(rect.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context, [color CGColor]);
    CGContextFillRect(context, rect);
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

+ (UIColor*) colorWithHexString:(NSString*)hexColorString
{
    NSScanner *scanner = [NSScanner scannerWithString:hexColorString];
    [scanner setScanLocation:1];
    unsigned hex;
    if (![scanner scanHexInt:&hex]) return nil;
    int a = (hex >> 24) & 0xFF;
    int r = (hex >> 16) & 0xFF;
    int g = (hex >> 8) & 0xFF;
    int b = (hex) & 0xFF;
    return [UIColor colorWithRed:r / 255.0f green:g / 255.0f blue:b / 255.0f alpha:a / 255.0f];
}

+ (NSString *) hexStringWithColor:(UIColor*)color
{
    const CGFloat *components = CGColorGetComponents(color.CGColor);
    CGFloat r = components[0];
    CGFloat g = components[1];
    CGFloat b = components[2];
    CGFloat a = components[3];
    return [NSString stringWithFormat:@"#%02lX%02lX%02lX%02lX",
            lroundf(a * 255),
            lroundf(r * 255),
            lroundf(g * 255),
            lroundf(b * 255)];
}

-(void) selectMainThemeColor:(UIColor *)color {
    self.mainThemeColor = color;
    [self setupGlobalTheme];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setValue:[ZomTheme hexStringWithColor:color] forKey:@"zom_ThemeColor"];
}

#pragma mark - Overrides

- (__kindof UIViewController*) conversationViewController
{
    return [[ZomConversationViewController alloc] init];
}

- (__kindof JSQMessagesViewController *) messagesViewController
{
    return [ZomMessagesViewController messagesViewController];
}

- (__kindof UIViewController *) composeViewController
{
    return [[ZomComposeViewController alloc] init];
}

- (__kindof UIViewController* ) inviteViewControllerForAccount:(OTRAccount*)account
{
    return [[ZomInviteViewController alloc] initWithAccount:account];
}

- (UIViewController *)accountDetailViewControllerForAccount:(OTRXMPPAccount *)account xmpp:(OTRXMPPManager *)xmpp longLivedReadConnection:(YapDatabaseConnection *)longLivedReadConnection writeConnection:(YapDatabaseConnection *)writeConnection {
        return [[ZomAccountDetailViewController alloc] initWithAccount:account xmpp:xmpp longLivedReadConnection:longLivedReadConnection writeConnection:writeConnection];
}

/** Returns new instance. Override this in subclass to use a different settings view controller class */
- (__kindof UIViewController *) settingsViewController {
    ZomSettingsViewController *svc = [[ZomSettingsViewController alloc] init];
    ZomSettingsManager *settingsManager = [[ZomSettingsManager alloc] init];
    svc.settingsManager = settingsManager;
    settingsManager.viewController = svc;
    return svc;
}

- (BOOL) enableOMEMO
{
    return YES;
}

@end
