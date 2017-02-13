//
//  LiveNPObject.h
//  VMSWebPlugin
//
//  Created by mac_dev on 15/11/6.
//  Copyright (c) 2015年 mac_dev. All rights reserved.
//

#import <WebKit/npapi.h>
#import <WebKit/npfunctions.h>
#import <WebKit/npruntime.h>
#import "NPVarTranslate.h"


@class Cocoa_VMSLivePluginImpl;
NPObject *createLiveNPObject(NPP,Cocoa_VMSLivePluginImpl *);
