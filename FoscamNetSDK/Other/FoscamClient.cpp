//
//  FoscamClient.cpp
//  
//
//  Created by mac_dev on 16/4/25.
//
//

#include "FoscamClient.h"
#include <iostream>
#include <sys/time.h>
#include <sys/timeb.h>
#include <stdlib.h>


static void *VideoDataCB(void* pParam)
{
    if(pParam != NULL)
    {
        CFoscamClient* pParent = (CFoscamClient*)pParam;
        pParent->DoData();
    }
    
    pthread_exit((void *)0);
}

static double time_2_dbl(timeval time_value)
{
    double new_time = 0.0;
    new_time = (double) (time_value.tv_usec) ;
    new_time /= 1000000.0;
    new_time += (double)time_value.tv_sec;
    //printf("the time.. %f\n", new_time);
    return(new_time);
} /* end time_2_dbl() */

static double gettimeofday()
{
    struct timeb timebuffer;
    struct timeval tp;
    ftime( &timebuffer );
    tp.tv_sec  = timebuffer.time;
    tp.tv_usec = timebuffer.millitm * 1000;
    
    return time_2_dbl(tp);
}



////////////////////////////////////////////////////////////////////////////////
CFoscamClient::CFoscamClient(void):
_stream_thread(NULL),
_is_stream(false),
_is_audio(false),
_sdker(NULL),
_user_data(NULL),
_user_id(-1),
_is_login(false),
_event_callback(NULL),
_is_retain(false)
{
    pthread_mutexattr_t attr;
    pthread_mutexattr_init(&attr);
    pthread_mutexattr_settype(&attr,PTHREAD_MUTEX_RECURSIVE);
    pthread_mutex_init(&_stream_mutex, &attr);
}

CFoscamClient::~CFoscamClient(void)
{
    if (_sdker) {
        _sdker->logout(1 << _chn_id);
    }
}

bool CFoscamClient::login(CFoscamSdker *sdker,int chn_id,LOGIN_DATA login_data,int *chn_cnt)
{
    if (NULL == sdker)
        return false;
    
    if (sdker->login(1 << chn_id,login_data, chn_cnt)) {
        this->_sdker = sdker;
        this->setLogin(true);
        this->setChnId(chn_id);
        return true;
    }
    
    return false;
}

void CFoscamClient::logout()
{
    if (NULL == _sdker)
        return;
    
    _sdker->logout(1 << _chn_id);
    _sdker = NULL;
    _is_login = false;
}

bool CFoscamClient::realPlay(LPPREVIEW_INFO previewInfo, NET_DataCallBack avnetDataCB, void *user)
{
    if (!_sdker)
        return false;
    
    if (!_is_login)
        return false;
    
    if (_sdker->openAV(1 << _chn_id, previewInfo, &_is_audio)) {
        _data_callback = avnetDataCB;
        _user_data = user;
        
        //初始化信号量
        pthread_condattr_t condattr;
        pthread_condattr_init(&condattr);
        pthread_cond_init(&_stream_cond, &condattr);
        _is_stream = true;
        //初始化线程
        pthread_attr_t attr;
        pthread_attr_init(&attr);
        
        return 0 == pthread_create(&_stream_thread, &attr, VideoDataCB, (void *)this);
    }
    
    return false;
}

void CFoscamClient::stopRealPlay()
{
    if (_is_login)
    {
        if (_sdker) {
            _sdker->closeAV(1 << _chn_id);
            if (_is_stream) {
                pthread_mutex_lock(&_stream_mutex);
                pthread_cond_signal(&_stream_cond);
                _is_stream = false;
                pthread_mutex_unlock(&_stream_mutex);
            }
            
            _data_callback = NULL;
            _user_data = NULL;
            
            if (_stream_thread != NULL) {
                void *retval;
                pthread_join(_stream_thread, &retval);
                _stream_thread = NULL;
            }
            
            pthread_cond_destroy(&_stream_cond);
        }
    }
}

bool CFoscamClient::ptz(PTZ_CMD ptz)
{
    if (!_is_login)
        return false;
    
    return true;
}

bool CFoscamClient::openTalk()
{
    return false;
}

void CFoscamClient::closeTalk()
{
    
}

bool CFoscamClient::talk(char* data, int dataLen)
{
    return false;
}

void CFoscamClient::setEventCB(NET_Event_CallBack cbNetEvent, void *userData)
{
    
}

bool CFoscamClient::getEventData( FOSCAM_IPC_NET_EVENT_DATA* eventData )
{
    return false;
}

bool CFoscamClient::getConfig(long type, void *config)
{
    return false;
}

bool CFoscamClient::setConfig(long type, void *config)
{
    return false;
}

#define VIDEO_BUFFER_LEN    1048576
void CFoscamClient::DoData()
{
    unsigned long dwWaitTime = 1000/30;//单位ms
    char *buffer = new char[VIDEO_BUFFER_LEN];
    int bufferLen = 0;
    
    while(_is_stream)
    {
        //获取当前时间
        struct timeval now;
        gettimeofday(&now, NULL);
        
        //计算等待时间
        timespec abstime;
        abstime.tv_nsec = now.tv_usec * 1000 + (dwWaitTime/* % 1000*/) * 1000000;
        abstime.tv_sec = now.tv_sec + dwWaitTime / 1000;
        
        pthread_mutex_lock(&_stream_mutex);
        int dwRet = pthread_cond_timedwait(&_stream_cond, &_stream_mutex, &abstime);
        pthread_mutex_unlock(&_stream_mutex);
    
        switch (dwRet) {
            case 0 :
                _is_stream = false;
                break;
                
            case ETIMEDOUT: {
                dwWaitTime = 1000/30;
                
                if (_sdker->getRawData(_chn_id, buffer, VIDEO_BUFFER_LEN, &bufferLen)) {
                    if(bufferLen > 0) {
                        FOSDEC_DATA *pFrame = (FOSDEC_DATA*)buffer; // 44
                        int headLen = sizeof(FOSDEC_DATA);
                        if (pFrame->type == FOSMEDIATYPE_VIDEO) {
                            unsigned char* dataBuffer = (unsigned char*)buffer + headLen;
                            //int dataBufferLen = bufferLen - headLen;
                            if (_data_callback != NULL)
                                _data_callback(_user_id, DATA_TYPE_VIDEO_H264, dataBuffer,
                                               pFrame->len, _user_data, gettimeofday());
                            
                            dwWaitTime = 0;
                        }
                    } else {
                        dwWaitTime = 1000/30;
                        break;
                    }
                    
                    if (!_is_stream)
                        break;
                }
               
                
                if (_is_audio) {
                    FOSDEC_DATA* pFrame = NULL;
                    int dataLen = 0;
                    
                    
                    while(_sdker->getAudioData(_chn_id, (char **)&pFrame, &dataLen)) {
                        if (dataLen) {
                            if (pFrame->type == FOSMEDIATYPE_AUDIO) {
                                // do data
                                if (_data_callback != NULL)
                                    _data_callback(_user_id,
                                                   DATA_TYPE_AUDIO_PCM,
                                                   (unsigned char*)pFrame->data,
                                                   pFrame->len,
                                                   _user_data,
                                                   gettimeofday());
                            }
                        } else {
                            dwWaitTime = 1000/30;
                            break;
                        }
                    }
                    
                    if (!_is_stream)
                        break;
                }
                
                if (_event_callback != NULL)
                {
                    /*FOSEVET_DATA fosEvent;
                    if (FOSCMDRET_OK == FosSdk_GetEvent(_fos_handle, &fosEvent))
                    {
                        switch (fosEvent.id)
                        {
                            case EVENT_MSG::PWRFREQ_EVENT_CHG:
                            {
                                if (fosEvent.len == sizeof(FOSPWRFREQ))
                                {
                                    FOSPWRFREQ* pwrFreq = (FOSPWRFREQ*)fosEvent.data;
                                    //fEventData.pwrFreq = pwrFreq->freq;
                                }
                            }
                                break;
                        }
                        
                        _event_callback(_user_id, &fosEvent, _user_data);
                    }*/
                }
            }
                break;
        }
    }
    
    //结束，清空buffer
    if (buffer != NULL) {
        delete[] buffer;
        buffer = NULL;
    }
}