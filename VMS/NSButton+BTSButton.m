//
//  NSButton+BTSButton.m
//  VMS
//
//  Created by mac_dev on 15/6/19.
//  Copyright (c) 2015年 mac_dev. All rights reserved.
//

#import "NSButton+BTSButton.h"

@implementation NSButton (BTSButton)
- (NSColor *)titleColor
{
    NSColor *l_textColor = [NSColor controlTextColor];
    
    NSAttributedString *l_attributedTitle = [self attributedTitle];
    NSUInteger l_len = [l_attributedTitle length];
    
    if (l_len) {
        
        NSDictionary *l_attrs = [l_attributedTitle fontAttributesInRange:NSMakeRange(0, 1)];
        
        if (l_attrs) {
            l_textColor = [l_attrs objectForKey:NSForegroundColorAttributeName];
        }
    }
    
    return l_textColor;
}

- (void)setTitleColor :(NSColor *)a_textColor
{
    NSMutableAttributedString *l_attributedTitle = [[NSMutableAttributedString alloc] initWithAttributedString:[self attributedTitle]];
    
    NSUInteger l_len = [l_attributedTitle length];
    NSRange l_range = NSMakeRange(0, l_len);
    [l_attributedTitle addAttribute:NSForegroundColorAttributeName
                              value:a_textColor
                              range:l_range];
    [l_attributedTitle fixAttributesInRange:l_range];
    [self setAttributedTitle:l_attributedTitle];
}

@end
