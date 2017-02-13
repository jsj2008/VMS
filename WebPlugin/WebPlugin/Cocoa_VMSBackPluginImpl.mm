//
//  Cocoa_VMSBackPluginImpl.m
//  VMSWebPlugin
//
//  Created by mac_dev on 15/11/9.
//  Copyright (c) 2015年 mac_dev. All rights reserved.
//

#import "Cocoa_VMSBackPluginImpl.h"
#import "VMSBackPluginImpl.h"

//Interface
class Cocoa_VMSBackPluginEvent : public VMSBackPluginEvent
{
public:
    Cocoa_VMSBackPluginEvent(void);
    virtual void OnLoginCompleted(int error);
    virtual void OnNetDisconnect();
    virtual void OnOpenVideo(unsigned int result);
    virtual void OnOpenAudio(unsigned int vid, unsigned int result);
    virtual void OnPlayProgress(unsigned int vid, time_t cur_tm);
    void setPluginCallbacks(PluginCallbackFuncs *callbacks,void *userData);
private:
    void *_userData;
    Plugin_Callback_Fucs *_callbacks;
};

Cocoa_VMSBackPluginEvent ::Cocoa_VMSBackPluginEvent()
{
    _userData = NULL;
    _callbacks = NULL;
}

void Cocoa_VMSBackPluginEvent::OnLoginCompleted(int error)
{
    if (_callbacks) {
        OnLoginCompletedFuc onLoginCompleted = _callbacks->onLoginCompleted;
        if (onLoginCompleted)
            onLoginCompleted(_userData,error);
    }
}


void Cocoa_VMSBackPluginEvent::OnNetDisconnect()
{
    if (_callbacks) {
        OnNetDisconnectFuc onNetDisconnect = _callbacks->onNetDisconnect;
        if (onNetDisconnect)
            onNetDisconnect(_userData);
    }
}


void Cocoa_VMSBackPluginEvent::OnOpenVideo(unsigned int result)
{
    if (_callbacks) {
        OnOpenVideoFuc onOpenVideo = _callbacks->onOpenVideo;
        if (onOpenVideo)
            onOpenVideo(_userData,-1,result);
    }
}

void Cocoa_VMSBackPluginEvent::OnOpenAudio(unsigned int vid, unsigned int result)
{
    if (_callbacks) {
        OnOpenAudioFuc onOpenAudio = _callbacks->onOpenAudio;
        if (onOpenAudio)
            onOpenAudio(_userData,vid,result);
    }
}


void Cocoa_VMSBackPluginEvent::OnPlayProgress(unsigned int vid, time_t cur_tm)
{
    if (_callbacks) {
        OnPlayProgressFuc onPlayProgress = _callbacks->onPlayProgress;
        if (onPlayProgress) {
            onPlayProgress(_userData,vid,cur_tm);
        }
    }
}


void Cocoa_VMSBackPluginEvent::setPluginCallbacks(PluginCallbackFuncs *callbacks, void *userData)
{
    _callbacks = callbacks;
    _userData = userData;
}

@interface Cocoa_VMSBackPluginImpl() {
    Cocoa_VMSBackPluginEvent *_vmsBackPluginEvent;
    VMSBackPluginImpl *_vmsBackPluginImpl;
}
@end


@implementation Cocoa_VMSBackPluginImpl

- (instancetype)initWithLayer :(CALayer *)layer
{
    if (self = [super init]) {
        _vmsBackPluginEvent = new Cocoa_VMSBackPluginEvent();
        _vmsBackPluginImpl = new VMSBackPluginImpl(_vmsBackPluginEvent,(__bridge void *)layer);
    }
    
    return self;
}

- (void)setPluginCallbacks :(PluginCallbackFuncs*)pluginCallbacks
                  userData :(void *)userData
{
    _vmsBackPluginEvent->setPluginCallbacks(pluginCallbacks, userData);
}

- (void)dealloc
{
    delete _vmsBackPluginEvent;
    delete _vmsBackPluginImpl;
}

- (int)loginWithServer :(const char *)server
                  port :(int)port
                  name :(const char *)name
                   pwd :(const char *)pwd
{
    if (_vmsBackPluginImpl)
        _vmsBackPluginImpl->login(server, port, name, pwd);
    return 0;
}

- (void)logoff
{
    if (_vmsBackPluginImpl)
        _vmsBackPluginImpl->logoff();
}

- (void)fullScreen
{
    if (_vmsBackPluginImpl)
        _vmsBackPluginImpl->FullScreen();
}

- (void)cancelFullSrceen
{
    if (_vmsBackPluginImpl) {
        _vmsBackPluginImpl->CancelFullSrceen();
    }
}

- (const char *)openVideo :(const char*)xml
{
    if (_vmsBackPluginImpl) {
        return _vmsBackPluginImpl->OpenVideo(xml).c_str();
    }
    return NULL;
}

- (const char *)closeVideo
{
    if (_vmsBackPluginImpl) {
        return _vmsBackPluginImpl->CloseVideo().c_str();
    }
    return NULL;
}

- (const char *)snapShot :(const char *)xml
{
    if (_vmsBackPluginImpl) {
        return _vmsBackPluginImpl->Snapshot(xml).c_str();
    }
    return NULL;
}


- (const char *)openAudio
{
    if (_vmsBackPluginImpl) {
        return _vmsBackPluginImpl->OpenAudio().c_str();
    }
    return NULL;
}

- (const char *)closeAudio
{
    if (_vmsBackPluginImpl) {
        return _vmsBackPluginImpl->CloseAudio().c_str();
    }
    return NULL;
}


- (void)setPlaySpeed :(double)speed
{
    if (_vmsBackPluginImpl) {
        _vmsBackPluginImpl->SetPlaySpeed(speed);
    }
}

- (void)setPlayBeginTime :(long)video_id
                     xml :(const char *)beginTime
{
    if (_vmsBackPluginImpl) {
        _vmsBackPluginImpl->SetPlayBeginTime(video_id,beginTime);
    }
}

@end
