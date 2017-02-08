//
//  FoscamIPCSdker.cpp
//  
//
//  Created by mac_dev on 16/4/25.
//
//

#include "FoscamIPCSdker.h"

CFoscamIPCSdker::CFoscamIPCSdker(long dev_id) :
CFoscamSdker(dev_id)
{

}

void CFoscamIPCSdker::logout(int chn)
{
    pthread_auto_lock lk(&_mutex);
    
    if (this->chnStates() > 0) {
        FosSdk_Release(this->fosHandle());
        this->setFosHandle(FOSHANDLE_INVALID);
        this->setChnState(0);
    }
}


bool CFoscamIPCSdker::login(int chn,LOGIN_DATA args,int *chn_cnt)
{
    pthread_auto_lock lk(&_mutex);
    
    //IPC只存在一路
    if (0 == this->chnStates()) {
        FOSHANDLE h = FosSdk_Create2(args.ip,
                                     args.ip,
                                     args.uid,
                                     args.user,
                                     args.psw,
                                     args.port,
                                     args.port,
                                     args.port,
                                     args.port,
                                     args.mac,
                                     FOSIPC_H264,
                                     FOSIPC_CONNECTTION_TYPE(args.connectType));
        
        if (FOSHANDLE_INVALID == h)
            return false;
        
        int timeout = strlen(args.uid) > 0? 2000 : 500;
        int usrRight = 0;
        FOSCMD_RESULT rst = FosSdk_Login(h, &usrRight, timeout);
        
        if (FOSCMDRET_OK == rst) {
            this->setFosHandle(h);
            this->setTimeout(timeout);
            this->setChnState(1 << 0);
            *chn_cnt = 1;
            return true;
        }
        
        FosSdk_Release(h);
        printf("login failed,code = %d\n",rst);
    }
    
    return false;
}

bool CFoscamIPCSdker::getRawData(int chn, char *data, int len, int *outLen)
{
    FOSHANDLE h = this->fosHandle();
    return (h == FOSHANDLE_INVALID)? false : (FOSCMDRET_OK) == FosSdk_GetRawData(h, data, len, outLen);
}

bool CFoscamIPCSdker::getAudioData(int chn, char **data, int *outLen)
{
    FOSHANDLE h = this->fosHandle();
    return (h == FOSHANDLE_INVALID)? false : (FOSCMDRET_OK) == FosSdk_GetAudioData(h, data, outLen);
}

bool CFoscamIPCSdker::getEvent(FOSEVET_DATA *data)
{
    return false;
}

bool CFoscamIPCSdker::openAV(int chn,LPPREVIEW_INFO preview_info,bool *is_audio)
{
    FOSHANDLE h = this->fosHandle();
    *is_audio = false;
    
    if (FOSHANDLE_INVALID != h) {
        //首先打开视频
        if (FosSdk_OpenVideo(h, FOSSTREAM_TYPE(preview_info->streamType), 500) != FOSCMDRET_OK)
            return false;
        
        //接下来打开音频
        if (FosSdk_OpenAudio(h, FOSSTREAM_TYPE(preview_info->streamType), 500) == FOSCMDRET_OK)
            *is_audio = true;
        
        return true;
    }
    
    return false;
}

void CFoscamIPCSdker::closeAV(int chn)
{
    FOSHANDLE h = this->fosHandle();
    int timeout = this->timeout();
    
    if (h != FOSHANDLE_INVALID) {
        FosSdk_CloseVideo(h, timeout);
        FosSdk_CloseAudio(h, timeout);
    }
}


