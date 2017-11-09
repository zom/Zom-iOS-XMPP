//
//  OTRAssets+ZomLanguageHandling.m
//  Zom
//
//  Created by N-Pex on 2016-04-18.
//
//

#import "OTRAssets+ZomLanguageHandling.h"
#import <objc/runtime.h>
@import ChatSecureCore;

static const char _bundle=0;
static const char _language=1;

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
        OTRLanguageSetting *langSetting = (OTRLanguageSetting *)[[OTRSettingsManager new] settingForOTRSettingKey:kOTRSettingKeyLanguage];
        [NSBundle setBundle:bundle toLanguage:[langSetting value]];
    }
    return bundle;
}
@end

@implementation NSBundle (ZomLanguageHandling)
+ (void)setupLanguageHandling {
    Method origMethod = class_getClassMethod([NSBundle class], @selector(mainBundle));
    Method newMethod = class_getClassMethod([NSBundle class], @selector(zom_mainBundle));
    method_exchangeImplementations(origMethod, newMethod);
}

+ (void) setBundle:(NSBundle *)main toLanguage:(NSString *)language {
    NSString* mainLang=objc_getAssociatedObject(main, &_language);
    if (mainLang == nil || ![mainLang isEqualToString:language]) {
        NSString *bundleLanguage = language;
        if (bundleLanguage != nil && ([bundleLanguage isEqualToString:@"en"] || [bundleLanguage isEqualToString:kOTRDefaultLanguageLocale]))
            bundleLanguage = @"Base"; // English resources are here
        NSBundle *langBundle = (bundleLanguage ? [NSBundle bundleWithPath:[main pathForResource:bundleLanguage ofType:@"lproj"]] : nil);
        objc_setAssociatedObject(main, &_bundle, langBundle, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        objc_setAssociatedObject(main, &_language, language, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
}

+ (NSBundle *)zom_mainBundle {
    NSBundle *main = [NSBundle zom_mainBundle];
    if (main != nil && ![main isKindOfClass:[ZomLanguageAwareBundle class]]) {
        object_setClass(main,[ZomLanguageAwareBundle class]);
        OTRLanguageSetting *langSetting = (OTRLanguageSetting *)[[OTRSettingsManager new] settingForOTRSettingKey:kOTRSettingKeyLanguage];
        [NSBundle setBundle:main toLanguage:[langSetting value]];
    }
    return main;
}

+ (void)setLanguage:(NSString *)language {
    NSBundle *main = [NSBundle mainBundle];
    [NSBundle setBundle:main toLanguage:language];
    NSBundle *resources = [OTRAssets resourcesBundle];
    [NSBundle setBundle:resources toLanguage:language];
}

@end
