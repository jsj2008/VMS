//
//  VMSNPObject.m
//  VMSWebPlugin
//
//  Created by mac_dev on 15/12/15.
//  Copyright (c) 2015年 mac_dev. All rights reserved.
//

#import "VMSNPObject.h"
#import "../../WebPlugin/WebPlugin/Cocoa_VMSPluginImpl.h"
#import "../../WebPlugin/WebPlugin/Cocoa_VMSLivePluginImpl.h"
#import "../../WebPlugin/WebPlugin/Cocoa_VMSBackPluginImpl.h"


NPObject *createVMSNPObject(NPP npp,Cocoa_VMSPluginImpl *impl)
{
    if ([impl isKindOfClass:[Cocoa_VMSLivePluginImpl class]])
        return createLiveNPObject(npp, (Cocoa_VMSLivePluginImpl *)impl);
    else if ([impl isKindOfClass:[Cocoa_VMSBackPluginImpl class]])
        return createBackNPObject(npp, (Cocoa_VMSBackPluginImpl *)impl);
    
    return nil;
}

