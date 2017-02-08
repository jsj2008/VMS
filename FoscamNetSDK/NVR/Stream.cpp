#include "Stream.h"
#include <iostream>
#include<sys/timeb.h>
#include <unistd.h>
#include "../PublicDef.h"
//#include "pubdef.h"

#define TIME_OUT    500
void *AVDataCB(void* pParam)
{
	if(pParam != NULL)
	{
        STREAM_THREAD_ARGCS *argcs = (STREAM_THREAD_ARGCS *)pParam;
		CStream* p = (CStream*)argcs->p1;
        switch (p->avStreamType()) {
            case STREAM_REAL:
                p->AVData();
                break;
            case STREAM_FILE:
                p->AVFileData(argcs->p2);
                break;
            default:
                break;
        }
	}

	return 0;
}

void *ProgressCB(void *pParam)
{
    if (pParam != NULL) {
        CStream* p = (CStream *)pParam;
        p->AVProgress();
    }
    return 0;
}

CStream::CStream(void):fIsPlay(false),
fDataCB(NULL),
fUserData(NULL),
fFosHandle(0),
/*fStreamHandle(NULL),*/
fStreamThread(NULL),
fIsStream(false),
fIsPro(false),
fIsCmd(false),
fIsAudio(false),
fSignals(0)
{
    pthread_mutexattr_t attr;
    pthread_mutexattr_init(&attr);
    pthread_mutexattr_settype(&attr,PTHREAD_MUTEX_RECURSIVE);
    pthread_mutex_init(&_mutex, &attr);
    pthread_mutex_init(&_mutex_cond, &attr);
    pthread_mutex_init(&fProCondMutex, &attr);
    pthread_mutex_init(&fCurMSecsMutex, &attr);
}

CStream::~CStream(void)
{
	stopRealPlay();
}

bool CStream::realPlay( FOSHANDLE fos, LPPREVIEW_INFO previewInfo, FOSCAM_NVR_DataCB dataCB, void* user )
{
	//CAutoLock lk(&fStreamCS);
    pthread_auto_lock lk(&_mutex);
    
	if (fIsPlay)
	{
		return false;
	}

    int channels = 1 << ((int)previewInfo->channel);
    FosNvr_OpenVideo(fos,
                     channels,
                     FOSSTREAM_TYPE(previewInfo->streamType),
                     FOSNVRVIDEOMODE_NOMAL,
                     FOSNVRPQ_MID,
                     FOSNVRVIDEOMODE_4CH,
                     0,
                     TIME_OUT);
    
    fAvStreamType = STREAM_REAL;
	fPreviewInfo = *previewInfo;
	fDataCB = dataCB;
	fUserData = user;
	fFosHandle = fos;
	fIsPlay = true;

    //初始化等待事件
    pthread_condattr_t condattr;
    pthread_condattr_init(&condattr);
    pthread_cond_init(&fStreamHandle, &condattr);
    fIsStream = true;
    
    //初始化流线程
    fThreadArgcs[0].p1 = this;
    pthread_attr_t attr;
    pthread_attr_init(&attr);
    pthread_create(&fStreamThread, &attr, AVDataCB, fThreadArgcs + 0);
    
	// create thread
//	unsigned int threadID = 0;
//	fStreamHandle = CreateEvent(NULL, false, FALSE, NULL);
//	fIsStream = true;
//	fStreamThread = (HANDLE)_beginthreadex( NULL, 0, &AVDataCB, this, 0, &threadID );

#if 0
	char msg[255] = {0};
	//sprintf(msg, "input data pt %f\r\n", time_2_dbl(pt));
	sprintf(msg, "foscam nvr sdk realplay success channel %d\n", previewInfo->channel);
	::OutputDebugString(msg);
#endif

	return true;
}

bool CStream::stopRealPlay()
{
	//CAutoLock lk(&fStreamCS);
    pthread_auto_lock lk(&_mutex);
    
	if (!fIsPlay)
	{
		return false;
	}

	fIsPlay = false;
	fDataCB = NULL;
	fUserData = NULL;
	fIsAudio = false;

    FOSCMD_RESULT ret = FosNvr_CloseVideo(fFosHandle, (int)fPreviewInfo.channel, TIME_OUT);
    if (ret != FOSCMDRET_OK) {
        printf("err to close video\n");
    }
    
//	int ret = NVRSdk_CloseVideo(fFosHandle, fPreviewInfo.channel);
//	if (ret != NVRCMD_OK)
//	{
//		return false;
//	}

    //通知流线程退出
    if(fIsStream) {
        //SetEvent(streamHandle);
        pthread_mutex_lock(&_mutex_cond);
        pthread_cond_signal(&fStreamHandle);
        fIsStream = false;
        pthread_mutex_unlock(&_mutex_cond);
    }
    
    //等待流线程退出
    if(fStreamThread != NULL) {
        void *retval;
        //WaitForSingleObject(streamThread, INFINITE);
        //printf("等待线程退出,fosHandle = %u,userId = %ld,isStream = %d\n",fFosHandle,fUserID,isStream);
        pthread_join(fStreamThread, &retval);
        fStreamThread = NULL;
        //printf("线程已经退出,fosHandle = %u,userid = %ld",fFosHandle,fUserID);
    }
    //销毁流等待信号
    pthread_cond_destroy(&fStreamHandle);
    
//	if(fIsStream != NULL)
//		SetEvent(fStreamHandle);
//	if(fStreamThread != NULL)
//		WaitForSingleObject(fStreamThread, INFINITE);
//	CLOSE_HANDLE(fStreamHandle);
//	CLOSE_HANDLE(fStreamThread);

	fFosHandle = 0;

	return true;
}


bool CStream::playback(FOSHANDLE fos, LPPLAYBACK_INFO playbackInfo,FOSCAM_NVR_FILEDataCB dataCB,FOSCAM_NVR_FILEEventCB eventCB, void *user)
{
    pthread_auto_lock lk(&_mutex);
    
    if (fIsPlay)
    {
        return false;
    }
    
    FOSCMD_RESULT ret = FosNvr_OpenPlayBack(fos,
                                            playbackInfo->channels,
                                            playbackInfo->st,
                                            playbackInfo->et,
                                            playbackInfo->offset,
                                            FOSNVRVIDEOMODE_NOMAL,
                                            TIME_OUT);
    printf("channels = %d,st=%d,et=%d,offset=%d\n",playbackInfo->channels,playbackInfo->st,playbackInfo->et,playbackInfo->offset);
    if (ret == FOSCMDRET_OK ||
        ret == FOSCMDRET_TIMEOUT) {
        
        fPlaybackInfo = *playbackInfo;
        fAvStreamType = STREAM_FILE;
        fFileDataCB = dataCB;
        fFileEventCB = eventCB;
        fUserData = user;
        fFosHandle = fos;
        fIsPlay = true;
        fpbCmd = FOSNVRPBCMD_PAUSEPLAY;
        fpbCmdValue = 1.0;
        fSignals = ~0;
        
        //初始化等待事件
        pthread_condattr_t condattr;
        pthread_condattr_init(&condattr);
        pthread_cond_init(&fStreamHandle, &condattr);
        pthread_cond_init(&fProCond, &condattr);
        fIsStream = true;
        fIsPro = true;
        fPlays = 0;
        
        //初始化流线程
        pthread_attr_t attr;
        pthread_attr_init(&attr);
        for (int ch = 0; ch < MAX_CHANNEL_CNT; ch++) {
            int channel = 1 << ch;
            if (channel & fPlaybackInfo.channels) {
                fThreadArgcs[ch].p1 = this;
                fThreadArgcs[ch].p2 = ch;
                pthread_mutex_lock(&_mutex_cond);
                fPlays |= channel;
                pthread_mutex_unlock(&_mutex_cond);
                pthread_create(fpbStreamThreads + ch, &attr, AVDataCB, fThreadArgcs + ch);
            }
        }
        
        pthread_create(&fpbProgressThread, &attr, ProgressCB, (void *)this);
        return true;
    }
    
    return false;
}

bool CStream::playbackCmd(FOSNVR_PBCMD cmd,int value)
{
    pthread_auto_lock lk(&_mutex);
    
    if (!fIsPlay)
    {
        return false;
    }
    
    
    FOSCMD_RESULT ret = FOSCMDRET_FAILD;
    bool reFill = true;
    switch (cmd) {
        case FOSNVRPBCMD_SEEK:
            ret = FosNvr_PlayBackCmd(fFosHandle, cmd, value, value, TIME_OUT);
            break;
        case FOSNVRPBCMD_BACKPLAY:
        case FOSNVRPBCMD_FASTPLAY:
        case FOSNVRPBCMD_SLOWPLAY:{
            int curSecs = 0;
            pthread_mutex_lock(&fCurMSecsMutex);
            curSecs = (int)(fCurMSecs / 1000);
            pthread_mutex_unlock(&fCurMSecsMutex);
            ret = FosNvr_PlayBackCmd(fFosHandle, cmd, curSecs, value, TIME_OUT);
        }
            break;
        case FOSNVRPBCMD_PAUSEPLAY:
        case FOSNVRPBCMD_RESUMEPLAY: {
            ret = FosNvr_PlayBackCmd(fFosHandle, cmd, 0, 0, TIME_OUT);
        }
            break;
        default:
            break;
    }
    
    if(FOSCMDRET_OK == ret)
    {
        //通知数据流线程跳过取数据
        pthread_mutex_lock(&_mutex_cond);
        fSignals = ~0;
        fpbCmd = cmd;
        fpbCmdValue = value;
        pthread_cond_broadcast(&fStreamHandle);
        pthread_mutex_unlock(&_mutex_cond);
        
        if (reFill) {
            //唤醒进度线程,开始读进度
            pthread_mutex_lock(&fProCondMutex);
            fIsCmd = true;
            pthread_cond_signal(&fProCond);
            pthread_mutex_unlock(&fProCondMutex);
        }
        
        return true;
    }
    return false;
}

bool CStream::stopPlayback()
{
    pthread_auto_lock lk(&_mutex);
    
    if (!fIsPlay)
    {
        return false;
    }
    
    FosNvr_ClosePlayback(fFosHandle, TIME_OUT);
    
    //通知流线程退出
    if(fIsStream) {
        pthread_mutex_lock(&_mutex_cond);
        fpbCmd = FOSNVRPBCMD_RESUMEPLAY;
        fIsStream = false;
        fSignals = -1;
        pthread_cond_broadcast(&fStreamHandle);
        pthread_mutex_unlock(&_mutex_cond);
        
        pthread_mutex_lock(&fProCondMutex);
        fIsCmd = true;
        fIsPro = false;
        pthread_cond_signal(&fProCond);
        pthread_mutex_unlock(&fProCondMutex);
    }
    
    pthread_join(fpbProgressThread, NULL);
    for (int ch = 0; ch < MAX_CHANNEL_CNT; ch++) {
        if ((1 << ch) & fPlaybackInfo.channels){
            pthread_t *pbStreamThread = fpbStreamThreads + ch;
            //等待流线程退出
            if(*pbStreamThread != NULL) {
                void *retval;
                pthread_join(*pbStreamThread, &retval);
                *pbStreamThread = NULL;
            }
        }
    }
    
    
    pthread_cond_destroy(&fStreamHandle);
    pthread_cond_destroy(&fProCond);
    
    fFosHandle = 0;
    fIsPlay = false;
    fDataCB = NULL;
    fUserData = NULL;
    fIsAudio = false;
    
    return true;
}

void CStream::AVProgress()
{
    bool start = false;
    
    while (fIsPro) {
        int val = FosNvr_GetPBSavedMemSize(fFosHandle, 3);
        if (!start && val == 0) {
            start = true;
        }
        
        if (start && (val == 100)) {
            //通知取数据线程开始播放
            pthread_mutex_lock(&_mutex_cond);
            fSignals = ~0;
            fpbCmd = FOSNVRPBCMD_RESUMEPLAY;
            pthread_cond_broadcast(&fStreamHandle);
            pthread_mutex_unlock(&_mutex_cond);
            start = false;
            
            //开始休眠
            pthread_mutex_lock(&fProCondMutex);
            if (!fIsCmd) {
                pthread_cond_wait(&fProCond, &fProCondMutex);
            }
            pthread_mutex_unlock(&fProCondMutex);
        }
        
        usleep(2000);
    }
}


void CStream::AVFileData(int ch)
{
    int     bufLen = 1*1024*1024;
    char    *buf = (char *)malloc(sizeof(char) *bufLen);
    memset(buf, 0, bufLen);
    
    unsigned long long  ptsRef = 0;
    long                waitMSecs = 0;
    struct              timeval tRef;
    bool                reset = true;
    float               ratio = 1.0;
    bool                endFrame = false;
    
    while(fIsStream)
    {
        pthread_mutex_lock(&_mutex_cond);
        timespec abstime;
        timeSpecFromNow(waitMSecs,&abstime);
        if (((1<<ch) & fSignals) || (0 == pthread_cond_timedwait(&fStreamHandle, &_mutex_cond, &abstime)))
        {
            //查看命令
            switch (fpbCmd)
            {
                case FOSNVRPBCMD_SLOWPLAY:
                    ratio = 1.0 * fpbCmdValue;
                    break;
                case FOSNVRPBCMD_BACKPLAY:
                case FOSNVRPBCMD_FASTPLAY:
                    ratio = 1.0 / fpbCmdValue;
                    break;
                default:
                    break;
            }
            
            if (fpbCmd != FOSNVRPBCMD_RESUMEPLAY)
                pthread_cond_wait(&fStreamHandle, &_mutex_cond);
            
            reset = true;
            fSignals &= ~(1<<ch);
        } else if (endFrame) {
            fPlays &= ~(1<<ch);
            if (0 == fPlays) {
                //callback
                if (fFileEventCB) {
                    fFileEventCB(0,FOSNVR_PBEVENT_FILE_END,fUserData);
                }
                
                if (!fIsStream) {
                    pthread_mutex_unlock(&_mutex_cond);
                    break;
                }
            }
            pthread_cond_wait(&fStreamHandle, &_mutex_cond);
            fPlays |= 1<<ch;
            endFrame = false;
        }
        pthread_mutex_unlock(&_mutex_cond);
        
        waitMSecs = 5;
        FOSDEC_DATA* vFrame = NULL;
        
        int vDataLen = 0;
        
        
        if(FosNvr_GetPBRawVideoData(fFosHandle,ch,buf,bufLen,&vDataLen),vDataLen > 0)
        {
            
            vFrame = (FOSDEC_DATA *)buf;
            if ((vFrame->type == FOSMEDIATYPE_VIDEO) && fFileDataCB != NULL) {
                fFileDataCB(0,vFrame->channel,DATA_TYPE_VIDEO_H264,(unsigned char*)vFrame->data,vFrame->len,(void *)fUserData,
                            vFrame->time / 1000.0);
            }
            
            if (vFrame->frameTag == 'E') {
                endFrame = true;
            }
        } else {
            //printf("ch=%d fosHandle=%d,获取视频数据失败!\n",ch,fFosHandle);
        }
        
        //不断地去获取音频数据,直到获取失败
        while (fIsStream) {
            FOSDEC_DATA *aFrame = NULL;
            int aDataLen = 0;
            FOSCMD_RESULT getAudioRet = FOSCMDRET_FAILD;
            
            getAudioRet = FosNvr_GetPBAudioData(fFosHandle, ch, (char**)&aFrame, &aDataLen);
            if ((FOSCMDRET_OK == getAudioRet) && (aDataLen > 0)) {
                if ((aFrame->type == FOSMEDIATYPE_AUDIO) && (fFileDataCB != NULL)) {
                    fFileDataCB(0,aFrame->channel,DATA_TYPE_AUDIO_PCM,(unsigned char*)aFrame->data,aFrame->len,(void *)fUserData,
                                aFrame->pts);
                }
            }
            else
                break;
        }
        
        //计算时间等待
        //查看是否需要重置
        if (vFrame) {
            if (reset) {
                ptsRef = vFrame->pts;
                gettimeofday(&tRef, NULL);
                reset = false;
                printf("设置参考时间\n");
            } else {
                struct timeval now;
                gettimeofday(&now, NULL);
                
                double ptsAbs = (std::max(vFrame->pts,ptsRef) - std::min(vFrame->pts,ptsRef)) * ratio;
                double locolUsed = (now.tv_sec - tRef.tv_sec) * 1000 + (now.tv_usec - tRef.tv_usec) / 1000;
                
                pthread_mutex_lock(&fCurMSecsMutex);
                fCurMSecs = vFrame->time;
                pthread_mutex_unlock(&fCurMSecsMutex);
                
                waitMSecs = (ptsAbs - locolUsed);
                if (waitMSecs < 0) {
                    waitMSecs = 0;
                } else if (waitMSecs > 10000) {
                    waitMSecs = 0;
                    reset = true;
                }
                //printf("ch=%d,ptsAbs = %lf,locol_userd = %lf,waitMsecs = %ld,ratio = %f\n",ch,ptsAbs,locolUsed,waitMSecs,ratio);
            }
        }
    }
    
    free(buf);
}

void CStream::AVData()
{
	DWORD dwWaitTime = 1000/40;
	char *data = new char[1024*1024];
	memset(data, 0, 1024*1024);
	int dataBufferLen = 1024*1024;
	//NVR_FrameData* videoFrame = NULL;
    int channel = (int)fPreviewInfo.channel;
    
	while(fIsStream)
	{
#ifdef _WIN32
        DWORD dwRet = WaitForSingleObject(fStreamHandle, dwWaitTime); // INFINITE
#else
        timespec abstime;
        timeSpecFromNow(dwWaitTime,&abstime);
        pthread_mutex_lock(&_mutex_cond);
        int dwRet = pthread_cond_timedwait(&fStreamHandle, &_mutex_cond, &abstime);
        pthread_mutex_unlock(&_mutex_cond);
#endif
		switch (dwRet)
		{
		case 0:
                fIsStream = false;
                break;
		case ETIMEDOUT:
			{
				dwWaitTime = 1000/40;
                FOSDEC_DATA* pFrame = NULL;
                
				int videoDataLen = 0;
				if(FosNvr_GetRawVideoData(fFosHandle, channel, data, dataBufferLen, &videoDataLen),videoDataLen > 0)
				{
                    pFrame = (FOSDEC_DATA *)data;
					if (fDataCB != NULL)
						fDataCB(fFosHandle,
                                DATA_TYPE_VIDEO_H264,
                                (unsigned char*)pFrame->data,
                                pFrame->len,
                                (void *)fUserData,
                                gettimeofday_ext());

					dwWaitTime = 0;
				}
                
                int audioDataLen = 0;
                while(FOSCMDRET_OK == FosNvr_GetAudioData(fFosHandle, channel, (char**)&pFrame, &audioDataLen))
                {
                    if (audioDataLen > 0)
                    {
                        if (pFrame->type == FOSMEDIATYPE_AUDIO)
                        {
                            // do data
                            if (fDataCB != NULL)
                                fDataCB(0,
                                        DATA_TYPE_AUDIO_PCM,
                                        (unsigned char*)pFrame->data,
                                        pFrame->len,
                                        (void *)fUserData,
                                        gettimeofday_ext());
                        }
                    }
                    else
                    {
                        dwWaitTime = 1000/30;
                        break;
                    }
                }
			}
			break;
		}
	}
	if (data != NULL)
	{
		delete[] data;
		data = NULL;
	}
}

bool CStream::isPlay()
{
	//CAutoLock lk(&fStreamCS);
    pthread_auto_lock lk(&_mutex);
    
	return fIsPlay;
}

bool CStream::isExist( LPPREVIEW_INFO previewInfo )
{
	//CAutoLock lk(&fStreamCS);
    pthread_auto_lock lk(&_mutex);
    
	if (!fIsPlay)
	{
		return false;
	}

	if (previewInfo->channel == fPreviewInfo.channel && previewInfo->streamType == fPreviewInfo.streamType)
	{
		return true;
	}

	return false;
}

bool CStream::isExist( int channel )
{
	//CAutoLock lk(&fStreamCS);
    pthread_auto_lock lk(&_mutex);
    
	if (!fIsPlay)
	{
		return false;
	}

	if (channel == fPreviewInfo.channel)
	{
		return true;
	}

	return false;
}

FOSHANDLE CStream::getHandle()
{
	//CAutoLock lk(&fStreamCS);
    pthread_auto_lock lk(&_mutex);
    
	return fFosHandle;
}
