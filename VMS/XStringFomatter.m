//
//  DeviceNameFomatter.m
//  VMS
//
//  Created by mac_dev on 15/9/15.
//  Copyright (c) 2015年 mac_dev. All rights reserved.
//

#import "XStringFomatter.h"


@implementation XStringFomatter

- (instancetype)init
{
    if (self = [super init]) {
        self.maxLength = INT_MAX;
        self.regex = @"^[a-zA-Z0-9]*$";
    }
    
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super initWithCoder:aDecoder]) {
        self.maxLength = INT_MAX;
        self.regex = @"^[a-zA-Z0-9]*$";
    }
    
    return self;
}

- (NSString *)stringForObjectValue:(id)obj
{
    return (NSString *)obj;
}

- (BOOL)getObjectValue :(out __autoreleasing id *)obj
             forString :(NSString *)string
      errorDescription :(out NSString *__autoreleasing *)error
{
    *obj = string;
    return YES;
}

- (BOOL)isPartialStringValid:(NSString *)partialString
            newEditingString:(NSString *__autoreleasing *)newString
            errorDescription:(NSString *__autoreleasing *)error
{
    if (partialString.length > self.maxLength) return NO;
    else {
        //判断是否包含字符集
        BOOL isMatched = self.charSet?
        [partialString rangeOfCharacterFromSet:self.charSet].location != NSNotFound :
        [partialString isMatchedByRegex:self.regex];
        
        return self.negate? !isMatched : isMatched;
    }
}
@end
