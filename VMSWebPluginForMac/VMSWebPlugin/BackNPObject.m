/*
 File: BackNPObject.m
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
#import "BackNPObject.h"
#import "../../WebPlugin/WebPlugin/Cocoa_VMSBackPluginImpl.h"

extern NPNetscapeFuncs* browser;
typedef struct {
    // Put the NPObject first so that casting from an NPObject to a
    // MovieNPObject works as expected.
    NPObject npObject;
    Cocoa_VMSBackPluginImpl *impl;
    NPObject *cbOnLoginCompleted;
    NPObject *cbOnNetDisconnect;
    NPObject *cbOnPlayProgress;
    int cbId;
    int cbResult;
    time_t cbTime;
    NPP npp;
} BackNPObject;

enum {
    LOGIN,
    LOGOFF,
    FULL_SCREEN,
    OPEN_VIDEO,
    CLOSE_VIDEO,
    SNAP_SHOT,
    OPEN_AUDIO,
    CLOSE_AUDIO,
    SET_PLAY_SPEED,
    SET_PLAY_BEGIN_TIME,
    NUM_METHOD_IDENTIFIERS
};


static NPIdentifier methodIdentifiers[NUM_METHOD_IDENTIFIERS];
static const NPUTF8 *methodIdentifierNames[NUM_METHOD_IDENTIFIERS] = {
    "Login",
    "Logoff",
    "FullScreen",
    "OpenVideo",
    "CloseVideo",
    "Snapshot",
    "OpenAudio",
    "CloseAudio",
    "SetPlaySpeed",
    "SetPlayBeginTime",
};

enum {
    ON_LOG_INCOMPLETED,
    ON_NET_DISCONNET,
    ON_PLAY_PROGRESS,
    NUM_PROPERTY_IDENTIFIERS
};

static NPIdentifier propertyIdentifiers[NUM_METHOD_IDENTIFIERS];
static const NPUTF8 *propertyIdentifierNames[NUM_METHOD_IDENTIFIERS] = {
    "OnLoginCompleted",
    "OnNetDisconnect",
    "OnPlayProgress",
};

static void initializeIdentifiers(void)
{
    static bool identifiersInitialized;
    if (identifiersInitialized)
        return;
    
    // Take all method identifier names and convert them to NPIdentifiers.
    browser->getstringidentifiers(methodIdentifierNames, NUM_METHOD_IDENTIFIERS, methodIdentifiers);
    browser->getstringidentifiers(propertyIdentifierNames,NUM_PROPERTY_IDENTIFIERS,propertyIdentifiers);
    //sbackPluginType_id = browser->getstringidentifier("PluginType");
    identifiersInitialized = true;
}


/*
 *BackNPClass
 */
static NPObject *backNPObjectAllocate(NPP npp, NPClass* theClass);
static void backNPObjectDeallocate(NPObject *npObject);
static bool backNPObjectHasMethod(NPObject *obj, NPIdentifier name);
static bool backNPObjectInvoke(NPObject *npObject,NPIdentifier name,const NPVariant* args,uint32_t argCount,NPVariant* result);
static bool backNPObjectHasProperty(NPObject *npobj, NPIdentifier name);
static bool backNPObjectSetProperty(NPObject *npobj,NPIdentifier name,const NPVariant *value);
static bool backNPObjectInvokeDefault(NPObject *npobj,const NPVariant *args,uint32_t argCount,NPVariant *result);
static NPClass backNPClass = {
    NP_CLASS_STRUCT_VERSION,
    backNPObjectAllocate, // NP_Allocate
    backNPObjectDeallocate, // NP_Deallocate
    0, // NP_Invalidate
    backNPObjectHasMethod, // NP_HasMethod
    backNPObjectInvoke, // NP_Invoke
    backNPObjectInvokeDefault, // NP_InvokeDefault
    backNPObjectHasProperty, // NP_HasProperty
    0, // NP_GetProperty
    backNPObjectSetProperty, // NP_SetProperty
    0, // NP_RemoveProperty
    0, // NP_Enumerate
    0, // NP_Construct
};


/*
 *Callback for plugin
 */
static void OnLoginCompleted(void *npobj,int error);
static void OnNetDisconnect(void *npobj);
static void OnPlayProgress(void *npobj,unsigned int vid, time_t cur_tm);

static PluginCallbackFuncs callbackFuncs = {
    OnLoginCompleted,
    OnNetDisconnect,
    0,
    0,
    0,
    OnPlayProgress,
};


static NPObject *backNPObjectAllocate(NPP npp, NPClass* theClass)
{
    initializeIdentifiers();
    
    BackNPObject *backNPObject = (BackNPObject *)malloc(sizeof(BackNPObject));
    bzero(backNPObject, sizeof(BackNPObject));
    backNPObject->cbId = -1;

    return (NPObject *)backNPObject;
}

static void backNPObjectDeallocate(NPObject *npObject)
{
    BackNPObject *backNPObject = (BackNPObject *)npObject;
    // Free the NPObject memory.
    [backNPObject->impl release];
    free(backNPObject);
}

static bool backNPObjectHasMethod(NPObject *obj, NPIdentifier name)
{
    // Loop over all the method NPIdentifiers and see if we expose the given method.
    for (int i = 0; i < NUM_METHOD_IDENTIFIERS; i++) {
        if (name == methodIdentifiers[i])
            return true;
    }
    
    return false;
}

static bool backNPObjectInvoke(NPObject *npObject,
                               NPIdentifier name,
                               const NPVariant* args,
                               uint32_t argCount,
                               NPVariant* result)
{
    BackNPObject *backNPObject = (BackNPObject *)npObject;
    Cocoa_VMSBackPluginImpl *impl = backNPObject->impl;
    
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
    
    if (name == methodIdentifiers[SET_PLAY_SPEED]) {
        [impl setPlaySpeed:(double)args[0].value.doubleValue];
        return true;
    }
    
    if (name == methodIdentifiers[SET_PLAY_BEGIN_TIME]) {
        int video_id = 0;
        if(args[0].type == NPVariantType_Int32)
            video_id = args[0].value.intValue;
        else
            video_id = (int)args[0].value.doubleValue; //for chrome
        char xml[256];
        utf8StringFromNPString(xml, 256, args[1].value.stringValue);
        [impl setPlayBeginTime:video_id xml:xml];
        return true;
    }
    return false;
}

static bool backNPObjectInvokeDefault(NPObject *npobj,
                                      const NPVariant *args,
                                      uint32_t argCount,
                                      NPVariant *result)
{
    printf ("backScriptablePluginObject default method called!\n");
    
    char *copy = strdup("default method return val");
    szToNPVar(copy, result);
    return true;
}


static bool backNPObjectHasProperty(NPObject *npobj, NPIdentifier name)
{
    for (int i = 0; i < NUM_PROPERTY_IDENTIFIERS; i++) {
        if (name == propertyIdentifiers[i])
            return true;
    }
    
    return false;
}

//绑定HTML设置的回调函数
static bool backNPObjectSetProperty(NPObject *npobj,
                                    NPIdentifier name,
                                    const NPVariant *value)
{
    BackNPObject *backNPObject = (BackNPObject *)npobj;
    
    if (name == propertyIdentifiers[ON_LOG_INCOMPLETED])
    {
        if (!backNPObject->cbOnLoginCompleted)
            backNPObject->cbOnLoginCompleted = browser->retainobject(NPVARIANT_TO_OBJECT(*value));
        
        return true;
    }
    
    if (name == propertyIdentifiers[ON_NET_DISCONNET])
    {
        if (!backNPObject->cbOnNetDisconnect)
            backNPObject->cbOnNetDisconnect = browser->retainobject(NPVARIANT_TO_OBJECT(*value));
        return true;
    }
    
   
    if (name == propertyIdentifiers[ON_PLAY_PROGRESS]) {
        if (!backNPObject->cbOnPlayProgress)
            backNPObject->cbOnPlayProgress = browser->retainobject(NPVARIANT_TO_OBJECT(*value));
        return true;
    }
    return false;
}


static void loginCompleted(void *userData)
{
    BackNPObject *backNPObject = (BackNPObject *)userData;
    if (backNPObject->cbOnLoginCompleted) {
        NPVariant args[1];
        INT32_TO_NPVARIANT(backNPObject->cbResult,args[0]);
        NPVariant result;
        browser->invokeDefault(backNPObject->npp, backNPObject->cbOnLoginCompleted, args, 1, &result);
        browser->releasevariantvalue(&result);
    }
}

static void netDisconnect(void *userData)
{
    BackNPObject *backNPObject = (BackNPObject *)userData;
    if (backNPObject->cbOnNetDisconnect) {
        NPVariant result;
        browser->invokeDefault(backNPObject->npp, backNPObject->cbOnNetDisconnect, NULL, 0, &result);
        browser->releasevariantvalue(&result);
    }
}

void FormatTime(time_t time1, char *szTime)
{
    struct tm tm1;
    
#ifdef _WIN32
    tm1 = *localtime(&time1);
#else
    localtime_r(&time1, &tm1 );
#endif
    sprintf( szTime, "%4.4d-%2.2d-%2.2d %2.2d:%2.2d:%2.2d",
            tm1.tm_year+1900, tm1.tm_mon+1, tm1.tm_mday,
            tm1.tm_hour, tm1.tm_min,tm1.tm_sec);
}

static void playProgress(void *userData)
{
    BackNPObject *backNPObject = (BackNPObject *)userData;
    if (backNPObject->cbOnNetDisconnect) {
        char timeStr[64];
        FormatTime(backNPObject->cbTime, timeStr);
        char xml[256];
        sprintf(xml, "<vms_plugin><vid>%d</vid><time>%s</time></vms_plugin>", backNPObject->cbId, timeStr);
        
        NPVariant args[1];
        szToNPVar(xml, args);
        NPVariant result;
        browser->invokeDefault(backNPObject->npp, backNPObject->cbOnPlayProgress, args, 1, &result);
        browser->releasevariantvalue(&result);
    }
}

//Callback
static void OnLoginCompleted(void *npobj,int error)
{
    BackNPObject *backNPObject = (BackNPObject *)npobj;
    backNPObject->cbResult = error;
    //异步回调至浏览器主线程
    browser->pluginthreadasynccall(backNPObject->npp, loginCompleted, backNPObject);
    //NSLog(@"Back plugin on login completed,error = %d",error);
}

static void OnNetDisconnect(void *npobj)
{
    BackNPObject *backNPObject = (BackNPObject *)npobj;
    browser->pluginthreadasynccall(backNPObject->npp, netDisconnect, backNPObject);
}

static void OnPlayProgress(void *npobj,unsigned int vid, time_t cur_tm)
{
    BackNPObject *backNPObject = (BackNPObject *)npobj;
    backNPObject->cbId = vid;
    backNPObject->cbTime = cur_tm;
    browser->pluginthreadasynccall(backNPObject->npp, playProgress, backNPObject);
}

//Public
NPObject *createBackNPObject(NPP npp,Cocoa_VMSBackPluginImpl *impl)
{
    BackNPObject *backNPObject = (BackNPObject *)browser->createobject(npp, &backNPClass);
    
    backNPObject->impl = [impl retain];
    backNPObject->npp = npp;
    
    [impl setPluginCallbacks:&callbackFuncs userData:backNPObject];
    return (NPObject *)backNPObject;
}