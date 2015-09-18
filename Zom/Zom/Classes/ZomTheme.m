//
//  ZomTheme.m
//  ChatSecure
//
//  Created by Christopher Ballinger on 6/10/15.
//  Copyright (c) 2015 Chris Ballinger. All rights reserved.
//

#import "ZomTheme.h"

@implementation ZomTheme

- (instancetype) init {
    if (self = [super init]) {
        self.lightThemeColor = [UIColor colorWithRed:255/255.0f green:221/255.0f blue:230/255.0f alpha:1.0f];
        self.mainThemeColor = [UIColor colorWithRed:231/255.0f green:39/255.0f blue:90/255.0f alpha:1.0f];
        self.buttonLabelColor = [UIColor whiteColor];
    }
    return self;
}

/** Set global app appearance via UIAppearance */
- (void) setupGlobalTheme {
    [[UINavigationBar appearance] setTranslucent:NO];
    [[UINavigationBar appearance] setTintColor:[UIColor whiteColor]];
    [[UINavigationBar appearance] setBarTintColor:self.mainThemeColor];
    [[UINavigationBar appearance] setBackgroundColor:self.mainThemeColor];
    [[UINavigationBar appearance] setTitleTextAttributes:@{
                                                           NSForegroundColorAttributeName: [UIColor whiteColor]
                                                           }];
    [[UITableView appearance] setBackgroundColor:self.lightThemeColor];
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
}

@end
