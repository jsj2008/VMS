//
//  XMLHelper.m
//  VMS
//
//  Created by mac_dev on 2016/12/21.
//  Copyright © 2016年 mac_dev. All rights reserved.
//

#import "XMLHelper.h"

@implementation XMLHelper

+ (NSDictionary *)parserCGIXml :(NSString *)xml error :(NSError **)err
{
    TBXML *tbxml = [TBXML newTBXMLWithXMLString:xml error:err];
    NSError *error = *err;
    
    if (!error) {
        NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
        TBXMLElement *root = tbxml.rootXMLElement;
        TBXMLElement *child = root->firstChild;
        
        do {
            [dict setValue:[TBXML textForElement:child] forKey:[TBXML elementName:child]];
        } while (child = child->nextSibling,child);
        
        return [NSDictionary dictionaryWithDictionary:dict];
    }
    
    return nil;
}

@end
