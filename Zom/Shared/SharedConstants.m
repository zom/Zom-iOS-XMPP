//
//  SharedConstants.m
//  Zom
//
//  Created by Benjamin Erhart on 06.02.18.
//

#import "SharedConstants.h"

#define ZOM_MACRO_STRING_(m) #m
#define ZOM_MACRO_STRING(m) @ZOM_MACRO_STRING_(m)

NSString * const ZomAppGroupId = ZOM_MACRO_STRING(ZOM_APPLICATION_GROUP);
NSString * const ZomShareUrl = @"zom://share-extension";
NSString * const ZomShareFolder = @"share";
