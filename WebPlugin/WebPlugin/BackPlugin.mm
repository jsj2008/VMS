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
// CBackPlugin class implementation
//

#include "BackPlugin.h"
#ifdef WIN32
#include <windows.h>
#include <stdio.h>
#include <windowsx.h>
#endif


#include "ScriptablePluginObjectBase.h"
#include "NPString.h"

static NPIdentifier sBackPluginType_id;

class BackConstructablePluginObject : public ScriptablePluginObjectBase
{
public:
  BackConstructablePluginObject(NPP npp)
    : ScriptablePluginObjectBase(npp)
  {
  }

  virtual bool Construct(const NPVariant *args, uint32_t argCount,
                         NPVariant *result);
};

static NPObject *
AllocateConstructablePluginObject(NPP npp, NPClass *aClass)
{
  return new BackConstructablePluginObject(npp);
}

DECLARE_NPOBJECT_CLASS_WITH_BASE(BackConstructablePluginObject,
                                 AllocateConstructablePluginObject);

bool
BackConstructablePluginObject::Construct(const NPVariant *args, uint32_t argCount,
                                     NPVariant *result)
{
  printf("Creating new BackConstructablePluginObject!\n");

  NPObject *myobj =
    NPN_CreateObject(mNpp, GET_NPOBJECT_CLASS(BackConstructablePluginObject));
  if (!myobj)
    return false;

  OBJECT_TO_NPVARIANT(myobj, *result);

  return true;
}

class BackScriptablePluginObject : public ScriptablePluginObjectBase
{
public:
  BackScriptablePluginObject(NPP npp)
    : ScriptablePluginObjectBase(npp), m_hWnd(0)
  {
	  m_cbOnLoginCompleted = NULL;
	  m_cbOnNetDisconnect = NULL;
	  m_cbOnPlayProgress = NULL;
  }
	~BackScriptablePluginObject();

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
    long m_hWnd;
#endif
	
	VMSBackPluginImpl* impl;
	NPObject *m_cbOnLoginCompleted;
	NPObject *m_cbOnNetDisconnect;
	NPObject *m_cbOnPlayProgress;
};

static NPObject *
AllocateScriptablePluginObject(NPP npp, NPClass *aClass)
{
  return new BackScriptablePluginObject(npp);
}

BackScriptablePluginObject::~BackScriptablePluginObject()
{
	if(m_cbOnLoginCompleted)
		NPN_ReleaseObject(m_cbOnLoginCompleted);
	if(m_cbOnNetDisconnect)
		NPN_ReleaseObject(m_cbOnNetDisconnect);
	if(m_cbOnPlayProgress)
		NPN_ReleaseObject(m_cbOnPlayProgress);
}

DECLARE_NPOBJECT_CLASS_WITH_BASE(BackScriptablePluginObject,
                                 AllocateScriptablePluginObject);

bool
BackScriptablePluginObject::HasMethod(NPIdentifier name)
{
	char *pFunc = NPN_UTF8FromIdentifier(name);
	if(strcmp(pFunc, "Login") == 0)
	{
		return true;
	}
	else if(strcmp(pFunc, "Logoff") == 0)
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
	else if(strcmp(pFunc, "SetPlaySpeed") == 0)
	{
		return true;
	}
	else if(strcmp(pFunc, "SetPlayBeginTime") == 0)
	{
		return true;
	}
	return false;
}

bool
BackScriptablePluginObject::HasProperty(NPIdentifier name)
{
	char *pProp = NPN_UTF8FromIdentifier(name);
	if(strcmp(pProp, "OnLoginCompleted") == 0)
	{
		return true;
	}
	else if(strcmp(pProp, "OnNetDisconnect") == 0)
	{
		return true;
	}
	else if(strcmp(pProp, "OnPlayProgress") == 0)
	{
		return true;
	}
	return false;
}

bool
BackScriptablePluginObject::GetProperty(NPIdentifier name, NPVariant *result)
{
  VOID_TO_NPVARIANT(*result);
  char *pProp = NPN_UTF8FromIdentifier(name);			

  if (name == sBackPluginType_id) {
    NPObject *myobj =
      NPN_CreateObject(mNpp, GET_NPOBJECT_CLASS(BackConstructablePluginObject));
    if (!myobj) {
      return false;
    }

    OBJECT_TO_NPVARIANT(myobj, *result);

    return true;
  }

  return true;
}

bool
BackScriptablePluginObject::SetProperty(NPIdentifier name,
                                        const NPVariant *value)
{
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
	else if(strcmp(pProp, "OnPlayProgress") == 0)
	{
		if(m_cbOnPlayProgress == NULL)
			m_cbOnPlayProgress=NPN_RetainObject(NPVARIANT_TO_OBJECT(*value));
		return true;
	}
	return false;
}

bool
BackScriptablePluginObject::Invoke(NPIdentifier name, const NPVariant *args, uint32_t argCount, NPVariant *result)
{
  char *pFunc = NPN_UTF8FromIdentifier(name);
  if(strcmp(pFunc, "Login") == 0)
  {
	  int port = 0;
	  if(args[1].type == NPVariantType_Int32)
		  port = args[1].value.intValue;
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
  else if(strcmp(pFunc, "SetPlaySpeed") == 0)
  {
	  impl->SetPlaySpeed((float)args[0].value.doubleValue);
	  return true;
  }
  else if(strcmp(pFunc, "SetPlayBeginTime") == 0)
  {
	  int video_id = 0;
	  if(args[0].type == NPVariantType_Int32)
		  video_id = args[0].value.intValue;
	  else
		  video_id = (int)args[0].value.doubleValue; //for chrome 
	  impl->SetPlayBeginTime(video_id, (LPCTSTR)CNPString(args[1].value.stringValue));
	  return true;
  }
  return false;
}

bool
BackScriptablePluginObject::InvokeDefault(const NPVariant *args, uint32_t argCount,
                                      NPVariant *result)
{
  printf ("BackScriptablePluginObject default method called!\n");

  STRINGZ_TO_NPVARIANT(strdup("default method return val"), *result);

  return true;
}

CBackPlugin::CBackPlugin(NPP pNPInstance) :
  m_pNPInstance(pNPInstance),
  m_pNPStream(NULL),
  m_bInitialized(false),
  m_pScriptableObject(NULL)
{
#ifdef WIN32
  m_hWnd = NULL;
#endif
	sBackPluginType_id = NPN_GetStringIdentifier("PluginType");
	impl = new VMSBackPluginImpl(this);
}

CBackPlugin::~CBackPlugin()
{
	delete impl;
}

#ifdef WIN32
static LRESULT CALLBACK BackPluginWinProc(HWND, UINT, WPARAM, LPARAM);
static WNDPROC lpOldProc = NULL;
#endif

NPBool CBackPlugin::init(NPWindow* pNPWindow)
{
  if(pNPWindow == NULL)
    return false;

#ifdef WIN32
  m_hWnd = (HWND)pNPWindow->window;
  if(m_hWnd == NULL)
    return false;

  // subclass window so we can intercept window messages and
  // do our drawing to it
  lpOldProc = SubclassWindow(m_hWnd, (WNDPROC)BackPluginWinProc);

  // associate window with our CBackPlugin object so we can access 
  // it in the window procedure
  SetWindowLongPtr(m_hWnd, GWLP_USERDATA, (LONG_PTR)this);

  impl->OnCreate(m_hWnd);
#endif

  m_Window = pNPWindow;

  m_bInitialized = true;
  return true;
}

void CBackPlugin::shut()
{
#ifdef WIN32
  // subclass it back
  SubclassWindow(m_hWnd, lpOldProc);
  m_hWnd = NULL;
#endif

  m_bInitialized = false;
}

NPBool CBackPlugin::isInitialized()
{
  return m_bInitialized;
}

int16_t CBackPlugin::handleEvent(void* event)
{
  return 0;
}

NPObject *
CBackPlugin::GetScriptableObject()
{
  if (!m_pScriptableObject) {
    m_pScriptableObject =
      NPN_CreateObject(m_pNPInstance,
                       GET_NPOBJECT_CLASS(BackScriptablePluginObject));
  }

  if (m_pScriptableObject) {
    NPN_RetainObject(m_pScriptableObject);
  }
#ifdef _WIN32
 ( (BackScriptablePluginObject*) m_pScriptableObject )->m_hWnd = m_hWnd;
#endif
 ( (BackScriptablePluginObject*) m_pScriptableObject )->impl = impl;
  return m_pScriptableObject;
}

static void OnAsyncLoginCompleted(void* pParm)
{
	CBackPlugin* plugin = (CBackPlugin*)pParm;
	plugin->AsyncOnLoginCompleted();
}

void CBackPlugin::AsyncOnLoginCompleted()
{
	BackScriptablePluginObject* scriptableObject = (BackScriptablePluginObject*)m_pScriptableObject;
	if (scriptableObject->m_cbOnLoginCompleted)
	{
		NPVariant args[1];
		INT32_TO_NPVARIANT(m_cbResult,args[0]);
		NPVariant result;
		NPN_InvokeDefault(m_pNPInstance, scriptableObject->m_cbOnLoginCompleted, args, 1, &result);
		NPN_ReleaseVariantValue(&result);
	}
}
void CBackPlugin::OnLoginCompleted(int error)
{
	m_cbResult = error;
	NPN_PluginThreadAsyncCall(m_pNPInstance, OnAsyncLoginCompleted, this);
}

static void OnAsyncNetDisconnect(void* pParm)
{
	CBackPlugin* plugin = (CBackPlugin*)pParm;
	plugin->AsyncOnNetDisconnect();
}

void CBackPlugin::AsyncOnNetDisconnect()
{
	BackScriptablePluginObject* scriptableObject = (BackScriptablePluginObject*)m_pScriptableObject;
	if (scriptableObject->m_cbOnNetDisconnect)
	{
		NPVariant result;
		NPN_InvokeDefault(m_pNPInstance, scriptableObject->m_cbOnNetDisconnect, NULL, 0, &result);
		NPN_ReleaseVariantValue(&result);
	}
}
void CBackPlugin::OnNetDisconnect()
{
	NPN_PluginThreadAsyncCall(m_pNPInstance, OnAsyncNetDisconnect, this);
}
void CBackPlugin::OnOpenVideo(unsigned int result)
{

}
void CBackPlugin::OnOpenAudio(unsigned int vid, unsigned int result)
{

}

void OnAsyncPlayProgress(void* pParm)
{
	CBackPlugin* plugin = (CBackPlugin*)pParm;
	plugin->AsyncPlayProgress();
}
void CBackPlugin::AsyncPlayProgress()
{
	BackScriptablePluginObject* scriptableObject = (BackScriptablePluginObject*)m_pScriptableObject;
	if (scriptableObject->m_cbOnPlayProgress)
	{
		char timeStr[64];
		FormatTime(m_cbTime, timeStr);
		char xml[256];
		sprintf(xml, "<vms_plugin><vid>%d</vid><time>%s</time></vms_plugin>", m_cbId, timeStr);

		NPVariant args[1];
		STRINGZ_TO_NPVARIANT(xml,args[0]);
		NPVariant result;
		NPN_InvokeDefault(m_pNPInstance, scriptableObject->m_cbOnPlayProgress, args, 1, &result);
		NPN_ReleaseVariantValue(&result);
	}
}
void CBackPlugin::OnPlayProgress(unsigned int vid, time_t cur_tm)
{
	m_cbId = vid;
	m_cbTime = cur_tm;
	NPN_PluginThreadAsyncCall(m_pNPInstance, OnAsyncPlayProgress, this);
}

#ifdef WIN32
static LRESULT CALLBACK BackPluginWinProc(HWND hWnd, UINT msg, WPARAM wParam, LPARAM lParam)
{
  switch (msg) {
    case WM_PAINT:
      {
        PAINTSTRUCT ps;
        HDC hdc = BeginPaint(hWnd, &ps);
		CBackPlugin *plugin = (CBackPlugin*) GetWindowLongPtr(hWnd, GWLP_USERDATA);
		plugin->impl->OnPaint();
        EndPaint(hWnd, &ps);
      }
      break;
	case WM_SIZE:
		{
			CBackPlugin *plugin = (CBackPlugin*) GetWindowLongPtr(hWnd, GWLP_USERDATA);
			plugin->impl->OnSize(wParam, lParam);
		}
		break;
    default:
      break;
  }

  return DefWindowProc(hWnd, msg, wParam, lParam);
}
#endif
