//
//  ZomTheme.m
//  ChatSecure
//
//  Created by Christopher Ballinger on 6/10/15.
//  Copyright (c) 2015 Chris Ballinger. All rights reserved.
//

#import "ZomTheme.h"
#import "Zom-swift.h"

@implementation ZomTheme

- (instancetype) init {
    if (self = [super init]) {
        self.lightThemeColor = [ZomTheme colorWithHexString:@"#fff1f2f3"];
        self.mainThemeColor = [UIColor colorWithRed:231/255.0f green:39/255.0f blue:90/255.0f alpha:1.0f];
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

#pragma mark - Overrides

- (Class) conversationViewControllerClass
{
    return [ZomConversationViewController class];
}

- (Class) messagesViewControllerClass
{
    return [ZomMessagesViewController class];
}

- (Class) composeViewControllerClass
{
    return [ZomComposeViewController class];
}

@end
