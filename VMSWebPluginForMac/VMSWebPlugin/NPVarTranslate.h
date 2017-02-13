//
//  NPVarTranslate.h
//  VMSWebPlugin
//
//  Created by mac_dev on 15/11/9.
//  Copyright (c) 2015年 mac_dev. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <WebKit/nptypes.h>
#import <WebKit/npruntime.h>

void utf8StringFromNPString(char *dst,int dstLen,NPString src);
void szToNPVar(const char *sz,NPVariant *npVar);