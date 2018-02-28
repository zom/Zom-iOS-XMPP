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
@synthesize lightThemeColor = _lightThemeColor;
@synthesize mainThemeColor = _mainThemeColor;
@synthesize buttonLabelColor = _buttonLabelColor;

- (instancetype) init {
    if (self = [super init]) {
        UIColor *themeColor = [ZomTheme colorWithHexString:DEFAULT_ZOM_COLOR];
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSString *themeColorString = [defaults stringForKey:@"zom_ThemeColor"];
        if (themeColorString != nil) {
            themeColor = [ZomTheme colorWithHexString:themeColorString];
        }
        _lightThemeColor = [ZomTheme colorWithHexString:@"#fff1f2f3"];
        _mainThemeColor = themeColor;
        _buttonLabelColor = [UIColor whiteColor];
    }
    return self;
}

/** Set global app appearance via UIAppearance */
- (void) setupAppearance {
    [[UIView appearance] setTintColor:self.mainThemeColor];
    
    [[UINavigationBar appearance] setTranslucent:NO];
    [[UINavigationBar appearance] setTintColor:[UIColor whiteColor]];
    [[UINavigationBar appearance] setBarTintColor:self.mainThemeColor];
    [[UINavigationBar appearance] setBackgroundColor:self.mainThemeColor];
    // On iOS 11 bar button items are descendants of button...
    [[UIButton appearanceWhenContainedInInstancesOfClasses:@[UINavigationBar.class]] setTintColor:[UIColor whiteColor]];
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
    [[UILabel appearanceWhenContainedInInstancesOfClasses:@[ZomTableViewSectionHeader.class]] setTextColor:self.mainThemeColor];

    [[UIButton appearanceWhenContainedInInstancesOfClasses:@[UITableView.class]] setBackgroundColor:self.mainThemeColor];
    [[UIButton appearanceWhenContainedInInstancesOfClasses:@[UITableView.class]] setTintColor:[UIColor whiteColor]];
    [[UIButton appearanceWhenContainedInInstancesOfClasses:@[UITableViewCell.class, UITableView.class]] setBackgroundColor:nil];
    [[UIButton appearanceWhenContainedInInstancesOfClasses:@[UITableViewCell.class, UITableView.class]] setTintColor:nil];
    
    // Migration button style
    [[UIButton appearanceWhenContainedInInstancesOfClasses:@[UIView.class, UITableView.class, ZomConversationViewController.class]] setBackgroundColor:UIColor.clearColor];
    [[UIButton appearanceWhenContainedInInstancesOfClasses:@[UIView.class, UITableView.class, ZomConversationViewController.class]] setTintColor:self.mainThemeColor];

    // Group compose cell button
    [[UIButton appearanceWhenContainedInInstancesOfClasses:@[OTRComposeGroupBuddyCell.class, UICollectionView.class, UITableView.class, UIViewController.class]] setBackgroundColor:UIColor.clearColor];
    [[UIButton appearanceWhenContainedInInstancesOfClasses:@[OTRComposeGroupBuddyCell.class, UICollectionView.class, UITableView.class, UIViewController.class]] setTintColor:UIColor.lightGrayColor];
    
    // Checkmark icon in group compose view
    [[UIImageView appearanceWhenContainedInInstancesOfClasses:@[OTRBuddyInfoCheckableCell.class, UITableView.class, UIViewController.class]] setTintColor:self.mainThemeColor];

    // Group compose QR button
    [[UIButton appearanceWhenContainedInInstancesOfClasses:@[UIView.class, UITableView.class, ZomComposeGroupViewController.class]] setBackgroundColor:UIColor.whiteColor];
     [[UIButton appearanceWhenContainedInInstancesOfClasses:@[UIView.class, UITableView.class, ZomComposeGroupViewController.class]] setTintColor:UIColor.blackColor];
    
    // Buttons on photo overlay
    [[UIBarButtonItem appearanceWhenContainedInInstancesOfClasses:@[UIToolbar.class, UIView.class, ZomPhotosViewController.class]] setTintColor:UIColor.whiteColor];
    [[UIButton appearanceWhenContainedInInstancesOfClasses:@[UIToolbar.class, UIView.class, ZomPhotosViewController.class]] setTintColor:UIColor.whiteColor];
    UIColor *photosBarColor = [[UIColor blackColor] colorWithAlphaComponent:0.7];
    [[UINavigationBar appearanceWhenContainedInInstancesOfClasses:@[ZomPhotosViewController.class]] setTintColor:[UIColor whiteColor]];
    [[UINavigationBar appearanceWhenContainedInInstancesOfClasses:@[ZomPhotosViewController.class]] setTranslucent:YES];
    [[UINavigationBar appearanceWhenContainedInInstancesOfClasses:@[ZomPhotosViewController.class]] setBarTintColor:photosBarColor];
    [[UINavigationBar appearanceWhenContainedInInstancesOfClasses:@[ZomPhotosViewController.class]] setBackgroundColor:photosBarColor];
    
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
    _mainThemeColor = color;
    [self setupAppearance];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setValue:[ZomTheme hexStringWithColor:color] forKey:@"zom_ThemeColor"];
    [defaults synchronize];
}

#pragma mark - Overrides

- (__kindof UIViewController*) conversationViewController
{
    return [[ZomConversationViewController alloc] init];
}

- (__kindof UIViewController *) messagesViewController
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

- (UIViewController *)accountDetailViewControllerForAccount:(OTRXMPPAccount *)account xmpp:(OTRXMPPManager *)xmpp {
    DatabaseConnections *connections = OTRDatabaseManager.shared.connections;
    return [[ZomAccountDetailViewController alloc] initWithAccount:account xmpp:xmpp longLivedReadConnection:connections.longLivedRead readConnection:connections.read writeConnection:connections.write];
}

/** Returns new instance. Override this in subclass to use a different settings view controller class */
- (__kindof UIViewController *) settingsViewController {
    ZomSettingsViewController *svc = [[ZomSettingsViewController alloc] init];
    ZomSettingsManager *settingsManager = [[ZomSettingsManager alloc] init];
    svc.settingsManager = settingsManager;
    settingsManager.viewController = svc;
    return svc;
}

- (nonnull __kindof UIViewController *)keyManagementViewControllerForAccount:(nonnull OTRXMPPAccount *)account buddies:(nonnull NSArray<OTRXMPPBuddy *> *)buddies {
    // TODO: Return Zom's customized key management/verification screen
    DatabaseConnections *connections = OTRDatabaseManager.shared.connections;
    XLFormDescriptor *form = [KeyManagementViewController profileFormDescriptorForAccount:account buddies:buddies connection:connections.ui];
    KeyManagementViewController *keyVC = [[KeyManagementViewController alloc] initWithAccountKey:account.uniqueId connections:connections form:form];
    return keyVC;
}

@end
