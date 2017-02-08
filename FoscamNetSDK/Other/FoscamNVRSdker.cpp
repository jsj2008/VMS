//
//  FoscamNVRSdker.cpp
//  
//
//  Created by mac_dev on 16/4/25.
//
//

#include "FoscamNVRSdker.h"

CFoscamNVRSdker::CFoscamNVRSdker(long dev_id) :
CFoscamSdker(dev_id)
{}


bool CFoscamNVRSdker::login(int chn,LOGIN_DATA args,int *chn_cnt)
{
    pthread_auto_lock lk(&_mutex);
    
    int chn_state = this->chnStates();
    if (chn_state == 0) {
        //没有任何通道登录
        FOSHANDLE h = FosNvr_Create(args.ip,
                                    args.port,
                                    args.ip,
                                    args.port,
                                    args.uid,
                                    args.mac,
                                    args.user,
                                    args.psw);
        
        if (FOSHANDLE_INVALID == h)
            return false;
        
        int timeout = strlen(args.uid) > 0? 2000 : 500;
        int usrRight = 0;
        
        
        FOSCMD_RESULT ret = FosNvr_Login(h, &usrRight, chn_cnt, timeout);
        if (FOSCMDRET_OK == ret) {
            this->setFosHandle(h);
            this->setTimeout(timeout);
            this->setChnState(chn_state | chn);
            return true;
        } else {
            FosNvr_Release(h);
            printf("login failed,errMsg = %s\n",CFoscamSdker::errMsg(ret));
        }
    } else if (!(chn_state & chn)) {
        this->setChnState(chn_state | chn);
        return true;
    }
    
    return false;
}

void CFoscamNVRSdker::logout(int chn)
{
    pthread_auto_lock lk(&_mutex);
    
    FOSHANDLE h = this->fosHandle();
    int chn_state = this->chnStates();
    
    if (FOSHANDLE_INVALID == h)
        return;
    
    if (chn_state & chn) {
        chn_state &= ~chn;
        this->setChnState(chn_state);
        
        if (0 == chn_state) {
            FosNvr_Release(h);
            this->setFosHandle(FOSHANDLE_INVALID);
        }
    }
}

bool CFoscamNVRSdker::getRawData(int chn, char *data, int len, int *outLen)
{
    FOSHANDLE h = this->fosHandle();
    return (FOSHANDLE_INVALID == h)? false : (FOSCMDRET_OK) == FosNvr_GetRawVideoData(h,chn,data,len,outLen);
}

bool CFoscamNVRSdker::getAudioData(int chn, char **data, int *outLen)
{
    FOSHANDLE h = this->fosHandle();
    return (FOSHANDLE_INVALID == h)? false : (FOSCMDRET_OK) == FosNvr_GetAudioData(h,chn,data,outLen);
}

bool CFoscamNVRSdker::getEvent(FOSEVET_DATA *data)
{
    return false;
}

bool CFoscamNVRSdker::openAV(int chn,LPPREVIEW_INFO preview_info,bool *is_audio)
{
    FOSHANDLE h = this->fosHandle();
    
    *is_audio = false;
    if (FOSHANDLE_INVALID != h) {
        FOSCMD_RESULT ret = FosNvr_OpenVideo(h,
                                             chn,
                                             FOSSTREAM_TYPE(preview_info->streamType),
                                             FOSNVRVIDEOMODE_NOMAL,
                                             FOSNVRPQ_MID,
                                             FOSNVRVIDEOMODE_4CH,
                                             0,
                                             500);
        
        //foscam部分机型打开视频成功了会返回超时,这里将超时算作成功!
        if (FOSCMDRET_OK == ret || FOSCMDRET_TIMEOUT == ret) {
            *is_audio = true;
            return true;
        }
        
        printf("nvr open av error,fos_handle = %d,msg :%s\n",h,CFoscamSdker::errMsg(ret));
    }
    
    return false;
}

void CFoscamNVRSdker::closeAV(int chn)
{
    FOSHANDLE h = this->fosHandle();
    
    if (h == FOSHANDLE_INVALID) {
        FosNvr_CloseVideo(h, chn, 500);
    }
}


