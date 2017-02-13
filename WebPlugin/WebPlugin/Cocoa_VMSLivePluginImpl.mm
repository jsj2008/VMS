//
//  Cocoa_VMSLivePluginImpl.m
//  VMSWebPlugin
//
//  Created by mac_dev on 15/11/6.
//  Copyright (c) 2015年 mac_dev. All rights reserved.
//

#import "Cocoa_VMSLivePluginImpl.h"
#include "VMSLivePluginImpl.h"


//插件委托对象
class Cocoa_VMSLivePluginEvent : public VMSLivePluginEvent{
public:
    Cocoa_VMSLivePluginEvent(void);
    virtual void OnLoginCompleted(int error);
    virtual void OnNetDisconnect();
    virtual void OnOpenVideo(unsigned int vid, unsigned int result);
    virtual void OnOpenAudio(unsigned int vid, unsigned int result);
    virtual void OnViewSelected(int selectIndex);
    void setPluginCallbacks(PluginCallbackFuncs *callbacks,void *userData);
private:
    void *_userData;
    Plugin_Callback_Fucs *_callbacks;
};


Cocoa_VMSLivePluginEvent::Cocoa_VMSLivePluginEvent()
{
    _callbacks = NULL;
    _userData = NULL;
}

void Cocoa_VMSLivePluginEvent::setPluginCallbacks(PluginCallbackFuncs *callbacks,void *userData)
{
    _callbacks = callbacks;
    _userData = userData;
}


void Cocoa_VMSLivePluginEvent::OnLoginCompleted(int error)
{
    if (_callbacks) {
        OnLoginCompletedFuc onLoginCompleted = _callbacks->onLoginCompleted;
        if (onLoginCompleted)
            onLoginCompleted(_userData,error);
    }
}

void Cocoa_VMSLivePluginEvent::OnNetDisconnect()
{
    if (_callbacks) {
        OnNetDisconnectFuc onNetDisconnect = _callbacks->onNetDisconnect;
        if (onNetDisconnect)
            onNetDisconnect(_userData);
    }
}

void Cocoa_VMSLivePluginEvent::OnOpenVideo(unsigned int vid, unsigned int result)
{
    if (_callbacks) {
        OnOpenVideoFuc onOpenVideo = _callbacks->onOpenVideo;
        if (onOpenVideo)
            onOpenVideo(_userData,vid,result);
    }
}

void Cocoa_VMSLivePluginEvent::OnOpenAudio(unsigned int vid, unsigned int result)
{
    if (_callbacks) {
        OnOpenAudioFuc onOpenAudio = _callbacks->onOpenAudio;
        if (onOpenAudio)
            onOpenAudio(_userData,vid,result);
    }
}

void Cocoa_VMSLivePluginEvent::OnViewSelected(int selectIndex)
{
    if (_callbacks) {
        OnViewSelectedFuc onViewSelected = _callbacks->onViewSelected;
        if (onViewSelected)
            onViewSelected(_userData,selectIndex);
    }
}




@interface Cocoa_VMSLivePluginImpl() {
    VMSLivePluginImpl *_vmsLivePluginImpl;
    Cocoa_VMSLivePluginEvent *_vmsLivePluginEvent;
}

@end

@implementation Cocoa_VMSLivePluginImpl
- (instancetype)initWithLayer :(CALayer *)layer
{
    if (self = [super init]) {
        _vmsLivePluginEvent = new Cocoa_VMSLivePluginEvent();
        _vmsLivePluginImpl = new VMSLivePluginImpl(_vmsLivePluginEvent,(__bridge void *)layer);
    }
    
    return self;
}

- (void)dealloc
{
    delete _vmsLivePluginImpl;
    delete _vmsLivePluginEvent;
}

#pragma mark - public api
- (void)setPluginCallbacks :(PluginCallbackFuncs*)pluginCallbacks
                  userData :(void *)userData
{
    _vmsLivePluginEvent->setPluginCallbacks(pluginCallbacks, userData);
}

- (int)loginWithServer :(const char *)server
                  port :(int)port
                  name :(const char *)name
                   pwd :(const char *)pwd
{
    if (_vmsLivePluginImpl)
        _vmsLivePluginImpl->login(server, port, name, pwd);
    return 0;
}

- (void)logoff
{
    if (_vmsLivePluginImpl)
        _vmsLivePluginImpl->logoff();
}


- (void)fullScreen
{
    if (_vmsLivePluginImpl)
        _vmsLivePluginImpl->FullScreen();
}

- (void)cancelFullSrceen
{
    if (_vmsLivePluginImpl)
        _vmsLivePluginImpl->CancelFullSrceen();
}

- (void)relayoutWithHCount :(int) hcount
                    vCount :(int) vcount
{
    if (_vmsLivePluginImpl)
        _vmsLivePluginImpl->Relayout(hcount, vcount);
}

- (const char *)openVideo :(const char*)xml
{
    if (_vmsLivePluginImpl) {
        return _vmsLivePluginImpl->OpenVideo(xml).c_str();
    }
    return NULL;
}

- (const char *)closeVideo
{
    if (_vmsLivePluginImpl) {
        return _vmsLivePluginImpl->CloseVideo().c_str();
    }
    return NULL;
}

- (const char *)snapShot :(const char *)xml
{
    if (_vmsLivePluginImpl) {
        return _vmsLivePluginImpl->Snapshot(xml).c_str();
    }
    return NULL;
}


- (const char *)openAudio
{
    if (_vmsLivePluginImpl) {
        return _vmsLivePluginImpl->OpenAudio().c_str();
    }
    return NULL;
}

- (const char *)closeAudio
{
    if (_vmsLivePluginImpl) {
        return _vmsLivePluginImpl->CloseAudio().c_str();
    }
    return NULL;
}

- (const char *)getCurViewInfo
{
    if (_vmsLivePluginImpl) {
        return _vmsLivePluginImpl->GetCurViewInfo().c_str();
    }
    return NULL;
}

- (void)ptzControll :(const char *)xml;

{
    if (_vmsLivePluginImpl) {
        _vmsLivePluginImpl->PtzControll(xml);
    }
}

- (void)closeAllVideo
{
    if (_vmsLivePluginImpl) {
        _vmsLivePluginImpl->CloseAllVideo();
    }
}

@end
