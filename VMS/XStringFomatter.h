//
//  DeviceNameFomatter.h
//  VMS
//
//  Created by mac_dev on 15/9/15.
//  Copyright (c) 2015年 mac_dev. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "../RegexKit/RegexKit/RegexKitLite.h"

@interface XStringFomatter : NSFormatter

@property (assign) int maxLength;
@property (copy) NSString *regex;
@property (assign,getter=isNegate) BOOL negate;
@property (nonatomic,strong) NSCharacterSet *charSet;


- (BOOL)getObjectValue:(out __autoreleasing id *)obj
             forString:(NSString *)string
      errorDescription:(out NSString *__autoreleasing *)error;

- (BOOL)isPartialStringValid:(NSString *)partialString
            newEditingString:(NSString *__autoreleasing *)newString
            errorDescription:(NSString *__autoreleasing *)error;

- (NSString *)stringForObjectValue:(id)obj;
@end
