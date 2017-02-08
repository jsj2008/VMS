//
//  FoscamClient.h
//  
//
//  Created by mac_dev on 16/4/25.
//
//

#ifndef ____FoscamClient__
#define ____FoscamClient__

#include "fossdk.h"
#include "pthread_auto_lock.h"
#include "FoscamNetSDK.h"
#include "FoscamSdker.h"
#include <stdio.h>

class CFoscamClient
{
public:
    CFoscamClient(void);
    ~CFoscamClient(void);
    
    bool login(CFoscamSdker *sdker,int chn_id,LOGIN_DATA login_data,int *chn_cnt);
    void logout();
    bool realPlay(LPPREVIEW_INFO previewInfo, NET_DataCallBack avnetDataCB, void* user);
    void stopRealPlay();
    bool ptz(PTZ_CMD ptz );
    bool openTalk();
    void closeTalk();
    bool talk(char* data, int dataLen);
    void setEventCB(NET_Event_CallBack cbNetEvent, void *userData);
    bool getEventData( FOSCAM_IPC_NET_EVENT_DATA* eventData );
    bool getConfig(long type, void *config);
    bool setConfig(long type, void *config);

    //通道id
    void setChnId(int chn_id){_chn_id = chn_id;};
    int chnId(){return _chn_id;};
    //是否已经登录
    bool IsLogin(){return _is_login;};
    void setLogin(bool val){_is_login = val;};
    //是否在占用
    bool isRetain(){return _is_retain;};
    void setRetain(bool val){_is_retain = val;};
    
    void DoData();
    
protected:
    bool    _is_login;
    bool    _is_retain;
    
private:
    long    _user_id;
    long    _dev_id;
    int     _chn_id;
    bool    _is_stream;
    bool    _is_audio;
    
    pthread_t   _stream_thread;
    pthread_mutex_t _stream_mutex;
    pthread_cond_t _stream_cond;
    void *_user_data;
    NET_DataCallBack _data_callback;
    NET_Event_CallBack _event_callback;
    CFoscamSdker *_sdker;
};

#endif /* defined(____FoscamClient__) */
