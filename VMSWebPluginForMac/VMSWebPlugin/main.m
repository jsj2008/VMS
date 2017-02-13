/*
 File: main.m
 Version: 1.0
 
 Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple
 Inc. ("Apple") in consideration of your agreement to the following
 terms, and your use, installation, modification or redistribution of
 this Apple software constitutes acceptance of these terms.  If you do
 not agree with these terms, please do not use, install, modify or
 redistribute this Apple software.
 
 In consideration of your agreement to abide by the following terms, and
 subject to these terms, Apple grants you a personal, non-exclusive
 license, under Apple's copyrights in this original Apple software (the
 "Apple Software"), to use, reproduce, modify and redistribute the Apple
 Software, with or without modifications, in source and/or binary forms;
 provided that if you redistribute the Apple Software in its entirety and
 without modifications, you must retain this notice and the following
 text and disclaimers in all such redistributions of the Apple Software.
 Neither the name, trademarks, service marks or logos of Apple Inc. may
 be used to endorse or promote products derived from the Apple Software
 without specific prior written permission from Apple.  Except as
 expressly stated in this notice, no other rights or licenses, express or
 implied, are granted by Apple herein, including but not limited to any
 patent rights that may be infringed by your derivative works or by other
 works in which the Apple Software may be incorporated.
 
 The Apple Software is provided by Apple on an "AS IS" basis.  APPLE
 MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION
 THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS
 FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND
 OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS.
 
 IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL
 OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION,
 MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED
 AND WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE),
 STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE
 POSSIBILITY OF SUCH DAMAGE.
 
 Copyright (C) 2011 Apple Inc. All Rights Reserved.
 
 */

#import <WebKit/npapi.h>
#import <WebKit/npfunctions.h>
#import <WebKit/npruntime.h>

#import <QuartzCore/QuartzCore.h>
#import <QTKit/QTKit.h>
#import "../../VidGridLayer/VidGridLayer/VidGridLayer.h"

#import "LiveNPObject.h"
#import "BackNPObject.h"
#import "VMSNPObject.h"
#import "../../WebPlugin/WebPlugin/Cocoa_VMSLivePluginImpl.h"
#import "../../WebPlugin/WebPlugin/Cocoa_VMSBackPluginImpl.h"
#import "../../WebPlugin/WebPlugin/PluginNotification.h"
#import "VMSPathManager.h"
const char* LIVE_MIME_DESC = "application/np-vms-live";
const char* BACK_MIME_DESC = "application/np-vms-back";

#define debug   1
// Browser function table
NPNetscapeFuncs* browser;

// Structure for per-instance storage
typedef struct PluginObject
{
    char mimetype[64];
    NPP npp;
    NPWindow window;
    VidGridLayer *gridLayer;
    // The NPObject for this scriptable object.
    NPObject *pluginNPObject;
    Cocoa_VMSPluginImpl *pluginImpl;
} PluginObject;

static void redirectConsoleLogToDocumentFolder();

NPError NPP_New(NPMIMEType pluginType, NPP instance, uint16_t mode, int16_t argc, char* argn[], char* argv[], NPSavedData* saved);
NPError NPP_Destroy(NPP instance, NPSavedData** save);
NPError NPP_SetWindow(NPP instance, NPWindow* window);
NPError NPP_NewStream(NPP instance, NPMIMEType type, NPStream* stream, NPBool seekable, uint16* stype);
NPError NPP_DestroyStream(NPP instance, NPStream* stream, NPReason reason);
int32_t NPP_WriteReady(NPP instance, NPStream* stream);
int32_t NPP_Write(NPP instance, NPStream* stream, int32_t offset, int32_t len, void* buffer);
void NPP_StreamAsFile(NPP instance, NPStream* stream, const char* fname);
void NPP_Print(NPP instance, NPPrint* platformPrint);
int16_t NPP_HandleEvent(NPP instance, void* event);
void NPP_URLNotify(NPP instance, const char* URL, NPReason reason, void* notifyData);
NPError NPP_GetValue(NPP instance, NPPVariable variable, void *value);
NPError NPP_SetValue(NPP instance, NPNVariable variable, void *value);

#pragma export on
// Mach-o entry points
NPError NP_Initialize(NPNetscapeFuncs *browserFuncs);
NPError NP_GetEntryPoints(NPPluginFuncs *pluginFuncs);
void NP_Shutdown(void);
#pragma export off

NPError NP_Initialize(NPNetscapeFuncs* browserFuncs)
{
    browser = browserFuncs;
    redirectConsoleLogToDocumentFolder();
    return NPERR_NO_ERROR;
}

NPError NP_GetEntryPoints(NPPluginFuncs* pluginFuncs)
{
    pluginFuncs->version = 11;
    pluginFuncs->size = sizeof(pluginFuncs);
    pluginFuncs->newp = NPP_New;
    pluginFuncs->destroy = NPP_Destroy;
    pluginFuncs->setwindow = NPP_SetWindow;
    pluginFuncs->newstream = NPP_NewStream;
    pluginFuncs->destroystream = NPP_DestroyStream;
    pluginFuncs->asfile = NPP_StreamAsFile;
    pluginFuncs->writeready = NPP_WriteReady;
    pluginFuncs->write = (NPP_WriteProcPtr)NPP_Write;
    pluginFuncs->print = NPP_Print;
    pluginFuncs->event = NPP_HandleEvent;
    pluginFuncs->urlnotify = NPP_URLNotify;
    pluginFuncs->getvalue = NPP_GetValue;
    pluginFuncs->setvalue = NPP_SetValue;
    
    return NPERR_NO_ERROR;
}

void NP_Shutdown(void)
{

}


static void handleMouseDown(PluginObject *obj, NPCocoaEvent *event)
{
    CGPoint point = CGPointMake(event->data.mouse.pluginX, 
                                // Flip the y coordinate
                                obj->window.height - event->data.mouse.pluginY);
    
    CALayer *mouseDownLayer = [obj->gridLayer hitTest:point];
    if ([mouseDownLayer isKindOfClass:[OpenGLVidGridLayer class]]) {
        OpenGLVidGridLayer *hittedLayer = (OpenGLVidGridLayer *)mouseDownLayer;
        obj->gridLayer.keyPort = hittedLayer.port;
    }
    if (event->data.mouse.clickCount == 2) {
//        id poster = (strcmp(obj->mimetype, LIVE_MIME_DESC) == 0)? obj->pluginImpl.livePluginImpl :
//        obj->pluginImpl.backPluginImpl;
        id poster = obj->pluginImpl;
        NSDictionary *userInfo = [[NSDictionary alloc] initWithObjectsAndKeys:mouseDownLayer,KEY_PLUGIN_MOUSE_DOWN_LAYER, nil];
        [[NSNotificationCenter defaultCenter] postNotificationName:PLUGIN_DOUBLE_CLICKED_NOTIFICATION
                                                            object:poster
                                                          userInfo:userInfo];
    }
    
    [obj->gridLayer setNeedsDisplay];
}


static int handleKeyDown(PluginObject *obj, NPCocoaEvent *event)
{
    return 1;
}

static void setupLayerHierarchy(PluginObject *obj)
{
    obj->gridLayer = [[VidGridLayer alloc] initWithCount:16];
   
    if (strcmp(obj->mimetype, LIVE_MIME_DESC) == 0)
        obj->pluginImpl = [[Cocoa_VMSLivePluginImpl alloc] initWithLayer:obj->gridLayer];
    else
        obj->pluginImpl = [[Cocoa_VMSBackPluginImpl alloc] initWithLayer:obj->gridLayer];
}

static void redirectConsoleLogToDocumentFolder()
{
    NSDate *now = [NSDate date];
    NSDateFormatter *fomatter = [[NSDateFormatter alloc] init];
    
    [fomatter setDateFormat:@"YYYY-MM-dd_HH:mm:ss"];
    
    NSString *fileName = [NSString stringWithFormat:@"vmsPluginConsole(%@).log",[fomatter stringFromDate:now]];
    
//    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
//                                                         NSUserDomainMask, YES);
//    NSString *documentsDirectory = [paths objectAtIndex:0];
    
    NSString *vmsWebLogsDir = [VMSPathManager vmsWebLogsDir];
    NSString *logPath = [vmsWebLogsDir stringByAppendingPathComponent:fileName];
    freopen([logPath fileSystemRepresentation],"a+",stderr);
}



NPError NPP_New(NPMIMEType pluginType,
                NPP instance,
                uint16_t mode,
                int16_t argc,
                char* argn[],
                char* argv[],
                NPSavedData* saved)
{
    // Create per-instance storage
    @try {
        
        PluginObject *obj = (PluginObject *)malloc(sizeof(PluginObject));
        bzero(obj, sizeof(PluginObject));
        
        obj->npp = instance;
        strcpy(obj->mimetype, pluginType);
        instance->pdata = obj;
        // Ask the browser if it supports the Core Animation drawing model
        NPBool supportsCoreAnimation;
        if (browser->getvalue(instance, NPNVsupportsCoreAnimationBool, &supportsCoreAnimation) != NPERR_NO_ERROR)
        supportsCoreAnimation = FALSE;
        
        if (!supportsCoreAnimation)
        return NPERR_INCOMPATIBLE_VERSION_ERROR;
        
        // If the browser supports the Core Animation drawing model, enable it.
        browser->setvalue(instance, NPPVpluginDrawingModel, (void *)NPDrawingModelCoreAnimation);
        
        // If the browser supports the Cocoa event model, enable it.
        NPBool supportsCocoa;
        if (browser->getvalue(instance, NPNVsupportsCocoaBool, &supportsCocoa) != NPERR_NO_ERROR)
        supportsCocoa = FALSE;
        
        if (!supportsCocoa)
        return NPERR_INCOMPATIBLE_VERSION_ERROR;
        
        browser->setvalue(instance, NPPVpluginEventModel, (void *)NPEventModelCocoa);
        
        NSLog(@"Running NPP_New,type %s",pluginType);
    }
    @catch (NSException *exception) {
        NSLog(@"NPP_New exception happen: %@",exception);
    }
    
    
    return NPERR_NO_ERROR;
}



NPError NPP_Destroy(NPP instance, NPSavedData** save)
{
    @try {
        PluginObject *obj = (PluginObject *)instance->pdata;
        
        if (obj->pluginNPObject)
            browser->releaseobject(obj->pluginNPObject);
        
        [obj->gridLayer release];
        [obj->pluginImpl release];
        
        free(obj);
        NSLog(@"Running NPP_Destroy,type %s",obj->mimetype);
    }
    @catch (NSException *exception) {
        NSLog(@"NPP_Destroy exception happen: %@",exception);
    }
    
    return NPERR_NO_ERROR;
}

NPError NPP_SetWindow(NPP instance, NPWindow* window)
{
    PluginObject *obj = (PluginObject *)instance->pdata;
    obj->window = *window;
    
    return NPERR_NO_ERROR;
}



NPError NPP_NewStream(NPP instance, NPMIMEType type, NPStream* stream, NPBool seekable, uint16* stype)
{
    *stype = NP_ASFILEONLY;
    return NPERR_NO_ERROR;
}

NPError NPP_DestroyStream(NPP instance, NPStream* stream, NPReason reason)
{return NPERR_NO_ERROR;}

int32_t NPP_WriteReady(NPP instance, NPStream* stream)
{return 0;}

int32_t NPP_Write(NPP instance, NPStream* stream, int32_t offset, int32_t len, void* buffer)
{return 0;}

void NPP_StreamAsFile(NPP instance, NPStream* stream, const char* fname)
{}

void NPP_Print(NPP instance, NPPrint* platformPrint)
{}

int16_t NPP_HandleEvent(NPP instance, void* event)
{
    PluginObject *obj = (PluginObject *)instance->pdata;
    NPCocoaEvent *cocoaEvent = (NPCocoaEvent *)event;
    
    switch (cocoaEvent->type) {
        case NPCocoaEventMouseDown:
            handleMouseDown(obj, cocoaEvent);
            return 1;
        case NPCocoaEventKeyDown:
            return handleKeyDown(obj, cocoaEvent);
        default:
            return 0;
    }
    
    return 0;
}


void NPP_URLNotify(NPP instance, const char* url, NPReason reason, void* notifyData)
{
    if(instance == NULL)
        return;
}

NPError NPP_GetValue(NPP instance, NPPVariable variable, void *value)
{
    PluginObject *obj = (PluginObject *)instance->pdata;
    
    switch (variable) {
        case NPPVpluginCoreAnimationLayer:
            if (!obj->gridLayer)
                setupLayerHierarchy(obj);
            
            *(CALayer **)value = obj->gridLayer;
            return NPERR_NO_ERROR;
            
        case NPPVpluginScriptableNPObject:
            if (!obj->pluginImpl)
                return NPERR_GENERIC_ERROR;
            if (!obj->pluginNPObject) {
                //obj->pluginNPObject = createVMSNPObject(instance, obj->pluginImpl);
                if (0 == strcmp(obj->mimetype, LIVE_MIME_DESC)) {
                    obj->pluginNPObject = createLiveNPObject(instance, (Cocoa_VMSLivePluginImpl *)obj->pluginImpl);
                } else if (0 == strcmp(obj->mimetype, BACK_MIME_DESC)) {
                    obj->pluginNPObject = createBackNPObject(instance, (Cocoa_VMSBackPluginImpl *)obj->pluginImpl);
                }
            }
            
            
            // Create the movie NPObject if necessary.
            // The NPAPI standard specifies that a retained NPObject should be returned.
            *(NPObject **)value = obj->pluginNPObject;
            browser->retainobject(obj->pluginNPObject);
            
            NSLog(@"Get Plugin Scriptable npobject");
            return NPERR_NO_ERROR;

        default:
            return NPERR_GENERIC_ERROR;
    }
}

NPError NPP_SetValue(NPP instance, NPNVariable variable, void *value)
{
    return NPERR_GENERIC_ERROR;
}


