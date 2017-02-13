//
//  XMLHelper.h
//  VMS
//
//  Created by mac_dev on 2016/12/21.
//  Copyright © 2016年 mac_dev. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "../TBXML/TBXML-Headers/TBXML.h"

#define KEY_XML_RESULT  @"result"
@interface XMLHelper : NSObject

+ (NSDictionary *)parserCGIXml :(NSString *)xml error :(NSError **)err;

@end
