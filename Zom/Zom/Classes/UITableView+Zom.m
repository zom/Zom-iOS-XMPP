//
//  UITableView+Zom.m
//  Zom
//
//  Created by N-Pex on 2016-05-17.
//
//

#import "UITableView+Zom.h"
#import <objc/runtime.h>
#import "Zom-Swift.h"

@implementation UITableView (Zom)
+ (void) zom_initialize {
    Method origMethod = class_getInstanceMethod([UITableView class], @selector(registerClass:forCellReuseIdentifier:));
    Method newMethod = class_getInstanceMethod([UITableView class], @selector(zom_registerClass:forCellReuseIdentifier:));
    method_exchangeImplementations(origMethod, newMethod);
}

- (void) zom_registerClass:(Class)cellClass forCellReuseIdentifier:(NSString *)identifier {
    if (cellClass == [OTRBuddyInfoCell class]) {
        cellClass = [ZomBuddyInfoCell class];
    }
    [self zom_registerClass:cellClass forCellReuseIdentifier:identifier];
}
@end
