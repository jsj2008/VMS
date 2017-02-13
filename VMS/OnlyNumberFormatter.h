//
//  OnlyNumberFormatter.h
//  VMS
//
//  Created by mac_dev on 15/9/15.
//  Copyright (c) 2015年 mac_dev. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface OnlyNumberFormatter : NSNumberFormatter

- (BOOL)isPartialStringValid:(NSString *)partialString
            newEditingString:(NSString *__autoreleasing *)newString
            errorDescription:(NSString *__autoreleasing *)error;
@end
