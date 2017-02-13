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

#ifndef __LIVE_PLUGIN_H__
#define __LIVE_PLUGIN_H__

#include "config.h"
#include "VMSLivePluginImpl.h"

#ifdef _WIN32
#include "npapi.h"
#include "npruntime.h"
#include "npfunctions.h"
#endif

#ifdef __APPLE__
#import <WebKit/npapi.h>
#import <WebKit/npfunctions.h>
#import <WebKit/npruntime.h>
#endif


class VMSLivePluginImpl;

class CLivePlugin : public VMSLivePluginEvent
{
private:
    NPP m_pNPInstance;
#ifdef _WIN32
  HWND m_hWnd; 
#endif
    
#ifdef __APPLE__
    void *_layer;
#endif
  NPWindow * m_Window;
  NPStream * m_pNPStream;
  NPBool m_bInitialized;
  NPObject *m_pScriptableObject;

  int m_cbResult;
  int m_cbId;
private:
	virtual void OnLoginCompleted(int error) ;
	virtual void OnNetDisconnect() ;
	virtual void OnOpenVideo(unsigned int vid, unsigned int result) ;
	virtual void OnOpenAudio(unsigned int vid, unsigned int result) ;
	virtual void OnViewSelected(int selectIndex) ;
public:
	void AsyncOnLoginCompleted() ;
	void AsyncOnNetDisconnect() ;
	void AsyncOnOpenVideo() ;
	void AsyncOnOpenAudio() ;
	void AsyncOnViewSelected() ;
public:
  CLivePlugin(NPP pNPInstance);
  ~CLivePlugin();

  NPBool init(NPWindow* pNPWindow);
  void shut();
  NPBool isInitialized();
  
  int16_t handleEvent(void* event);

  NPObject *GetScriptableObject();

  VMSLivePluginImpl* impl;
};

#endif // __LIVE_PLUGIN_H__
