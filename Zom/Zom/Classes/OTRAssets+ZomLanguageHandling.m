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
@end

@implementation OTRAssets (ZomLanguageHandling)
+ (void)setupLanguageHandling {
    Method origMethod = class_getClassMethod([OTRAssets class], @selector(resourcesBundle));
    Method newMethod = class_getClassMethod([OTRAssets class], @selector(zom_resourcesBundle));
    method_exchangeImplementations(origMethod, newMethod);
}

+ (NSBundle *)zom_resourcesBundle {
    NSBundle *bundle = [OTRAssets zom_resourcesBundle];
    if (bundle != nil) {
        object_setClass(bundle,[ZomLanguageAwareBundle class]);
        NSString *bundleLanguage = [OTRLanguageManager currentLocale];
        if ([bundleLanguage isEqualToString:@"en"])
            bundleLanguage = @"Base"; // English resources are here
        objc_setAssociatedObject(bundle, &_bundle, bundleLanguage ? [NSBundle bundleWithPath:[bundle pathForResource:bundleLanguage ofType:@"lproj"]] : nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return bundle;
}
@end