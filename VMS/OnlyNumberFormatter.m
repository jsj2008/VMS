//
//  OnlyNumberFormatter.m
//  VMS
//
//  Created by mac_dev on 15/9/15.
//  Copyright (c) 2015年 mac_dev. All rights reserved.
//

#import "OnlyNumberFormatter.h"

@implementation OnlyNumberFormatter

- (BOOL)isPartialStringValid:(NSString *)partialString
            newEditingString:(NSString *__autoreleasing *)newString
            errorDescription:(NSString *__autoreleasing *)error
{
    if (newString) *newString = nil;
    if (error) *error = nil;
    
    static NSCharacterSet *nonDecimalCharacters = nil;
    if (!nonDecimalCharacters)
        nonDecimalCharacters = [[NSCharacterSet decimalDigitCharacterSet] invertedSet];
    if ([partialString length] == 0) return YES;
    else if ([partialString rangeOfCharacterFromSet:nonDecimalCharacters].location != NSNotFound) return NO;
    
    return YES;
}

@end
