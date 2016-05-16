//
//  OTRAssets+ZomLanguageHandling.m
//  Zom
//
//  Created by N-Pex on 2016-04-18.
//
//

#import "OTRAssets+ZomLanguageHandling.h"
#import <objc/runtime.h>
#import <ChatSecureCore/OTRLanguageManager.h>

static const char _bundle=0;

@interface ZomLanguageAwareBundle : NSBundle
@end
@implementation ZomLanguageAwareBundle
-(NSString*)localizedStringForKey:(NSString *)key value:(NSString *)value table:(NSString *)tableName
{
    NSBundle* bundle=objc_getAssociatedObject(self, &_bundle);
    return bundle ? [bundle localizedStringForKey:key value:value table:tableName] : [super localizedStringForKey:key value:value table:tableName];
}
- (NSString *)pathForResource:(NSString *)name ofType:(NSString *)ext inDirectory:(NSString *)subpath forLocalization:(NSString *)localizationName {

    // English resourcers are found under "Base" for Zom
    if ([localizationName isEqualToString:@"en"])
        localizationName = @"Base";
    return [super pathForResource:name ofType:ext inDirectory:subpath forLocalization:localizationName];
}
@end

@implementation OTRAssets (ZomLanguageHandling)
+ (void)setupLanguageHandling {
    Method origMethod = class_getClassMethod([OTRAssets class], @selector(resourcesBundle));
    Method newMethod = class_getClassMethod([OTRAssets class], @selector(zom_resourcesBundle));
    method_exchangeImplementations(origMethod, newMethod);
}

+ (NSBundle *)zom_resourcesBundle {
    NSBundle *bundle = [OTRAssets zom_resourcesBundle];
    if (bundle != nil && ![bundle isKindOfClass:[ZomLanguageAwareBundle class]]) {
        object_setClass(bundle,[ZomLanguageAwareBundle class]);
    }
    return bundle;
}
@end