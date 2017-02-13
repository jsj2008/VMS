/*
 File: LiveNPObject.m
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
#import <Cocoa/Cocoa.h>
#import "LiveNPObject.h"
#import "../../WebPlugin/WebPlugin/Cocoa_VMSLivePluginImpl.h"

extern NPNetscapeFuncs* browser;

typedef struct {
    // Put the NPObject first so that casting from an NPObject to a
    // MovieNPObject works as expected.
    NPObject npObject;
    Cocoa_VMSLivePluginImpl *impl;
    NPObject *cbOnLoginCompleted;
    NPObject *cbOnNetDisconnect;
    NPObject *cbOnOpenVideo;
    NPObject *cbOnOpenAudio;
    NPObject *cbOnViewSelected;
    int cbId;
    int cbResult;
    NPP npp;
} LiveNPObject;

enum {
    LOGIN,
    LOGOFF,
    RELAYOUT,
    FULL_SCREEN,
    OPEN_VIDEO,
    CLOSE_VIDEO,
    SNAP_SHOT,
    OPEN_AUDIO,
    CLOSE_AUDIO,
    GET_CUR_VIEW_INFO,
    PTZ_CONTROLL,
    CLOSE_ALL_VIDEO,
    NUM_METHOD_IDENTIFIERS
};

static NPIdentifier methodIdentifiers[NUM_METHOD_IDENTIFIERS];
static const NPUTF8 *methodIdentifierNames[NUM_METHOD_IDENTIFIERS] = {
    "Login",
    "Logoff",
    "Relayout",
    "FullScreen",
    "OpenVideo",
    "CloseVideo",
    "Snapshot",
    "OpenAudio",
    "CloseAudio",
    "GetCurViewInfo",
    "PtzControll",
    "CloseAllVideo",
};


enum {
    ON_LOG_INCOMPLETED,
    ON_NET_DISCONNET,
    ON_OPEN_VIDEO,
    ON_OPEN_AUDIO,
    ON_VIEW_SELECTED,
    NUM_PROPERTY_IDENTIFIERS
};

static NPIdentifier propertyIdentifiers[NUM_METHOD_IDENTIFIERS];
static const NPUTF8 *propertyIdentifierNames[NUM_METHOD_IDENTIFIERS] = {
    "OnLoginCompleted",
    "OnNetDisconnect",
    "OnOpenVideo",
    "OnOpenAudio",
    "OnViewSelected",
};


static void initializeIdentifiers(void)
{
    static bool identifiersInitialized;
    if (identifiersInitialized)
        return;
    
    // Take all method identifier names and convert them to NPIdentifiers.
    browser->getstringidentifiers(methodIdentifierNames, NUM_METHOD_IDENTIFIERS, methodIdentifiers);
    browser->getstringidentifiers(propertyIdentifierNames,NUM_PROPERTY_IDENTIFIERS,propertyIdentifiers);
    //sLivePluginType_id = browser->getstringidentifier("PluginType");
    identifiersInitialized = true;
}



/*
 *LiveNPClass
 */
static NPObject *liveNPObjectAllocate(NPP npp, NPClass* theClass);
static void liveNPObjectDeallocate(NPObject *npObject);
static bool liveNPObjectHasMethod(NPObject *obj, NPIdentifier name);
static bool liveNPObjectInvoke(NPObject *npObject,NPIdentifier name,const NPVariant* args,uint32_t argCount,NPVariant* result);
static bool liveNPObjectHasProperty(NPObject *npobj, NPIdentifier name);
static bool liveNPObjectSetProperty(NPObject *npobj,NPIdentifier name,const NPVariant *value);
static bool liveNPObjectInvokeDefault(NPObject *npobj,const NPVariant *args,uint32_t argCount,NPVariant *result);
static NPClass liveNPClass = {
    NP_CLASS_STRUCT_VERSION,
    liveNPObjectAllocate, // NP_Allocate
    liveNPObjectDeallocate, // NP_Deallocate
    0, // NP_Invalidate
    liveNPObjectHasMethod, // NP_HasMethod
    liveNPObjectInvoke, // NP_Invoke
    liveNPObjectInvokeDefault, // NP_InvokeDefault
    liveNPObjectHasProperty, // NP_HasProperty
    0, // NP_GetProperty
    liveNPObjectSetProperty, // NP_SetProperty
    0, // NP_RemoveProperty
    0, // NP_Enumerate
    0, // NP_Construct
};


/*
 *Callback for plugin
 */
static void OnLoginCompleted(void *npobj,int error);
static void OnNetDisconnect(void *npobj);
static void OnOpenVideo(void *npobj,unsigned int vid, unsigned int result);
static void OnOpenAudio(void *npobj,unsigned int vid, unsigned int result);
static void OnViewSelected(void *npobj,int selectIndex);

static PluginCallbackFuncs callbackFuncs = {
    OnLoginCompleted,
    OnNetDisconnect,
    OnOpenVideo,
    OnOpenAudio,
    OnViewSelected,
    0,
};


static NPObject *liveNPObjectAllocate(NPP npp, NPClass* theClass)
{
    initializeIdentifiers();
    
    LiveNPObject *liveNPObject = (LiveNPObject *)malloc(sizeof(LiveNPObject));
    bzero(liveNPObject, sizeof(LiveNPObject));
    liveNPObject->cbId = -1;

    NSLog(@"Live NPObject allocate");
    return (NPObject *)liveNPObject;
}

static void liveNPObjectDeallocate(NPObject *npObject)
{
    LiveNPObject *liveNPObject = (LiveNPObject *)npObject;
    
    // Free the NPObject memory.
    [liveNPObject->impl release];
    free(liveNPObject);
    
    NSLog(@"Live NPObject deallocate");
}

static bool liveNPObjectHasMethod(NPObject *obj, NPIdentifier name)
{
    // Loop over all the method NPIdentifiers and see if we expose the given method.
    for (int i = 0; i < NUM_METHOD_IDENTIFIERS; i++) {
        if (name == methodIdentifiers[i])
            return true;
    }
    
    return false;
}

static bool liveNPObjectInvoke(NPObject *npObject,
                                NPIdentifier name,
                                const NPVariant* args,
                                uint32_t argCount,
                                NPVariant* result)
{
    LiveNPObject *liveNPObject = (LiveNPObject *)npObject;
    Cocoa_VMSLivePluginImpl *impl = liveNPObject->impl;
    
    if (name == methodIdentifiers[LOGIN]) {
        int port = 0;
        if(args[1].type == NPVariantType_Int32)
            port = args[1].value.intValue;
        else if(args[1].type == NPVariantType_String) {
            char portString[32];
            utf8StringFromNPString(portString,32,args[1].value.stringValue);
            port = atoi(portString);
        }
        else
            port = (int)args[1].value.doubleValue; //for chrome
        
        char server[16];
        char name[32];
        char psw[32];
        utf8StringFromNPString(server,16,args[0].value.stringValue);
        utf8StringFromNPString(name,32,args[2].value.stringValue);
        utf8StringFromNPString(psw,32,args[3].value.stringValue);
        
        int ret = [impl loginWithServer :server port :(int)port name :name pwd :psw];
        
        INT32_TO_NPVARIANT(ret, *result);
        return true;
    }
    
    if (name == methodIdentifiers[LOGOFF]) {
        [impl logoff];
        return true;
    }
    
    if (name == methodIdentifiers[RELAYOUT]) {
        int hcount;
        int vcount;
        
        if(args[0].type == NPVariantType_Int32)
            hcount = args[0].value.intValue;
        else if(args[0].type == NPVariantType_String) {
            char hcountString[16];
            utf8StringFromNPString(hcountString, 16, args[0].value.stringValue);
            hcount = atoi(hcountString);
        }
        
        else
            hcount = (int)args[0].value.doubleValue; //for chrome
        
        if(args[1].type == NPVariantType_Int32)
            vcount = args[1].value.intValue;
        else if(args[1].type == NPVariantType_String) {
            char vcountString[16];
            utf8StringFromNPString(vcountString, 16, args[1].value.stringValue);
            vcount = atoi(vcountString);
        }
        
        else
            vcount = (int)args[1].value.doubleValue; //for chrome
        [impl relayoutWithHCount:hcount vCount:vcount];
        return true;
    }
    
    if (name == methodIdentifiers[FULL_SCREEN]) {
        [impl fullScreen];
        return true;
    }
    
    if (name == methodIdentifiers[OPEN_VIDEO]) {
        char xml[256];
        utf8StringFromNPString(xml, 256, args[0].value.stringValue);
        const char *xmlRet = [impl openVideo:xml];
        char *returnStr = (char *)browser->memalloc(strlen(xmlRet) + 1);
        strcpy(returnStr, xmlRet);
        szToNPVar(returnStr, result);
        return true;
    }
    
    if (name == methodIdentifiers[CLOSE_VIDEO]) {
        const char *ret = [impl closeVideo];
        char *returnStr = (char *)browser->memalloc(strlen(ret) + 1);
        strcpy(returnStr, ret);
        szToNPVar(returnStr, result);
        return true;
    }
    
    if (name == methodIdentifiers[SNAP_SHOT]) {
        char xml[256];
        utf8StringFromNPString(xml, 256, args[0].value.stringValue);
        const char *ret = [impl snapShot:xml];
        char *returnStr = (char *)browser->memalloc(strlen(ret) + 1);
        strcpy(returnStr, ret);
        szToNPVar(returnStr, result);
        return true;
    }
    
    if (name == methodIdentifiers[OPEN_AUDIO]) {
        const char *ret = [impl openAudio];
        char *returnStr = (char *)browser->memalloc(strlen(ret) + 1);
        strcpy(returnStr, ret);
        szToNPVar(returnStr, result);
        return true;
    }
    
    if (name == methodIdentifiers[CLOSE_AUDIO]) {
        const char *ret = [impl closeAudio];
        char *returnStr = (char *)browser->memalloc(strlen(ret) + 1);
        strcpy(returnStr, ret);
        szToNPVar(returnStr, result);
        return true;
    }
    
    if (name == methodIdentifiers[GET_CUR_VIEW_INFO]) {
        const char *ret = [impl getCurViewInfo];
        char *returnStr = (char *)browser->memalloc(strlen(ret) + 1);
        strcpy(returnStr, ret);
        szToNPVar(returnStr, result);
        return true;
    }
    
    if (name == methodIdentifiers[PTZ_CONTROLL]) {
        char xml[256];
        utf8StringFromNPString(xml, 256, args[0].value.stringValue);
        [impl ptzControll:xml];
        return true;
    }
    
    if (name == methodIdentifiers[CLOSE_ALL_VIDEO]) {
        [impl closeAllVideo];
        return true;
    }
    return false;
}

static bool liveNPObjectInvokeDefault(NPObject *npobj,
                                      const NPVariant *args,
                                      uint32_t argCount,
                                      NPVariant *result)
{
    printf ("LiveScriptablePluginObject default method called!\n");
    
    char *copy = strdup("default method return val");
    szToNPVar(copy, result);
    return true;
}

static bool liveNPObjectHasProperty(NPObject *npobj, NPIdentifier name)
{
    for (int i = 0; i < NUM_PROPERTY_IDENTIFIERS; i++) {
        if (name == propertyIdentifiers[i])
            return true;
    }
    
    return false;
}

//绑定HTML设置的回调函数
static bool liveNPObjectSetProperty(NPObject *npobj,
                                    NPIdentifier name,
                                    const NPVariant *value)
{
    LiveNPObject *liveNPObject = (LiveNPObject *)npobj;
    
    if (name == propertyIdentifiers[ON_LOG_INCOMPLETED])
    {
        if (!liveNPObject->cbOnLoginCompleted)
            liveNPObject->cbOnLoginCompleted = browser->retainobject(NPVARIANT_TO_OBJECT(*value));
        
        return true;
    }
    
    if (name == propertyIdentifiers[ON_NET_DISCONNET])
    {
        if (!liveNPObject->cbOnNetDisconnect)
            liveNPObject->cbOnNetDisconnect = browser->retainobject(NPVARIANT_TO_OBJECT(*value));
        return true;
    }
    
    if (name == propertyIdentifiers[ON_OPEN_VIDEO]) {
        if (!liveNPObject->cbOnOpenVideo)
            liveNPObject->cbOnOpenVideo = browser->retainobject(NPVARIANT_TO_OBJECT(*value));
        return true;
    }
    
    if (name == propertyIdentifiers[ON_OPEN_AUDIO]) {
        if (!liveNPObject->cbOnOpenVideo)
            liveNPObject->cbOnOpenVideo = browser->retainobject(NPVARIANT_TO_OBJECT(*value));
        return true;
    }
    
    if (name == propertyIdentifiers[ON_VIEW_SELECTED]) {
        if (!liveNPObject->cbOnViewSelected)
            liveNPObject->cbOnViewSelected = browser->retainobject(NPVARIANT_TO_OBJECT(*value));
        return true;
    }
    return false;
}
   

static void loginCompleted(void *userData)
{
    LiveNPObject *liveNPObject = (LiveNPObject *)userData;
    if (liveNPObject->cbOnLoginCompleted) {
        NPVariant args[1];
        INT32_TO_NPVARIANT(liveNPObject->cbResult,args[0]);
        NPVariant result;
        browser->invokeDefault(liveNPObject->npp, liveNPObject->cbOnLoginCompleted, args, 1, &result);
        browser->releasevariantvalue(&result);
    }
}
                                                                    
static void netDisconnect(void *userData)
{
    LiveNPObject *liveNPObject = (LiveNPObject *)userData;
    if (liveNPObject->cbOnNetDisconnect) {
        NPVariant result;
        browser->invokeDefault(liveNPObject->npp, liveNPObject->cbOnNetDisconnect, NULL, 0, &result);
        browser->releasevariantvalue(&result);
    }
}

static void openVideo(void *userData)
{
    LiveNPObject *liveNPObject = (LiveNPObject *)userData;
    if (liveNPObject->cbOnOpenVideo) {
        NPVariant args[2];
        INT32_TO_NPVARIANT(liveNPObject->cbId,args[0]);
        INT32_TO_NPVARIANT(liveNPObject->cbResult,args[1]);
        NPVariant result;
        
        browser->invokeDefault(liveNPObject->npp, liveNPObject->cbOnOpenVideo, args, 2, &result);
        browser->releasevariantvalue(&result);
    }
}

static void openAudio(void *userData)
{
    LiveNPObject *liveNPObject = (LiveNPObject *)userData;
    if (liveNPObject->cbOnOpenAudio) {
        NPVariant args[2];
        INT32_TO_NPVARIANT(liveNPObject->cbId,args[0]);
        INT32_TO_NPVARIANT(liveNPObject->cbResult,args[1]);
        NPVariant result;
        
        browser->invokeDefault(liveNPObject->npp, liveNPObject->cbOnOpenAudio, args, 2, &result);
        browser->releasevariantvalue(&result);
    }
}

static void viewSelected(void *userData)
{
    LiveNPObject *liveNPObject = (LiveNPObject *)userData;
    if (liveNPObject->cbOnViewSelected) {
        NPVariant args[1];
        INT32_TO_NPVARIANT(liveNPObject->cbId,args[0]);
        NPVariant result;
        
        browser->invokeDefault(liveNPObject->npp, liveNPObject->cbOnViewSelected, args, 1, &result);
        browser->releasevariantvalue(&result);
    }
}


//Callback
static void OnLoginCompleted(void *npobj,int error)
{
    LiveNPObject *liveNPObject = (LiveNPObject *)npobj;
    liveNPObject->cbResult = error;
    //异步回调至浏览器主线程
    browser->pluginthreadasynccall(liveNPObject->npp, loginCompleted, liveNPObject);
    //NSLog(@"Live plugin on login completed,error = %d",error);
}

static void OnNetDisconnect(void *npobj)
{
    LiveNPObject *liveNPObject = (LiveNPObject *)npobj;
    browser->pluginthreadasynccall(liveNPObject->npp, netDisconnect, liveNPObject);
}
static void OnOpenVideo(void *npobj,unsigned int vid, unsigned int result)
{
    LiveNPObject *liveNPObject = (LiveNPObject *)npobj;
    liveNPObject->cbId = vid;
    liveNPObject->cbResult = result;
    browser->pluginthreadasynccall(liveNPObject->npp, openVideo, liveNPObject);
}
static void OnOpenAudio(void *npobj,unsigned int vid, unsigned int result)
{
    LiveNPObject *liveNPObject = (LiveNPObject *)npobj;
    liveNPObject->cbId = vid;
    liveNPObject->cbResult = result;
    browser->pluginthreadasynccall(liveNPObject->npp, openAudio, liveNPObject);
}
static void OnViewSelected(void *npobj,int selectIndex)
{
    LiveNPObject *liveNPObject = (LiveNPObject *)npobj;
    liveNPObject->cbId = selectIndex;
    browser->pluginthreadasynccall(liveNPObject->npp, viewSelected, liveNPObject);
}


//Public
NPObject *createLiveNPObject(NPP npp,Cocoa_VMSLivePluginImpl *impl)
{
    LiveNPObject *liveNPObject = (LiveNPObject *)browser->createobject(npp, &liveNPClass);
    
    liveNPObject->impl = [impl retain];
    liveNPObject->npp = npp;

    [impl setPluginCallbacks:&callbackFuncs userData:liveNPObject];
    return (NPObject *)liveNPObject;
}
