//
//  OTRAssets+ZomLanguageHandling.h
//  Zom
//
//  Created by N-Pex on 2016-04-18.
//
//

#import <OTRAssets/OTRAssets.h>

@interface OTRAssets (ZomLanguageHandling)
+ (void) setupLanguageHandling;
+ (NSBundle*) zom_resourcesBundle;
@end
@interface NSBundle (ZomLanguageHandling)
+ (void) setupLanguageHandling;
+ (void) setLanguage:(NSString *)language;
+ (void) setBundle:(NSBundle *)main toLanguage:(NSString *)language;
+ (NSBundle*) zom_mainBundle;
@end
