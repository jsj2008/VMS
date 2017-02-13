/* -*- Mode: C++; tab-width: 2; indent-tabs-mode: nil; c-basic-offset: 2 -*- */
/* ***** BEGIN LICENSE BLOCK *****
 * Version: NPL 1.1/GPL 2.0/LGPL 2.1
 *
 * The contents of this file are subject to the Netscape Public License
 * Version 1.1 (the "License"); you may not use this file except in
 * compliance with the License. You may obtain a copy of the License at
 * http://www.mozilla.org/NPL/
 *
 * Software distributed under the License is distributed on an "AS IS" basis,
 * WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License
 * for the specific language governing rights and limitations under the
 * License.
 *
 * The Original Code is mozilla.org code.
 *
 * The Initial Developer of the Original Code is 
 * Netscape Communications Corporation.
 * Portions created by the Initial Developer are Copyright (C) 1998
 * the Initial Developer. All Rights Reserved.
 *
 * Contributor(s):
 *
 * Alternatively, the contents of this file may be used under the terms of
 * either the GNU General Public License Version 2 or later (the "GPL"), or 
 * the GNU Lesser General Public License Version 2.1 or later (the "LGPL"),
 * in which case the provisions of the GPL or the LGPL are applicable instead
 * of those above. If you wish to allow use of your version of this file only
 * under the terms of either the GPL or the LGPL, and not to allow others to
 * use your version of this file under the terms of the NPL, indicate your
 * decision by deleting the provisions above and replace them with the notice
 * and other provisions required by the GPL or the LGPL. If you do not delete
 * the provisions above, a recipient may use your version of this file under
 * the terms of any one of the NPL, the GPL or the LGPL.
 *
 * ***** END LICENSE BLOCK ***** */

//////////////////////////////////////////////////
//
// CLivePlugin class implementation
//

#include "LivePlugin.h"
#ifdef _WIN32
#include <windows.h>
#include <stdio.h>
#include <windowsx.h>
#endif


#include "ScriptablePluginObjectBase.h"
#include "config.h"
#include "net_io.h"
//#include "../../../libplay/libplay/avplay_sdk.h"
#include "../../libplay/libplay/avplay_sdk.h"
//#include "avplay_sdk.h"

#include "NPString.h"

#ifdef __APPLE__
#define LPCTSTR const char*
#endif

void PluginInit()
{
	static bool init = true;
	if(init)
	{
		net_io::instance().init();
		AVPLAY_Init();
		init = false;
	}
}

static NPIdentifier sLivePluginType_id;

class LiveConstructablePluginObject : public ScriptablePluginObjectBase
{
public:
  LiveConstructablePluginObject(NPP npp)
    : ScriptablePluginObjectBase(npp)
  {
  }

  virtual bool Construct(const NPVariant *args, uint32_t argCount,
                         NPVariant *result);
};

static NPObject *
AllocateConstructablePluginObject(NPP npp, NPClass *aClass)
{
  return new LiveConstructablePluginObject(npp);
}

DECLARE_NPOBJECT_CLASS_WITH_BASE(LiveConstructablePluginObject,
                                 AllocateConstructablePluginObject);

bool
LiveConstructablePluginObject::Construct(const NPVariant *args,
                                         uint32_t argCount,
                                         NPVariant *result)
{
    printf("Creating new LiveConstructablePluginObject!\n");
#ifdef __APPLE__
    NPNetscapeFuncs* browser = (NPNetscapeFuncs*)mNpp->ndata;
    NPObject *myobj = browser->createobject(mNpp, GET_NPOBJECT_CLASS(LiveConstructablePluginObject));
#endif
    
#ifdef _WIN32
    NPObject *myobj = NPN_CreateObject(mNpp, GET_NPOBJECT_CLASS(LiveConstructablePluginObject));
#endif
    
  if (!myobj)
    return false;

  OBJECT_TO_NPVARIANT(myobj, *result);

  return true;
}

class LiveScriptablePluginObject : public ScriptablePluginObjectBase
{
public:
#ifdef _WIN32
    LiveScriptablePluginObject(NPP npp)
    : ScriptablePluginObjectBase(npp), m_hWnd(0)
    {
        m_cbOnLoginCompleted = NULL;
        m_cbOnNetDisconnect = NULL;
        m_cbOnOpenVideo = NULL;
        m_cbOnOpenAudio = NULL;
        m_cbOnViewSelected = NULL;
    }
#endif
    
#ifdef __APPLE__
    LiveScriptablePluginObject(NPP npp)
    : ScriptablePluginObjectBase(npp), _pluginLayer(NULL)
    {
        m_cbOnLoginCompleted = NULL;
        m_cbOnNetDisconnect = NULL;
        m_cbOnOpenVideo = NULL;
        m_cbOnOpenAudio = NULL;
        m_cbOnViewSelected = NULL;
    }
#endif
	~LiveScriptablePluginObject();

  virtual bool HasMethod(NPIdentifier name);
  virtual bool HasProperty(NPIdentifier name);
  virtual bool GetProperty(NPIdentifier name, NPVariant *result);
	virtual bool SetProperty(NPIdentifier name, const NPVariant *value);
  virtual bool Invoke(NPIdentifier name, const NPVariant *args,
                      uint32_t argCount, NPVariant *result);
  virtual bool InvokeDefault(const NPVariant *args, uint32_t argCount,
                             NPVariant *result);

#ifdef _WIN32
    HWND m_hWnd;
#endif
    
#ifdef __APPLE__
    void *_pluginLayer;
#endif
	
	VMSLivePluginImpl* impl;
	NPObject *m_cbOnLoginCompleted;
	NPObject *m_cbOnNetDisconnect;
	NPObject *m_cbOnOpenVideo;
	NPObject *m_cbOnOpenAudio;
	NPObject *m_cbOnViewSelected;
};

static NPObject *
AllocateScriptablePluginObject(NPP npp, NPClass *aClass)
{
  return new LiveScriptablePluginObject(npp);
}

LiveScriptablePluginObject::~LiveScriptablePluginObject()
{
#ifdef _WIN32
    if(m_cbOnLoginCompleted)
        NPN_ReleaseObject(m_cbOnLoginCompleted);
    if(m_cbOnNetDisconnect)
        NPN_ReleaseObject(m_cbOnNetDisconnect);
    if(m_cbOnOpenVideo)
        NPN_ReleaseObject(m_cbOnOpenVideo);
    if(m_cbOnOpenAudio)
        NPN_ReleaseObject(m_cbOnOpenAudio);
    if(m_cbOnViewSelected)
        NPN_ReleaseObject(m_cbOnViewSelected);
#endif
    
#ifdef __APPLE__
    NPNetscapeFuncs* browser = (NPNetscapeFuncs*)mNpp->ndata;
    if(m_cbOnLoginCompleted)
        browser->releaseobject(m_cbOnLoginCompleted);
    if(m_cbOnNetDisconnect)
        browser->releaseobject(m_cbOnNetDisconnect);
    if(m_cbOnOpenVideo)
        browser->releaseobject(m_cbOnOpenVideo);
    if(m_cbOnOpenAudio)
        browser->releaseobject(m_cbOnOpenAudio);
    if(m_cbOnViewSelected)
        browser->releaseobject(m_cbOnViewSelected);
#endif
}

DECLARE_NPOBJECT_CLASS_WITH_BASE(LiveScriptablePluginObject,
                                 AllocateScriptablePluginObject);

bool
LiveScriptablePluginObject::HasMethod(NPIdentifier name)
{
#ifdef _WIN32
    char *pFunc = NPN_UTF8FromIdentifier(name);
#endif
    
#ifdef __APPLE__
    NPNetscapeFuncs* browser = (NPNetscapeFuncs*)mNpp->ndata;
    char *pFunc = browser->utf8fromidentifier(name);
#endif
	
	if(strcmp(pFunc, "Login") == 0)
	{
		return true;
	}
	else if(strcmp(pFunc, "Logoff") == 0)
	{
		return true;
	}
	else if(strcmp(pFunc, "Relayout") == 0)
	{
		return true;
	}
	else if(strcmp(pFunc, "FullScreen") == 0)
	{
		return true;
	}
	else if(strcmp(pFunc, "OpenVideo") == 0)
	{
		return true;
	}
	else if(strcmp(pFunc, "CloseVideo") == 0)
	{
		return true;
	}
	else if(strcmp(pFunc, "Snapshot") == 0)
	{
		return true;
	}
	else if(strcmp(pFunc, "OpenAudio") == 0)
	{
		return true;
	}
	else if(strcmp(pFunc, "CloseAudio") == 0)
	{
		return true;
	}
	else if(strcmp(pFunc, "GetCurViewInfo") == 0)
	{
		return true;
	}
	else if(strcmp(pFunc, "PtzControll") == 0)
	{
		return true;
	}
	else if(strcmp(pFunc, "CloseAllVideo") == 0)
	{
		return true;
	}
	return false;
}

bool
LiveScriptablePluginObject::HasProperty(NPIdentifier name)
{
#ifdef _WIN32
    char *pProp = NPN_UTF8FromIdentifier(name);
#endif
    
#ifdef __APPLE__
    NPNetscapeFuncs* browser = (NPNetscapeFuncs*)mNpp->ndata;
    char *pProp = browser->utf8fromidentifier(name);
#endif
	
	if(strcmp(pProp, "OnLoginCompleted") == 0)
	{
		return true;
	}
	else if(strcmp(pProp, "OnNetDisconnect") == 0)
	{
		return true;
	}
	else if(strcmp(pProp, "OnOpenVideo") == 0)
	{
		return true;
	}
	else if(strcmp(pProp, "OnOpenAudio") == 0)
	{
		return true;
	}
	else if(strcmp(pProp, "OnViewSelected") == 0)
	{
		return true;
	}
	return false;
}

bool
LiveScriptablePluginObject::GetProperty(NPIdentifier name, NPVariant *result)
{
    VOID_TO_NPVARIANT(*result);
#ifdef __APPLE__
    NPNetscapeFuncs* browser = (NPNetscapeFuncs*)mNpp->ndata;
    char *pProp = browser->utf8fromidentifier(name);
    if (name == sLivePluginType_id) {
        NPObject *myobj = browser->createobject(mNpp, GET_NPOBJECT_CLASS(LiveConstructablePluginObject));
        if (!myobj) return false;
        
        OBJECT_TO_NPVARIANT(myobj, *result);
        return true;
    }
#endif
#ifdef _WIN32
    char *pProp = NPN_UTF8FromIdentifier(name);
    if (name == sLivePluginType_id) {
        NPObject *myobj = NPN_CreateObject(mNpp, GET_NPOBJECT_CLASS(LiveConstructablePluginObject));
        if (!myobj) return false;

        OBJECT_TO_NPVARIANT(myobj, *result);
        return true;
    }
#endif
  return true;
}

bool
LiveScriptablePluginObject::SetProperty(NPIdentifier name,
                                        const NPVariant *value)
{
#ifdef _WIN32
    char *pProp = NPN_UTF8FromIdentifier(name);
    if(strcmp(pProp, "OnLoginCompleted") == 0)
    {
        if(m_cbOnLoginCompleted == NULL)
            m_cbOnLoginCompleted=NPN_RetainObject(NPVARIANT_TO_OBJECT(*value));
        return true;
    }
    else if(strcmp(pProp, "OnNetDisconnect") == 0)
    {
        if(m_cbOnNetDisconnect == NULL)
            m_cbOnNetDisconnect=NPN_RetainObject(NPVARIANT_TO_OBJECT(*value));
        return true;
    }
    else if(strcmp(pProp, "OnOpenVideo") == 0)
    {
        if(m_cbOnOpenVideo == NULL)
            m_cbOnOpenVideo=NPN_RetainObject(NPVARIANT_TO_OBJECT(*value));
        return true;
    }
    else if(strcmp(pProp, "OnOpenAudio") == 0)
    {
        if(m_cbOnOpenAudio == NULL)
            m_cbOnOpenAudio=NPN_RetainObject(NPVARIANT_TO_OBJECT(*value));
        return true;
    }
    else if(strcmp(pProp, "OnViewSelected") == 0)
    {
        if(m_cbOnViewSelected == NULL)
            m_cbOnViewSelected=NPN_RetainObject(NPVARIANT_TO_OBJECT(*value));
        return true;
    }
#endif
    
#ifdef __APPLE__
    NPNetscapeFuncs* browser = (NPNetscapeFuncs*)mNpp->ndata;
    char *pProp = browser->utf8fromidentifier(name);
    if(strcmp(pProp, "OnLoginCompleted") == 0)
    {
        if(m_cbOnLoginCompleted == NULL)
            m_cbOnLoginCompleted=browser->retainobject(NPVARIANT_TO_OBJECT(*value));
        return true;
    }
    else if(strcmp(pProp, "OnNetDisconnect") == 0)
    {
        if(m_cbOnNetDisconnect == NULL)
            m_cbOnNetDisconnect=browser->retainobject(NPVARIANT_TO_OBJECT(*value));
        return true;
    }
    else if(strcmp(pProp, "OnOpenVideo") == 0)
    {
        if(m_cbOnOpenVideo == NULL)
            m_cbOnOpenVideo=browser->retainobject(NPVARIANT_TO_OBJECT(*value));
        return true;
    }
    else if(strcmp(pProp, "OnOpenAudio") == 0)
    {
        if(m_cbOnOpenAudio == NULL)
            m_cbOnOpenAudio=browser->retainobject(NPVARIANT_TO_OBJECT(*value));
        return true;
    }
    else if(strcmp(pProp, "OnViewSelected") == 0)
    {
        if(m_cbOnViewSelected == NULL)
            m_cbOnViewSelected=browser->retainobject(NPVARIANT_TO_OBJECT(*value));
        return true;
    }
#endif
	return false;
}




bool
LiveScriptablePluginObject::Invoke(NPIdentifier name,
                                   const NPVariant *args,
                                   uint32_t argCount,
                                   NPVariant *result)
{
#ifdef _WIN32
    char *pFunc = NPN_UTF8FromIdentifier(name);
    if(strcmp(pFunc, "Login") == 0)
    {
        int port = 0;
        if(args[1].type == NPVariantType_Int32)
            port = args[1].value.intValue;
        else if(args[1].type == NPVariantType_String)
            port = atoi((LPCTSTR)CNPString(args[1].value.stringValue));
        else
            port = (int)args[1].value.doubleValue; //for chrome
        
        int ret = impl->login((LPCTSTR)CNPString(args[0].value.stringValue),
                              port,
                              (LPCTSTR)CNPString(args[2].value.stringValue),
                              (LPCTSTR)CNPString(args[3].value.stringValue));
        
        INT32_TO_NPVARIANT(ret, *result);
        return true;
    }
    else if(strcmp(pFunc, "Logoff") == 0)
    {
        impl->logoff();
        return true;
    }
    else if(strcmp(pFunc, "Relayout") == 0)
    {
        int hcount;
        int vcount;
        
        if(args[0].type == NPVariantType_Int32)
            hcount = args[0].value.intValue;
        else if(args[0].type == NPVariantType_String)
            hcount = atoi((LPCTSTR)CNPString(args[0].value.stringValue));
        else
            hcount = (int)args[0].value.doubleValue; //for chrome
        
        if(args[1].type == NPVariantType_Int32)
            vcount = args[1].value.intValue;
        else if(args[1].type == NPVariantType_String)
            vcount = atoi((LPCTSTR)CNPString(args[1].value.stringValue));
        else
            vcount = (int)args[1].value.doubleValue; //for chrome
        impl->Relayout(hcount, vcount);
        return true;
    }
    else if(strcmp(pFunc, "FullScreen") == 0)
    {
        impl->FullScreen();
        return true;
    }
    else if(strcmp(pFunc, "OpenVideo") == 0)
    {
        std::string ret = impl->OpenVideo((LPCTSTR)CNPString(args[0].value.stringValue));
        char* returnStr = (char*)NPN_MemAlloc(ret.length()+1);
        strcpy(returnStr, ret.c_str());
        STRINGZ_TO_NPVARIANT(returnStr, *result);
        return true;
    }
    else if(strcmp(pFunc, "CloseVideo") == 0)
    {
        std::string ret = impl->CloseVideo();
        char* returnStr = (char*)NPN_MemAlloc(ret.length()+1);
        strcpy(returnStr, ret.c_str());
        STRINGZ_TO_NPVARIANT(returnStr, *result);
        return true;
    }
    else if(strcmp(pFunc, "Snapshot") == 0)
    {
        std::string ret = impl->Snapshot((LPCTSTR)CNPString(args[0].value.stringValue));
        char* returnStr = (char*)NPN_MemAlloc(ret.length()+1);
        strcpy(returnStr, ret.c_str());
        STRINGZ_TO_NPVARIANT(returnStr, *result);
        return true;
    }
    else if(strcmp(pFunc, "OpenAudio") == 0)
    {
        std::string ret = impl->OpenAudio();
        char* returnStr = (char*)NPN_MemAlloc(ret.length()+1);
        strcpy(returnStr, ret.c_str());
        STRINGZ_TO_NPVARIANT(returnStr, *result);
        return true;
    }
    else if(strcmp(pFunc, "CloseAudio") == 0)
    {
        std::string ret = impl->CloseAudio();
        char* returnStr = (char*)NPN_MemAlloc(ret.length()+1);
        strcpy(returnStr, ret.c_str());
        STRINGZ_TO_NPVARIANT(returnStr, *result);
        return true;
    }
    else if(strcmp(pFunc, "GetCurViewInfo") == 0)
    {
        std::string ret = impl->GetCurViewInfo();
        char* returnStr = (char*)NPN_MemAlloc(ret.length()+1);
        strcpy(returnStr, ret.c_str());
        STRINGZ_TO_NPVARIANT(returnStr, *result);
        return true;
    }
    else if(strcmp(pFunc, "PtzControll") == 0)
    {
        impl->PtzControll((LPCTSTR)CNPString(args[0].value.stringValue));
        return true;
    }
    else if(strcmp(pFunc, "CloseAllVideo") == 0)
    {
        impl->CloseAllVideo();
        return true;
    }
#endif
    
#ifdef __APPLE__
    NPNetscapeFuncs* browser = (NPNetscapeFuncs*)mNpp->ndata;
    char *pFunc = browser->utf8fromidentifier(name);
    if(strcmp(pFunc, "Login") == 0)
    {
        int port = 0;
        if(args[1].type == NPVariantType_Int32)
            port = args[1].value.intValue;
        else if(args[1].type == NPVariantType_String)
            port = atoi((LPCTSTR)CNPString(args[1].value.stringValue));
        else
            port = (int)args[1].value.doubleValue; //for chrome
        
        int ret = impl->login((LPCTSTR)CNPString(args[0].value.stringValue),
                              port,
                              (LPCTSTR)CNPString(args[2].value.stringValue),
                              (LPCTSTR)CNPString(args[3].value.stringValue));
        
        INT32_TO_NPVARIANT(ret, *result);
        return true;
    }
    else if(strcmp(pFunc, "Logoff") == 0)
    {
        impl->logoff();
        return true;
    }
    else if(strcmp(pFunc, "Relayout") == 0)
    {
        int hcount;
        int vcount;
        
        if(args[0].type == NPVariantType_Int32)
            hcount = args[0].value.intValue;
        else if(args[0].type == NPVariantType_String)
            hcount = atoi((LPCTSTR)CNPString(args[0].value.stringValue));
        else
            hcount = (int)args[0].value.doubleValue; //for chrome
        
        if(args[1].type == NPVariantType_Int32)
            vcount = args[1].value.intValue;
        else if(args[1].type == NPVariantType_String)
            vcount = atoi((LPCTSTR)CNPString(args[1].value.stringValue));
        else
            vcount = (int)args[1].value.doubleValue; //for chrome
        impl->Relayout(hcount, vcount);
        return true;
    }
    else if(strcmp(pFunc, "FullScreen") == 0)
    {
        impl->FullScreen();
        return true;
    }
    else if(strcmp(pFunc, "OpenVideo") == 0)
    {
        std::string ret = impl->OpenVideo((LPCTSTR)CNPString(args[0].value.stringValue));
        char* returnStr = (char *)browser->memalloc(ret.length()+1);
        strcpy(returnStr, ret.c_str());
        STRINGZ_TO_NPVARIANT(returnStr, *result);
        return true;
    }
    else if(strcmp(pFunc, "CloseVideo") == 0)
    {
        std::string ret = impl->CloseVideo();
        char* returnStr = (char *)browser->memalloc(ret.length()+1);
        strcpy(returnStr, ret.c_str());
        STRINGZ_TO_NPVARIANT(returnStr, *result);
        return true;
    }
    else if(strcmp(pFunc, "Snapshot") == 0)
    {
        std::string ret = impl->Snapshot((LPCTSTR)CNPString(args[0].value.stringValue));
        char* returnStr = (char *)browser->memalloc(ret.length()+1);
        strcpy(returnStr, ret.c_str());
        STRINGZ_TO_NPVARIANT(returnStr, *result);
        return true;
    }
    else if(strcmp(pFunc, "OpenAudio") == 0)
    {
        std::string ret = impl->OpenAudio();
        char* returnStr = (char *)browser->memalloc(ret.length()+1);
        strcpy(returnStr, ret.c_str());
        STRINGZ_TO_NPVARIANT(returnStr, *result);
        return true;
    }
    else if(strcmp(pFunc, "CloseAudio") == 0)
    {
        std::string ret = impl->CloseAudio();
        char* returnStr = (char *)browser->memalloc(ret.length()+1);
        strcpy(returnStr, ret.c_str());
        STRINGZ_TO_NPVARIANT(returnStr, *result);
        return true;
    }
    else if(strcmp(pFunc, "GetCurViewInfo") == 0)
    {
        std::string ret = impl->GetCurViewInfo();
        char* returnStr = (char *)browser->memalloc(ret.length()+1);
        strcpy(returnStr, ret.c_str());
        STRINGZ_TO_NPVARIANT(returnStr, *result);
        return true;
    }
    else if(strcmp(pFunc, "PtzControll") == 0)
    {
        impl->PtzControll((LPCTSTR)CNPString(args[0].value.stringValue));
        return true;
    }
    else if(strcmp(pFunc, "CloseAllVideo") == 0)
    {
        impl->CloseAllVideo();
        return true;
    }
#endif
  
  return false;
}

bool
LiveScriptablePluginObject::InvokeDefault(const NPVariant *args, uint32_t argCount,
                                      NPVariant *result)
{
  printf ("LiveScriptablePluginObject default method called!\n");

  STRINGZ_TO_NPVARIANT(strdup("default method return val"), *result);

  return true;
}

CLivePlugin::CLivePlugin(NPP pNPInstance) :
m_pNPInstance(pNPInstance),
m_pNPStream(NULL),
m_bInitialized(false),
m_pScriptableObject(NULL)
{
#ifdef WIN32
    m_hWnd = NULL;
    sLivePluginType_id = NPN_GetStringIdentifier("PluginType");
    impl = new VMSLivePluginImpl(this);
#endif
    
#ifdef __APPLE__
    NPNetscapeFuncs* browser = (NPNetscapeFuncs*)pNPInstance->ndata;
    browser->getstringidentifier("PluginType");
    _layer = NULL;
    impl = new VMSLivePluginImpl(this,_layer);
#endif
}

CLivePlugin::~CLivePlugin()
{
	delete impl;
}

#ifdef WIN32
static LRESULT CALLBACK LivePluginWinProc(HWND, UINT, WPARAM, LPARAM);
static WNDPROC lpOldProc = NULL;
#endif

NPBool CLivePlugin::init(NPWindow* pNPWindow)
{
  if(pNPWindow == NULL)
    return false;

#ifdef WIN32
  m_hWnd = (HWND)pNPWindow->window;
  if(m_hWnd == NULL)
    return false;

  // subclass window so we can intercept window messages and
  // do our drawing to it
  lpOldProc = SubclassWindow(m_hWnd, (WNDPROC)LivePluginWinProc);

  // associate window with our CLivePlugin object so we can access 
  // it in the window procedure
  SetWindowLongPtr(m_hWnd, GWLP_USERDATA, (LONG_PTR)this);

  impl->OnCreate(m_hWnd);
#endif

  m_Window = pNPWindow;

  m_bInitialized = true;
  return true;
}

void CLivePlugin::shut()
{
#ifdef _WIN32
  // subclass it back
  SubclassWindow(m_hWnd, lpOldProc);
  m_hWnd = NULL;
#endif

  m_bInitialized = false;
}

NPBool CLivePlugin::isInitialized()
{
  return m_bInitialized;
}

int16_t CLivePlugin::handleEvent(void* event)
{
  return 0;
}

NPObject *
CLivePlugin::GetScriptableObject()
{
    
#ifdef  _WIN32
    if (!m_pScriptableObject)
        m_pScriptableObject = NPN_CreateObject(m_pNPInstance,GET_NPOBJECT_CLASS(LiveScriptablePluginObject));
    
    if (m_pScriptableObject)
        NPN_RetainObject(m_pScriptableObject);
    
    ((LiveScriptablePluginObject*) m_pScriptableObject)->m_hWnd = m_hWnd;
#endif
    
#ifdef __APPLE__
    NPNetscapeFuncs* browser = (NPNetscapeFuncs*)m_pNPInstance->ndata;
    if (!m_pScriptableObject)
        m_pScriptableObject =browser->createobject(m_pNPInstance,GET_NPOBJECT_CLASS(LiveScriptablePluginObject));
    
    if (m_pScriptableObject)
        browser->retainobject(m_pScriptableObject);

    ((LiveScriptablePluginObject*) m_pScriptableObject)->_pluginLayer = _layer;
#endif
    
    ((LiveScriptablePluginObject*) m_pScriptableObject)->impl = impl;
    return m_pScriptableObject;
}

static void OnAsyncLoginCompleted(void* pParm)
{
	CLivePlugin* plugin = (CLivePlugin*)pParm;
	plugin->AsyncOnLoginCompleted();
}

void CLivePlugin::AsyncOnLoginCompleted()
{
	LiveScriptablePluginObject* scriptableObject = (LiveScriptablePluginObject*)m_pScriptableObject;
	if (scriptableObject->m_cbOnLoginCompleted)
	{
		NPVariant args[1];
		INT32_TO_NPVARIANT(m_cbResult,args[0]);
		NPVariant result;
#ifdef _WIN32
        NPN_InvokeDefault(m_pNPInstance, scriptableObject->m_cbOnLoginCompleted, args, 1, &result);
        NPN_ReleaseVariantValue(&result);
#endif
        
#ifdef __APPLE__
        NPNetscapeFuncs* browser = (NPNetscapeFuncs*)m_pNPInstance->ndata;
        browser->invokeDefault(m_pNPInstance, scriptableObject->m_cbOnLoginCompleted, args, 1, &result);
        browser->releasevariantvalue(&result);
#endif
	}
}


void CLivePlugin::OnLoginCompleted(int error)
{
	m_cbResult = error;
#ifdef _WIN32
    NPN_PluginThreadAsyncCall(m_pNPInstance, OnAsyncLoginCompleted, this);
#endif
    
#ifdef __APPLE__
    NPNetscapeFuncs* browser = (NPNetscapeFuncs*)m_pNPInstance->ndata;
    browser->pluginthreadasynccall(m_pNPInstance, OnAsyncLoginCompleted, this);
#endif
}

static void OnAsyncNetDisconnect(void* pParm)
{
	CLivePlugin* plugin = (CLivePlugin*)pParm;
	plugin->AsyncOnNetDisconnect();
}

void CLivePlugin::AsyncOnNetDisconnect()
{
	LiveScriptablePluginObject* scriptableObject = (LiveScriptablePluginObject*)m_pScriptableObject;
	if (scriptableObject->m_cbOnNetDisconnect)
	{
		NPVariant result;
#ifdef _WIN32
        NPN_InvokeDefault(m_pNPInstance, scriptableObject->m_cbOnNetDisconnect, NULL, 0, &result);
        NPN_ReleaseVariantValue(&result);
#endif
#ifdef __APPLE__
        NPNetscapeFuncs* browser = (NPNetscapeFuncs*)m_pNPInstance->ndata;
        browser->invokeDefault(m_pNPInstance, scriptableObject->m_cbOnNetDisconnect, NULL, 0, &result);
        browser->releasevariantvalue(&result);
#endif
	}
}
void CLivePlugin::OnNetDisconnect()
{
#ifdef _WIN32
    NPN_PluginThreadAsyncCall(m_pNPInstance, OnAsyncNetDisconnect, this);
#endif
    
#ifdef __APPLE__
    NPNetscapeFuncs* browser = (NPNetscapeFuncs*)m_pNPInstance->ndata;
    browser->pluginthreadasynccall(m_pNPInstance, OnAsyncNetDisconnect, this);
#endif
}

static void OnAsyncOpenVideo(void* pParm)
{
	CLivePlugin* plugin = (CLivePlugin*)pParm;
	plugin->AsyncOnOpenVideo();
}
void CLivePlugin::AsyncOnOpenVideo()
{
	LiveScriptablePluginObject* scriptableObject = (LiveScriptablePluginObject*)m_pScriptableObject;
	if (scriptableObject->m_cbOnOpenVideo)
	{
		NPVariant args[2];
		INT32_TO_NPVARIANT(m_cbId,args[0]);
		INT32_TO_NPVARIANT(m_cbResult,args[1]);
		NPVariant result;
#ifdef _WIN32
        NPN_InvokeDefault(m_pNPInstance, scriptableObject->m_cbOnOpenVideo, args, 2, &result);
        NPN_ReleaseVariantValue(&result);
#endif
        
#ifdef __APPLE__
        NPNetscapeFuncs* browser = (NPNetscapeFuncs*)m_pNPInstance->ndata;
        browser->invokeDefault(m_pNPInstance, scriptableObject->m_cbOnOpenVideo, args, 2, &result);
        browser->releasevariantvalue(&result);
#endif
		
	}
}
void CLivePlugin::OnOpenVideo(unsigned int vid, unsigned int result)
{
	m_cbResult = result;
	m_cbId = vid;
#ifdef _WIN32
    NPN_PluginThreadAsyncCall(m_pNPInstance, OnAsyncOpenVideo, this);
#endif
    
#ifdef __APPLE__
    NPNetscapeFuncs* browser = (NPNetscapeFuncs*)m_pNPInstance->ndata;
    browser->pluginthreadasynccall(m_pNPInstance, OnAsyncOpenVideo, this);
#endif
}

static void OnAsyncOpenAudio(void* pParm)
{
	CLivePlugin* plugin = (CLivePlugin*)pParm;
	plugin->AsyncOnOpenAudio();
}
void CLivePlugin::AsyncOnOpenAudio()
{
	LiveScriptablePluginObject* scriptableObject = (LiveScriptablePluginObject*)m_pScriptableObject;
	if (scriptableObject->m_cbOnOpenAudio)
	{
		NPVariant args[2];
		INT32_TO_NPVARIANT(m_cbId,args[0]);
		INT32_TO_NPVARIANT(m_cbResult,args[1]);
		NPVariant result;
#ifdef _WIN32
        NPN_InvokeDefault(m_pNPInstance, scriptableObject->m_cbOnOpenAudio, args, 2, &result);
        NPN_ReleaseVariantValue(&result);
#endif
        
#ifdef __APPLE__
        NPNetscapeFuncs* browser = (NPNetscapeFuncs*)m_pNPInstance->ndata;
        browser->invokeDefault(m_pNPInstance, scriptableObject->m_cbOnOpenAudio, args, 2, &result);
        browser->releasevariantvalue(&result);
#endif
		
	}
}
void CLivePlugin::OnOpenAudio(unsigned int vid, unsigned int result)
{
	m_cbResult = result;
	m_cbId = vid;
#ifdef _WIN32
    NPN_PluginThreadAsyncCall(m_pNPInstance, OnAsyncOpenAudio, this);
#endif
    
#ifdef __APPLE__
    NPNetscapeFuncs* browser = (NPNetscapeFuncs*)m_pNPInstance->ndata;
    browser->pluginthreadasynccall(m_pNPInstance, OnAsyncOpenAudio, this);
#endif
}


static void OnAsyncOnViewSelected(void* pParm)
{
	CLivePlugin* plugin = (CLivePlugin*)pParm;
	plugin->AsyncOnViewSelected();
}
void CLivePlugin::AsyncOnViewSelected()
{
	LiveScriptablePluginObject* scriptableObject = (LiveScriptablePluginObject*)m_pScriptableObject;
	if (scriptableObject->m_cbOnViewSelected)
	{
		NPVariant args[1];
		INT32_TO_NPVARIANT(m_cbId,args[0]);
		NPVariant result;
#ifdef _WIN32
        NPN_InvokeDefault(m_pNPInstance, scriptableObject->m_cbOnViewSelected, args, 1, &result);
        NPN_ReleaseVariantValue(&result);
#endif
        
#ifdef __APPLE__
        NPNetscapeFuncs* browser = (NPNetscapeFuncs*)m_pNPInstance->ndata;
        browser->invokeDefault(m_pNPInstance, scriptableObject->m_cbOnViewSelected, args, 1, &result);
        browser->releasevariantvalue(&result);
#endif
		
	}
}
void CLivePlugin::OnViewSelected(int selectIndex) 
{
	m_cbId = selectIndex;
#ifdef _WIN32
    NPN_PluginThreadAsyncCall(m_pNPInstance, OnAsyncOnViewSelected, this);
#endif
    
#ifdef __APPLE__
    NPNetscapeFuncs* browser = (NPNetscapeFuncs*)m_pNPInstance->ndata;
    browser->pluginthreadasynccall(m_pNPInstance, OnAsyncOnViewSelected, this);
#endif
	
}

#ifdef WIN32
static LRESULT CALLBACK LivePluginWinProc(HWND hWnd, UINT msg, WPARAM wParam, LPARAM lParam)
{
  switch (msg) {
    case WM_PAINT:
      {
        PAINTSTRUCT ps;
        HDC hdc = BeginPaint(hWnd, &ps);
		CLivePlugin *plugin = (CLivePlugin*) GetWindowLongPtr(hWnd, GWLP_USERDATA);
		plugin->impl->OnPaint();
        EndPaint(hWnd, &ps);
      }
      break;
	case WM_SIZE:
		{
			CLivePlugin *plugin = (CLivePlugin*) GetWindowLongPtr(hWnd, GWLP_USERDATA);
			plugin->impl->OnSize(wParam, lParam);
		}
		break;
    default:
      break;
  }

  return DefWindowProc(hWnd, msg, wParam, lParam);
}
#endif
