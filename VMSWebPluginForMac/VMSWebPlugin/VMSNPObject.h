//
//  VMSNPObject.h
//  VMSWebPlugin
//
//  Created by mac_dev on 15/12/15.
//  Copyright (c) 2015年 mac_dev. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <WebKit/npfunctions.h>
#import <WebKit/npruntime.h>
#import "NPVarTranslate.h"
#import "LiveNPObject.h"
#import "BackNPObject.h"

@class Cocoa_VMSPluginImpl;
NPObject *createVMSNPObject(NPP,Cocoa_VMSPluginImpl *);
