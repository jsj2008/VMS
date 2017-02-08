//
//  FoscamSdker.h
//  
//
//  Created by mac_dev on 16/4/25.
//
//

#ifndef ____FoscamSdker__
#define ____FoscamSdker__

#include <stdio.h>
#include "FoscamNetSDK.h"
#include "pthread_auto_lock.h"

class CFoscamSdker {
public:
    CFoscamSdker(void);
    CFoscamSdker(long);
    ~CFoscamSdker(void);
    
    virtual bool login(int chn,LOGIN_DATA,int *) = 0;
    virtual void logout(int chn) = 0;
    virtual bool getRawData(int chn, char *data, int len, int *outLen) = 0;
    virtual bool getAudioData(int chn, char **data, int *outLen) = 0;
    virtual bool getEvent(FOSEVET_DATA *data) = 0;
    virtual bool openAV(int chns,LPPREVIEW_INFO preview_info,bool *is_audio) = 0;
    virtual void closeAV(int chns) = 0;
    
    static const char *errMsg(FOSCMD_RESULT code);
    //通道状态
    int chnStates();
    void setChnState(int);
    //设备ID
    long devId();
    //通道数
    int channelCounts();
    void setChannelCounts(int);
    //句柄
    FOSHANDLE fosHandle();
    void setFosHandle(FOSHANDLE);
    //超时
    int timeout();
    void setTimeout(int);
protected:
    
    pthread_mutex_t _mutex;
    FOSHANDLE	_fos_handle;
    int     _timeout;
    int     _retain_cnt;
    int     _chn_cnt;
    long    _dev_id;
    int     _chn_states;
};
#endif /* defined(____FoscamSdker__) */
