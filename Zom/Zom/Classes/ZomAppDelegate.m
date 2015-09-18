//
//  ZomAppDelegate.m
//  ChatSecure
//
//  Created by Christopher Ballinger on 6/10/15.
//  Copyright (c) 2015 Chris Ballinger. All rights reserved.
//

#import "ZomAppDelegate.h"
#import "ZomTheme.h"

@implementation ZomAppDelegate

#pragma mark - Theming

- (Class) themeClass {
    return [ZomTheme class];
}

@end
