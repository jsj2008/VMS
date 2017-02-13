//
//  NPVarTranslate.m
//  VMSWebPlugin
//
//  Created by mac_dev on 15/11/9.
//  Copyright (c) 2015年 mac_dev. All rights reserved.
//

#import "NPVarTranslate.h"


void utf8StringFromNPString(char *dst,int dstLen,NPString src)
{
    int len = src.UTF8Length;
    if (len < dstLen) {
        memset(dst, 0, (len + 1));
        memcpy(dst, src.UTF8Characters, len);
    }
}

void szToNPVar(const char *sz,NPVariant *npVar)
{
    if (npVar) {
        npVar->type = NPVariantType_String;
        NPString str = {sz,(uint32_t)(strlen(sz))};
        npVar->value.stringValue = str;
    }
}