#include "FoscamIPCClient.h"
#include <iostream>
#include <sys/time.h>
#include <sys/timeb.h>
#include <stdlib.h>
#include <unistd.h>

extern int TIME_OUT;

//unsigned int __stdcall VideoDataCB(void* pParam)
static void *VideoDataCB(void* pParam)
{
    if(pParam != NULL)
    {
        CFoscamIPCClient* pParent = (CFoscamIPCClient*)pParam;
        pParent->DoData();
    }
    
    pthread_exit((void *)0);
}

static void *doEventCB(void* pParam)
//unsigned int __stdcall doEventCB(void* pParam)
{
    if(pParam != NULL)
    {
        CFoscamIPCClient* p = (CFoscamIPCClient*)pParam;
        p->doEvent();
    }
    
    return 0;
}

CFoscamIPCClient::CFoscamIPCClient(void):
streamThread(NULL),
fEventThread(NULL),
/*streamHandle(NULL),*/
isStream(false),
fIsAudio(false),
fFosHandle(0),
fUserData(NULL),
fUserID(-1),
fIsLogin(false),
fTimeout(500),
fEventCB(NULL),
fEventUserData(0),
fRetain(false)
{
    pthread_mutexattr_t attr;
    pthread_mutexattr_init(&attr);
    pthread_mutexattr_settype(&attr,PTHREAD_MUTEX_RECURSIVE);
    
    pthread_mutex_init(&_mutex, NULL);
    pthread_mutex_init(&_mutex, &attr);
    
    //初始化条件锁
    pthread_mutex_init(&_mutex_cond, NULL);
    pthread_mutex_init(&_mutex_cond, &attr);
}

CFoscamIPCClient::~CFoscamIPCClient(void)
{
	logout();
}

bool CFoscamIPCClient::login( LOGIN_DATA *loginData )
{
    pthread_auto_lock lk(&_mutex);
    loginData->result = FOSCMDRET_FAILD;
    
	if (fIsLogin)
	{
		return false;
	}

    if (strlen(loginData->mac) > 0)
    {
        fTimeout = 500;
    }
    else
    {
        fTimeout = 2000;
    }
    
	fFosHandle =
    FosSdk_Create2(loginData->ip,
                   loginData->ip,
                   loginData->uid,
                   loginData->user,
                   loginData->psw,
                   loginData->port,
                   loginData->port,
                   loginData->port,
                   loginData->port,
                   loginData->mac,
                   FOSIPC_H264,
                   FOSIPC_CONNECTTION_TYPE(loginData->connectType));
	int usrRight = 0;
	FOSCMD_RESULT rst = FosSdk_Login(fFosHandle, &usrRight, fTimeout);
    
    loginData->result = rst;
    
	if (rst == FOSCMDRET_OK)
	{
        fIsLogin = true;
        fLoginData = *loginData;
        
        pthread_condattr_t condattr;
        pthread_condattr_init(&condattr);
        pthread_cond_init(&fEventHandle, &condattr);
        
        fIsEventThread = true;
        
        pthread_attr_t attr;
        pthread_attr_init(&attr);
        pthread_create(&fEventThread, &attr, doEventCB, (void *)this);
        
        return true;
    }
    
    FosSdk_Release(fFosHandle);
    fFosHandle = NULL;
    
    printf("ipc login failed,ret = %d\n",rst);
    return false;
}

bool CFoscamIPCClient::logout()
{
	//CAutoLock lk(&fFoscamIPCClientBaseCS);
    pthread_auto_lock lk(&_mutex);
    //printf("enter logout fosHandle = %u,userId = %ld\n",fFosHandle,fUserID);
	if (!fIsLogin)
	{
		return false;
	}
	stopRealPlay();
	//FosSdk_Logout(fFosHandle, 3000);
    //printf("fosId = %u will release\n",fFosHandle);
    if(fIsEventThread) {
        //SetEvent(streamHandle);
        pthread_mutex_lock(&_mutex_cond);
        pthread_cond_signal(&fEventHandle);
        fIsEventThread = false;
        pthread_mutex_unlock(&_mutex_cond);
    }
    
    //等待事件线程退出
    if(fEventThread != NULL) {
        void *retval;
        //WaitForSingleObject(streamThread, INFINITE);
        //printf("等待线程退出,fosHandle = %u,userId = %ld,isStream = %d\n",fFosHandle,fUserID,isStream);
        pthread_join(fEventThread, &retval);
        fEventThread = NULL;
        //printf("线程已经退出,fosHandle = %u,userid = %ld",fFosHandle,fUserID);
    }
    
    FosSdk_Release(fFosHandle);
    //printf("fosId = %u did release\n",fFosHandle);
	fIsLogin = false;

	fEventCB = NULL;
	fEventUserData = 0;
	fUserData = NULL;
    fFosHandle = 0;
    
    //printf("exit logout fosHandle = %u,userId = %ld\n",fFosHandle,fUserID);
	return true;
}

bool CFoscamIPCClient::modifyLoginInfo(char *newName,char* newPwd)
{
    pthread_auto_lock lk(&_mutex);
    
    if (!fIsLogin)
    {
        return false;
    }
  
    FOSCMD_RESULT rst = FosSdk_ChangeUserNameAndPwdTogether(fFosHandle,fTimeout,"admin",newName,"",newPwd);
    
    if (rst == FOSCMDRET_OK) {
        return true;
    }
    else {
        printf("failed to change user name and pwd together,ret = %d\n",rst);
    }
    
    return false;
}

long CFoscamIPCClient::realPlay( LPPREVIEW_INFO previewInfo, NET_DataCallBack avnetDataCB, void* user )
{
	//CAutoLock lk(&fFoscamIPCClientBaseCS);
    pthread_auto_lock lk(&_mutex);
    //printf("enter realPlay,fFosHandle = %u",fFosHandle);
	if (!fIsLogin)
		return -1;

	// FOSCMD_RESULT ret = FosSdk_OpenVideo(fFosHandle, FOSSTREAM_MAIN, 500);
    if (fLoginData.connectType == FOSCNTYPE_P2P)
        previewInfo->streamType = FOSSTREAM_SUB;
    
    
	FOSCMD_RESULT ret = FosSdk_OpenVideo(fFosHandle, FOSSTREAM_TYPE(previewInfo->streamType), 500);
	if (ret != FOSCMDRET_OK)
		return -1;


	ret = FosSdk_OpenAudio(fFosHandle, FOSSTREAM_TYPE(previewInfo->streamType), 500);
	if (ret != FOSCMDRET_OK)
	{
		fIsAudio = false;
	}
	else
	{
		fIsAudio = true;
	}

	fPreviewInfo = *previewInfo;
	fDataCB = avnetDataCB;
	fUserData = user;

    // create thread
    
    //streamHandle = CreateEvent(NULL, false, FALSE, NULL);
    pthread_condattr_t condattr;
    pthread_condattr_init(&condattr);
    pthread_cond_init(&streamHandle, &condattr);
    isStream = true;
    
    //unsigned int threadID = 0;
    //streamThread = (HANDLE)_beginthreadex( NULL, 0, &VideoDataCB, this, 0, &threadID );
    pthread_attr_t attr;
    pthread_attr_init(&attr);
    pthread_create(&streamThread, &attr, VideoDataCB, (void *)this);
    
    //printf("exit realPlay,fFosHandle = %u",fFosHandle);
    return 0;
}

bool CFoscamIPCClient::stopRealPlay()
{
	//CAutoLock lk(&fFoscamIPCClientBaseCS);
    pthread_auto_lock lk(&_mutex);
    
	if (!fIsLogin)
	{
		return false;
	}

	fDataCB = NULL;
	fUserData = NULL;

	/*FOSCMD_RESULT ret = */FosSdk_CloseVideo(fFosHandle, 500);
	//if (ret != FOSCMDRET_OK)
	//{
	//	return false;
	//}

    if(isStream) {
        //SetEvent(streamHandle);
        pthread_mutex_lock(&_mutex_cond);
        pthread_cond_signal(&streamHandle);
        isStream = false;
        pthread_mutex_unlock(&_mutex_cond);
    }
    
    if(streamThread != NULL) {
        void *retval;
        //WaitForSingleObject(streamThread, INFINITE);
        //printf("等待线程退出,fosHandle = %u,userId = %ld,isStream = %d\n",fFosHandle,fUserID,isStream);
        pthread_join(streamThread, &retval);
        streamThread = NULL;
        //printf("线程已经退出,fosHandle = %u,userid = %ld",fFosHandle,fUserID);
    }
    
    
    //CLOSE_HANDLE(streamHandle);
    //CLOSE_HANDLE(streamThread);
    pthread_cond_destroy(&streamHandle);

	return  true;
}

void CFoscamIPCClient::DoData()
{
	unsigned long dwWaitTime = 1000/30;//单位ms
    char *buffer = new char[1024*1204];
    int bufferLen = 0;
    
	while(isStream)
	{
#ifdef _WIN32
        unsigned long dwRet = WaitForSingleObject(streamHandle, dwWaitTime);
#else
        timespec abstime;
        timeSpecFromNow(dwWaitTime,&abstime);
        pthread_mutex_lock(&_mutex_cond);
        int dwRet = pthread_cond_timedwait(&streamHandle, &_mutex_cond, &abstime);
        pthread_mutex_unlock(&_mutex_cond);
    
        //usleep(1000 * dwWaitTime);
#endif
		switch (dwRet)
		{
		case 0 :
			{
				isStream = false;
			}
			break;
		case ETIMEDOUT:
			{
				dwWaitTime = 1000/30;

				if( FOSCMDRET_OK == FosSdk_GetRawData(fFosHandle, buffer,1024*1024, &bufferLen))
				{
                    //printf("bufferLen = %ld\n",bufferLen);
					if(bufferLen)
					{
						FOSDEC_DATA *pFrame = (FOSDEC_DATA*)buffer; // 44
						//int headLen = sizeof(FOSDEC_DATA);
						if (pFrame->type == FOSMEDIATYPE_VIDEO)
						{
							//unsigned char* dataBuffer = (unsigned char*)buffer + headLen;
							//int dataBufferLen = bufferLen - headLen;
							if (fDataCB != NULL)
								fDataCB(fFosHandle,
                                        DATA_TYPE_VIDEO_H264,
                                        (unsigned char *)pFrame->data,
                                        pFrame->len,
                                        (void *)fUserData,
                                        gettimeofday_ext());

							dwWaitTime = 0;

#if 0
							char msg[255] = {0};
							//sprintf(msg, "input data pt %f\r\n", time_2_dbl(pt));
							sprintf(msg, "CFoscamIPCClient input video data %d %d %d %d %d %d %d\r\n", dataBuffer[0], dataBuffer[1], dataBuffer[2], dataBuffer[3], dataBuffer[4], dataBufferLen);
							::OutputDebugString(msg);
#endif

						}
					}
                    else
                    {
                        dwWaitTime = 1000/30;
                        break;
                    }
                    if (!isStream)
                    {
                        break;
                    }
				}

				if (fIsAudio)
				{
                    FOSDEC_DATA* pFrame = NULL;
                    int dataLen = 0;
                    // FosSdk_SetWebRtcState(fFosHandle, false);
                    while( FOSCMDRET_OK == FosSdk_GetAudioData(fFosHandle, (char**)&pFrame, &dataLen) )
                    {
                        if (dataLen)
                        {
                            if (pFrame->type == FOSMEDIATYPE_AUDIO)
                            {
                                // do data
                                if (fDataCB != NULL)
                                    fDataCB(0, DATA_TYPE_AUDIO_PCM, (unsigned char*)pFrame->data, pFrame->len, (void *)fUserData, gettimeofday_ext());
                            }
                        }
                        else
                        {
                            dwWaitTime = 1000/30;
                            break;
                        }
                    }
                    if (!isStream)
                    {
                        break;
                    }
				}
			}
			break;
		}
	}
	if (buffer != NULL)
	{
		delete[] buffer;
		buffer = NULL;
        //printf("released buffer\n");
	}
}

void CFoscamIPCClient::doEvent()
{
    DWORD dwWaitTime = 100;//ms
    while(fIsEventThread)
    {
#ifdef _WIN32
        DWORD dwRet = WaitForSingleObject(fEventHandle, dwWaitTime); // INFINITE
#else
        timespec abstime;
        timeSpecFromNow(dwWaitTime,&abstime);
        pthread_mutex_lock(&_mutex_cond);
        int dwRet = pthread_cond_timedwait(&fEventHandle, &_mutex_cond, &abstime);
        pthread_mutex_unlock(&_mutex_cond);
#endif
        switch (dwRet)
        {
            case 0 :
                fIsEventThread = false;
                break;
            case ETIMEDOUT:
            {
                FOSEVET_DATA fosEvent;
                if (FOSCMDRET_OK == FosSdk_GetEvent(fFosHandle, &fosEvent))
                {
                    switch (fosEvent.id)
                    {
                        case EVENT_MSG::PWRFREQ_EVENT_CHG:
                        {
                            if (fosEvent.len == sizeof(FOSPWRFREQ))
                            {
                                FOSPWRFREQ* pwrFreq = (FOSPWRFREQ*)fosEvent.data;
                                fEventData.pwrFreq = pwrFreq->freq;
                            }
                        }
                            break;
                            
                        case EVENT_MSG::IRCUT_EVENT_CHG:
                            fEventData.ircutState = *((FOSIRCUTSTATE *)fosEvent.data);
                            break;
                    }
                    
                    if (fEventCB) {
                        fEventCB(fUserID, &fosEvent, fEventUserData);
                    }
                }
            }
                break;
        }
    }
}

bool CFoscamIPCClient::IsLogin()
{
	//CAutoLock lk(&fFoscamIPCClientBaseCS);
    pthread_auto_lock lk(&_mutex);
	return fIsLogin;
}

void CFoscamIPCClient::IsLogin( bool val )
{
	//CAutoLock lk(&fFoscamIPCClientBaseCS);
    pthread_auto_lock lk(&_mutex);
	fIsLogin = val;
}

long CFoscamIPCClient::UserID()
{
	//CAutoLock lk(&fFoscamIPCClientBaseCS);
    pthread_auto_lock lk(&_mutex);
	return fUserID;
}

void CFoscamIPCClient::UserID( long val )
{
	//CAutoLock lk(&fFoscamIPCClientBaseCS);
    pthread_auto_lock lk(&_mutex);
	fUserID = val;
}


/*
∑¢ÀÕ‘∆Ã®√¸¡Ó∫Ø ˝
int nCameraID
int nPtzCmd
int nParam1
int nParam2
int nParam3
int nParam4

1 µΩ 54  « nPtzCmd √¸¡Ó

1	£≠	Õ£÷πÀ˘”–¡¨–¯¡ø(æµÕ∑,‘∆Ã®)∂Ø◊˜	(Param1: Œﬁ–ß, Param2: Œﬁ–ß, Param3: Œﬁ–ß, Param4: Œﬁ–ß)
2	£≠	Ωπæ‡±‰¥Û(±∂¬ ±‰¥Û)		(Param1: 1-ø™ º/0-Õ£÷π, Param2: ÀŸ∂» [0-10,0±Ì æƒ¨»œÀŸ∂»,1-10±Ì æÀŸ∂»º∂±], Param3: Œﬁ–ß, Param4: Œﬁ–ß)
3	£≠	Ωπæ‡±‰–°(±∂¬ ±‰–°)		(Param1: 1-ø™ º/0-Õ£÷π, Param2: ÀŸ∂» [0-10,0±Ì æƒ¨»œÀŸ∂»,1-10±Ì æÀŸ∂»º∂±], Param3: Œﬁ–ß, Param4: Œﬁ–ß)
4	£≠	Ωπµ„«∞µ˜				(Param1: 1-ø™ º/0-Õ£÷π, Param2: ÀŸ∂» [0-10,0±Ì æƒ¨»œÀŸ∂»,1-10±Ì æÀŸ∂»º∂±], Param3: Œﬁ–ß, Param4: Œﬁ–ß)
5	£≠	Ωπµ„∫Ûµ˜				(Param1: 1-ø™ º/0-Õ£÷π, Param2: ÀŸ∂» [0-10,0±Ì æƒ¨»œÀŸ∂»,1-10±Ì æÀŸ∂»º∂±], Param3: Œﬁ–ß, Param4: Œﬁ–ß)
6	£≠	π‚»¶¿©¥Û				(Param1: 1-ø™ º/0-Õ£÷π, Param2: ÀŸ∂» [0-10,0±Ì æƒ¨»œÀŸ∂»,1-10±Ì æÀŸ∂»º∂±], Param3: Œﬁ–ß, Param4: Œﬁ–ß)
7	£≠	π‚»¶Àı–°				(Param1: 1-ø™ º/0-Õ£÷π, Param2: ÀŸ∂» [0-10,0±Ì æƒ¨»œÀŸ∂»,1-10±Ì æÀŸ∂»º∂±], Param3: Œﬁ–ß, Param4: Œﬁ–ß)
8	£≠	ø™◊‘∂ØΩπæ‡(◊‘∂Ø±∂¬ )	(Param1: 1-ø™ º/0-Õ£÷π, Param2: Œﬁ–ß, Param3: Œﬁ–ß, Param4: Œﬁ–ß)
9	£≠	ø™◊‘∂Øµ˜Ωπ				(Param1: 1-ø™ º/0-Õ£÷π, Param2: Œﬁ–ß, Param3: Œﬁ–ß, Param4: Œﬁ–ß)
10	£≠	ø™◊‘∂Øπ‚»¶				(Param1: 1-ø™ º/0-Õ£÷π, Param2: Œﬁ–ß, Param3: Œﬁ–ß, Param4: Œﬁ–ß)
11	£≠	‘∆Ã®…œ—ˆ				(Param1: 1-ø™ º/0-Õ£÷π, Param2: ÀŸ∂» [0-10,0±Ì æƒ¨»œÀŸ∂»,1-10±Ì æÀŸ∂»º∂±], Param3: Œﬁ–ß, Param4: Œﬁ–ß)
12	£≠	‘∆Ã®œ¬∏©				(Param1: 1-ø™ º/0-Õ£÷π, Param2: ÀŸ∂» [0-10,0±Ì æƒ¨»œÀŸ∂»,1-10±Ì æÀŸ∂»º∂±], Param3: Œﬁ–ß, Param4: Œﬁ–ß)
13	£≠	‘∆Ã®◊Û◊™				(Param1: 1-ø™ º/0-Õ£÷π, Param2: ÀŸ∂» [0-10,0±Ì æƒ¨»œÀŸ∂»,1-10±Ì æÀŸ∂»º∂±], Param3: Œﬁ–ß, Param4: Œﬁ–ß)
14	£≠	‘∆Ã®”“◊™				(Param1: 1-ø™ º/0-Õ£÷π, Param2: ÀŸ∂» [0-10,0±Ì æƒ¨»œÀŸ∂»,1-10±Ì æÀŸ∂»º∂±], Param3: Œﬁ–ß, Param4: Œﬁ–ß)
15	£≠	‘∆Ã®…œ—ˆ∫Õ◊Û◊™			(Param1: 1-ø™ º/0-Õ£÷π, Param2: ÀŸ∂» [0-10,0±Ì æƒ¨»œÀŸ∂»,1-10±Ì æÀŸ∂»º∂±], Param3: Œﬁ–ß, Param4: Œﬁ–ß)
16	£≠	‘∆Ã®…œ—ˆ∫Õ”“◊™			(Param1: 1-ø™ º/0-Õ£÷π, Param2: ÀŸ∂» [0-10,0±Ì æƒ¨»œÀŸ∂»,1-10±Ì æÀŸ∂»º∂±], Param3: Œﬁ–ß, Param4: Œﬁ–ß)
17	£≠	‘∆Ã®œ¬∏©∫Õ◊Û◊™			(Param1: 1-ø™ º/0-Õ£÷π, Param2: ÀŸ∂» [0-10,0±Ì æƒ¨»œÀŸ∂»,1-10±Ì æÀŸ∂»º∂±], Param3: Œﬁ–ß, Param4: Œﬁ–ß)
18	£≠	‘∆Ã®œ¬∏©∫Õ”“◊™			(Param1: 1-ø™ º/0-Õ£÷π, Param2: ÀŸ∂» [0-10,0±Ì æƒ¨»œÀŸ∂»,1-10±Ì æÀŸ∂»º∂±], Param3: Œﬁ–ß, Param4: Œﬁ–ß)
19	£≠	‘∆Ã®◊Û”“◊‘∂Ø…®√Ë		(Param1: 1-ø™ º/0-Õ£÷π, Param2: ÀŸ∂» [0-10,0±Ì æƒ¨»œÀŸ∂»,1-10±Ì æÀŸ∂»º∂±], Param3: Œﬁ–ß, Param4: Œﬁ–ß)

30	£≠	…Ë÷√‘§÷√µ„				(Param1: ‘§÷√µ„–Ú∫≈[>=0], Param2: Œﬁ–ß, Param3: Œﬁ–ß, Param4: Œﬁ–ß)
31	£≠	«Â≥˝‘§÷√µ„				(Param1: ‘§÷√µ„–Ú∫≈[>=0], Param2: Œﬁ–ß, Param3: Œﬁ–ß, Param4: Œﬁ–ß)
32	£≠	◊™µΩ‘§÷√µ„				(Param1: ‘§÷√µ„–Ú∫≈[>=0], Param2: Œﬁ–ß, Param3: Œﬁ–ß, Param4: Œﬁ–ß)

41	£≠	∆Ù∂Ø—≤∫Ωº«“‰			(Param1: —≤∫Ω¬∑œﬂ∫≈[>=0], Param2: Œﬁ–ß, Param3: Œﬁ–ß, Param4: Œﬁ–ß)
42	£≠	πÿ±’—≤∫Ωº«“‰			(Param1: —≤∫Ω¬∑œﬂ∫≈[>=0], Param2: Œﬁ–ß, Param3: Œﬁ–ß, Param4: Œﬁ–ß)
43	£≠	Ω´‘§÷√µ„º”»Î—≤∫Ω–Ú¡–	(Param1: —≤∫Ω¬∑œﬂ∫≈[>=0], Param2: ‘§÷√µ„–Ú∫≈[>=0], Param3: Õ£∂Ÿ ±º‰[√Î,>=0], Param4: —≤∫ΩÀŸ∂»[1-10])
44	£≠	ø™ º—≤∫Ω				(Param1: —≤∫Ω¬∑œﬂ∫≈[>=0], Param2: Œﬁ–ß, Param3: Œﬁ–ß, Param4: Œﬁ–ß)
45	£≠	Õ£÷π—≤∫Ω				(Param1: —≤∫Ω¬∑œﬂ∫≈[>=0], Param2: Œﬁ–ß, Param3: Œﬁ–ß, Param4: Œﬁ–ß)

51	£≠	∆Ù∂ØπÏº£º«“‰			(Param1: πÏº£∫≈[>=0], Param2: Œﬁ–ß, Param3: Œﬁ–ß, Param4: Œﬁ–ß)
52	£≠	πÿ±’πÏº£º«“‰			(Param1: πÏº£∫≈[>=0], Param2: Œﬁ–ß, Param3: Œﬁ–ß, Param4: Œﬁ–ß)
53	£≠	ø™ ºπÏº£				(Param1: πÏº£∫≈[>=0], Param2: Œﬁ–ß, Param3: Œﬁ–ß, Param4: Œﬁ–ß)
54	£≠	Õ£÷ππÏº£				(Param1: πÏº£∫≈[>=0], Param2: Œﬁ–ß, Param3: Œﬁ–ß, Param4: Œﬁ–ß)
*/
int CFoscamIPCClient::ptz(PTZ_CMD ptz )
{
	//CAutoLock lk(&fFoscamIPCClientBaseCS);
	pthread_auto_lock lk(&_mutex);
    
	if (!fIsLogin)
	{
		return false;
	}

#if 1
	char msg[200] = {0};
	sprintf(msg, "ptz cmd %d p1 %d p2 %d\r\n", ptz.ptzCmd, ptz.param1, ptz.param2);
	//::OutputDebugString(msg);
#endif

	int timeout = 100;

	switch (ptz.ptzCmd)
	{
	case FOSCAM_IPC_PTZ_CMD_STOP_ALL:
		//FosSdk_PtzCmd(fFosHandle, FOSPTZ_STOP, 500);
		break;
	case FOSCAM_IPC_PTZ_CMD_ZOOM_IN:
		if (ptz.param1 == 1)
		{
			FosSdk_PTZZoom(fFosHandle, FOSPTZ_ZOOMIN, timeout);
		}
		else
		{
			FosSdk_PTZZoom(fFosHandle, FOSPTZ_ZOOMSTOP, timeout);
		}
		break;
	case FOSCAM_IPC_PTZ_CMD_ZOOM_OUT:
		if (ptz.param1 == 1)
		{
			FosSdk_PTZZoom(fFosHandle, FOSPTZ_ZOOMOUT, timeout);
		}
		else
		{
			FosSdk_PTZZoom(fFosHandle, FOSPTZ_ZOOMSTOP, timeout);
		}
		break;
	case FOSCAM_IPC_PTZ_CMD_FOCUS_NEAR:
		if (ptz.param1 == 1)
		{
			FosSdk_PTZFocus(fFosHandle, FOSPTZ_FOCUSNEAR, timeout);
		}
		else
		{
			FosSdk_PTZFocus(fFosHandle, FOSPTZ_FOCUSSTOP, timeout);
		}
		break;
	case FOSCAM_IPC_PTZ_CMD_FOCUS_FAR:
		if (ptz.param1 == 1)
		{
			FosSdk_PTZFocus(fFosHandle, FOSPTZ_FOCUSFAR, timeout);
		}
		else
		{
			FosSdk_PTZFocus(fFosHandle, FOSPTZ_FOCUSSTOP, timeout);
		}
		break;
	case FOSCAM_IPC_PTZ_CMD_IRIS_OPEN:
		break;
	case FOSCAM_IPC_PTZ_CMD_IRIS_CLOSE:
		break;

	case FOSCAM_IPC_PTZ_CMD_UP:
		if (ptz.param1 == 1)
		{
			FosSdk_PtzCmd(fFosHandle, FOSPTZ_UP, timeout);
		}
		else
		{
			FosSdk_PtzCmd(fFosHandle, FOSPTZ_STOP, timeout);
		}
		break;
	case FOSCAM_IPC_PTZ_CMD_DOWN:
		if (ptz.param1 == 1)
		{
			FosSdk_PtzCmd(fFosHandle, FOSPTZ_DOWN, timeout);
		}
		else
		{
			FosSdk_PtzCmd(fFosHandle, FOSPTZ_STOP, timeout);
		}
		break;
	case FOSCAM_IPC_PTZ_CMD_LEFT:
		if (ptz.param1 == 1)
		{
			FosSdk_PtzCmd(fFosHandle, FOSPTZ_LEFT, timeout);
		}
		else
		{
			FosSdk_PtzCmd(fFosHandle, FOSPTZ_STOP, timeout);
		}
		break;
	case FOSCAM_IPC_PTZ_CMD_RIGHT:
		if (ptz.param1 == 1)
		{
			FosSdk_PtzCmd(fFosHandle, FOSPTZ_RIGHT, timeout);
		}
		else
		{
			FosSdk_PtzCmd(fFosHandle, FOSPTZ_STOP, timeout);
		}
		break;
	case FOSCAM_IPC_PTZ_CMD_LEFT_UP:
		if (ptz.param1 == 1)
		{
			FosSdk_PtzCmd(fFosHandle, FOSPTZ_LEFT_UP, timeout);
		}
		else
		{
			FosSdk_PtzCmd(fFosHandle, FOSPTZ_STOP, timeout);
		}
		break;
	case FOSCAM_IPC_PTZ_CMD_LEFT_DOWN:
		if (ptz.param1 == 1)
		{
			FosSdk_PtzCmd(fFosHandle, FOSPTZ_LEFT_DOWN, timeout);
		}
		else
		{
			FosSdk_PtzCmd(fFosHandle, FOSPTZ_STOP, timeout);
		}
		break;
	case FOSCAM_IPC_PTZ_CMD_RIGHT_UP:
		if (ptz.param1 == 1)
		{
			FosSdk_PtzCmd(fFosHandle, FOSPTZ_RIGHT_UP, timeout);
		}
		else
		{
			FosSdk_PtzCmd(fFosHandle, FOSPTZ_STOP, timeout);
		}
		break;
	case FOSCAM_IPC_PTZ_CMD_RIGHT_DOWN:
		if (ptz.param1 == 1)
		{
			FosSdk_PtzCmd(fFosHandle, FOSPTZ_RIGHT_DOWN, timeout);
		}
		else
		{
			FosSdk_PtzCmd(fFosHandle, FOSPTZ_STOP, timeout);
		}
		break;
	case FOSCAM_IPC_PTZ_CMD_AUTO:
		FosSdk_PtzCmd(fFosHandle, FOSPTZ_CENTER, timeout);
		break;
            
    case FOSCAM_IPC_PTZ_CMD_ADD_PRESET:
        {
            FOS_RESETPOINTLIST list;
            FOSCMD_RESULT ret = FosSdk_PTZAddPresetPoint(fFosHandle, ptz.param5, timeout, &list);
            
            return (ret == FOSCMDRET_OK)? list.result : -1;
        }
        break;
	case FOSCAM_IPC_PTZ_CMD_SET_PRESET:
		{
            int retVal = 0;
            char name[20] = {0};
            //itoa(ptz.param1, name, 10);
            sprintf(name, "%d",ptz.param1);
            FOS_RESETPOINTLIST list;
            FOSCMD_RESULT ret = FosSdk_PTZDelPresetPoint(fFosHandle, name, timeout, &list);
            
            retVal = (ret == FOSCMDRET_OK)? list.result : -1;
            
            if (retVal == 0 || retVal == 1) {
                ret = FosSdk_PTZAddPresetPoint(fFosHandle, name, timeout, &list);
                return (ret == FOSCMDRET_OK)? list.result : -1;
            }
            
            return retVal;
		}
		break;
	case FOSCAM_IPC_PTZ_CMD_CLEAR_PRESET:
		{
			FOS_RESETPOINTLIST list;
			FOSCMD_RESULT ret = FosSdk_PTZDelPresetPoint(fFosHandle, ptz.param5, timeout, &list);
            
            return (ret == FOSCMDRET_OK)? list.result : -1;
		}
		break;
	case FOSCAM_IPC_PTZ_CMD_GOTO_RRESET:
		{
            FosSdk_PTZGoToPresetPoint(fFosHandle, ptz.param5, timeout);
		}
		break;

	case FOSCAM_IPC_PTZ_CMD_BEGIN_PATTERN:
		break;
	case FOSCAM_IPC_PTZ_CMD_SET_PATTERN:
		break;
	case FOSCAM_IPC_PTZ_CMD_END_PATTERN:
		break;
    case FOSCAM_IPC_PTZ_CMD_START_PATTERN:
        {
            FosSdk_PTZStartCruise(fFosHandle, ptz.param5, timeout);
        }
            break;
    case FOSCAM_IPC_PTZ_CMD_STOP_PATTERN:
        {
            FosSdk_PTZStopCruise(fFosHandle, timeout);
        }
            break;
    }
	return 0;
}

bool CFoscamIPCClient::getConfig( long type, void *config )
{
	if (config == NULL)
	{
		return false;
	}

	//CAutoLock lk(&fFoscamIPCClientBaseCS);
    pthread_auto_lock lk(&_mutex);
    
	if (!fIsLogin)
	{
		return false;
	}

	FOSCAM_NET_CONFIG *netConfig = (FOSCAM_NET_CONFIG*)config;

	switch(type)
	{
        case FOSCAM_NET_CONFIG_PRODUCT_INFO:
        {
            if (netConfig->info == NULL)
                return false;
            FOSCMD_RESULT ret = FosSdk_GetProductAllInfo(fFosHandle, fTimeout, (FOS_PRODUCTALLINFO *)netConfig->info);
            if (ret == FOSCMDRET_OK) {
                return true;
            }
        }
            break;
        case FOSCAM_NET_CONFIG_NETWORK_FTP_TEST:
        {
            if(netConfig->info == NULL)
                return false;
            FOSCAM_NET_CONFIG_TEST *testInfo = (FOSCAM_NET_CONFIG_TEST *)netConfig->info;
            if (FosSdk_TestFtpServer(fFosHandle, fTimeout, (FOS_FTPCONFIG *)testInfo->input, (FOS_TESTFTPSERVER *)testInfo->result) == FOSCMDRET_OK)
                return true;
        }
            break;
        case FOSCAM_NET_CONFIG_NETWORK_SMTP_TEST:
        {
            if(netConfig->info == NULL)
                return false;
            FOSCAM_NET_CONFIG_TEST *testInfo = (FOSCAM_NET_CONFIG_TEST *)netConfig->info;
            if (FosSdk_SmtpTest(fFosHandle, fTimeout, (FOS_SMTPCONFIG *)testInfo->input , (FOS_SMTPTEST *)testInfo->result) == FOSCMDRET_OK)
                return true;
        }
            break;
        case FOSCAM_NET_CONFIG_NETWORK_WIFI_REFRESH:
        {
            if (FosSdk_RefreshWifiList(fFosHandle, 20000) == FOSCMDRET_OK) {
                return true;
            }
        }
            break;
        case FOSCAM_NET_CONFIG_NETWORK_WIFI_LIST:
        {
            if(netConfig->info == NULL)
                return false;
            
            if(FosSdk_GetWifiList(fFosHandle, fTimeout, *((int *)netConfig->info), (FOS_WIFILIST *)netConfig->info2) == FOSCMDRET_OK)
                return true;
        }
            break;
        case FOSCAM_NET_CONFIG_DEVICE_TEMPERATURE_ALARM:
        {
            if(netConfig->info == NULL)
                return false;
            if(FosSdk_GetTemperatureAlarmConfig(fFosHandle, fTimeout, (FOS_TEMPRATUREALARMCONFIG*)netConfig->info) == FOSCMDRET_OK)
                return true;
        }
            break;
        case FOSCAM_NET_CONFIG_VIDEO_MOTION_DETECT:
        {
            //这里需要区分平台类型，分安霸平台和其它
            if(netConfig->info == NULL)
                return false;
            
            FOSCMD_RESULT result = FosSdk_GetMotionDetectConfig(fFosHandle, fTimeout, (FOS_MOTIONDETECTCONFIG*)netConfig->info);
            if(result == FOSCMDRET_OK)
                return true;
        }
            break;
        case FOSCAM_NET_CONFIG_VIDEO_MOTION_DETECT1:
        {
            if(netConfig->info == NULL)
                return false;
            
            FOSCMD_RESULT result = FosSdk_GetMotionDetectConfig1(fFosHandle, fTimeout, (FOS_MOTIONDETECTCONFIG1*)netConfig->info);
            if(result == FOSCMDRET_OK)
                return true;
        }
            break;
        case FOSCAM_NET_CONFIG_PC_AUDIO_ALARM:
        {
            if(netConfig->info == NULL)
                return false;
            
            FOSCMD_RESULT result = FosSdk_GetPCAudioAlarmCfg(fFosHandle, fTimeout, (int *)netConfig->info);
            if (result == FOSCMDRET_OK) {
                return true;
            }
        }
            break;
	case FOSCAM_NET_CONFIG_DEVICE_NAME:
		{
			if(netConfig->info == NULL)
				return false;
			if(FosSdk_GetDevName(fFosHandle, fTimeout, (char*)netConfig->info) == FOSCMDRET_OK)
				return true;
		}
		break;
	case FOSCAM_NET_CONFIG_DEVICE_INFO:
		{
			if(netConfig->info == NULL)
				return false;
			if(FosSdk_GetDevInfo(fFosHandle, fTimeout, (FOS_DEVINFO*)netConfig->info) == FOSCMDRET_OK)
				return true;
		}
		break;
	case FOSCAM_NET_CONFIG_DEVICE_STATE:
		{
			if(netConfig->info == NULL)
				return false;
			if(FosSdk_GetDevState(fFosHandle, fTimeout, (FOS_DEVSTATE*)netConfig->info) == FOSCMDRET_OK)
				return true;
		}
		break;
	case FOSCAM_NET_CONFIG_NETWORK_IP:
		{
			if(netConfig->info == NULL)
				return false;
			if(FosSdk_GetIpInfo(fFosHandle, fTimeout, (FOS_IPINFO*)netConfig->info) == FOSCMDRET_OK)
				return true;
		}
		break;
	case FOSCAM_NET_CONFIG_NETWORK_PPPOE:
		{
			if(netConfig->info == NULL)
				return false;
			if(FosSdk_GetPPPoEConfig(fFosHandle, fTimeout, (FOS_PPPOECONFIG*)netConfig->info) == FOSCMDRET_OK)
				return true;
		}
		break;
	case FOSCAM_NET_CONFIG_NETWORK_UPNP:
		{
			if(netConfig->info == NULL)
				return false;
			if(FosSdk_GetUPnPConfig(fFosHandle, fTimeout, (FOS_UPNPCONFIG*)netConfig->info) == FOSCMDRET_OK)
				return true;
		}
		break;
	case FOSCAM_NET_CONFIG_NETWORK_PORT:
		{
			if(netConfig->info == NULL)
				return false;
			if(FosSdk_GetPortInfo(fFosHandle, fTimeout, (FOS_PORTINFO*)netConfig->info) == FOSCMDRET_OK)
				return true;
		}
		break;
	case FOSCAM_NET_CONFIG_NETWORK_P2P_INFO:
		{
			if(netConfig->info == NULL)
				return false;
			if(FosSdk_GetP2PInfo(fFosHandle, fTimeout, (FOS_P2PINFO*)netConfig->info) == FOSCMDRET_OK)
				return true;
		}
		break;
	case FOSCAM_NET_CONFIG_NETWORK_P2P_ENABLE:
		{
			if(netConfig->info == NULL)
				return false;
			if(FosSdk_GetP2PEnable(fFosHandle, fTimeout, (FOS_P2PENABLE*)netConfig->info) == FOSCMDRET_OK)
				return true;
		}
		break;
	case FOSCAM_NET_CONFIG_NETWORK_P2P_PORT:
		{
			if(netConfig->info == NULL)
				return false;
			if(FosSdk_GetP2PPort(fFosHandle, fTimeout, (FOS_P2PPORT*)netConfig->info) == FOSCMDRET_OK)
				return true;
		}
		break;
    case FOSCAM_NET_CONFIG_VIDEO_OSD_MSG:
        {
            if(netConfig->info == NULL)
                return false;
        }
            break;
	case FOSCAM_NET_CONFIG_VIDEO_OSD:
		{
			if(netConfig->info == NULL)
				return false;
			if(FosSdk_GetOSDSetting(fFosHandle, fTimeout, (FOS_OSDSETTING*)netConfig->info) == FOSCMDRET_OK)
				return true;
		}
		break;
	case FOSCAM_NET_CONFIG_VIDEO_IRLAMP_TYPE:
		{
			if(netConfig->info == NULL)
				return false;
			if(FosSdk_GetInfraLedConfig(fFosHandle, fTimeout, (int*)netConfig->info) == FOSCMDRET_OK)
				return true;
		}
		break;
	case FOSCAM_NET_CONFIG_VIDEO_IMAGE_PARAM:
		{
			if(netConfig->info == NULL)
				return false;
			if(FosSdk_GetImageSetting(fFosHandle, (FOSIMAGE*)netConfig->info, fTimeout) == FOSCMDRET_OK)
				return true;
		}
		break;
	case FOSCAM_NET_CONFIG_VIDEO_IRLAMP_PLAN:
		{
			if(netConfig->info == NULL)
				return false;
			if(FosSdk_GetScheduleInfraLedConfig(fFosHandle, fTimeout, (FOS_SCHEDULEINFRALEDCONFIG*)netConfig->info) == FOSCMDRET_OK)
				return true;
		}
		break;
	case FOSCAM_NET_CONFIG_DEVICE_TIME:
		{
			if(netConfig->info == NULL)
				return false;
            if(FosSdk_GetSystemTime(fFosHandle, fTimeout, (FOS_DEVSYSTEMTIME*)netConfig->info) == FOSCMDRET_OK) {
                FOS_DEVSYSTEMTIME *tm = (FOS_DEVSYSTEMTIME*)netConfig->info;
                
                return true;
            }
		}
		break;
	case FOSCAM_NET_CONFIG_VIDEO_ENCODE_MAIN:
		{
//			if(netConfig->info == NULL)
//				return false;
//			if(FosSdk_GetVideoStreamParam(fFosHandle, fTimeout, (FOS_VIDEOSTREAMLISTPARAM*)netConfig->info) == FOSCMDRET_OK)
//				return true;
            if (netConfig->info == NULL ||netConfig->info2 == NULL) {
                return false;
            }
            
            if (FosSdk_CallCGIRaw(fFosHandle, "cmd=getVideoStreamParam", (char *)netConfig->info, (int *)netConfig->info2, fTimeout) == FOSCMDRET_OK) {
                return true;
            }
		}
		break;
	case FOSCAM_NET_CONFIG_VIDEO_ENCODE_SUB:
		{
//			if(netConfig->info == NULL)
//				return false;
//			if(FosSdk_GetSubVideoStreamParam(fFosHandle, fTimeout, (FOS_VIDEOSTREAMLISTPARAM*)netConfig->info) == FOSCMDRET_OK)
//				return true;
            if (netConfig->info == NULL ||netConfig->info2 == NULL) {
                return false;
            }
            
            if (FosSdk_CallCGIRaw(fFosHandle, "cmd=getSubVideoStreamParam", (char *)netConfig->info, (int *)netConfig->info2, fTimeout) == FOSCMDRET_OK) {
                return true;
            }
		}
		break;
	case FOSCAM_NET_CONFIG_VIDEO_ENCODE_MAIN_STREAM_TYPE:
		{
			if(netConfig->info == NULL)
				return false;

			if(FosSdk_GetMainVideoStreamType(fFosHandle, fTimeout, (int*)netConfig->info) == FOSCMDRET_OK)
				return true;
		}
		break;
	case FOSCAM_NET_CONFIG_VIDEO_ENCODE_SUB_STREAM_TYPE:
		{
			if(netConfig->info == NULL)
				return false;
			if(FosSdk_GetSubVideoStreamType(fFosHandle, fTimeout, (int*)netConfig->info) == FOSCMDRET_OK)
				return true;
		}
		break;
	case FOSCAM_NET_CONFIG_MOTION:
		{
			if(netConfig->info == NULL)
				return false;
			if(FosSdk_GetMotionDetectConfig(fFosHandle, fTimeout, (FOS_MOTIONDETECTCONFIG*)netConfig->info) == FOSCMDRET_OK)
			{
				return true;
			}
		}
		break;
	case FOSCAM_NET_CONFIG_VIDEO_MIRROR_FLIP:
		{
			if(netConfig->info == NULL)
				return false;
			FOSMIRRORFLIP *config = (FOSMIRRORFLIP*)netConfig->info;
			if(FosSdk_GetMirrorAndFlipSetting(fFosHandle, fTimeout, &config->isMirror, &config->isFlip) == FOSCMDRET_OK)
			{
				return true;
			}
		}
		break;
	case FOSCAM_NET_CONFIG_ALARM_AUDIO:
		{
			if(netConfig->info == NULL)
				return false;
			FOS_AudioAlarmSetting *config = (FOS_AudioAlarmSetting*)netConfig->info;
			if(FosSdk_GetAudioAlarmConfig(fFosHandle, config, fTimeout) == FOSCMDRET_OK)
			{
				return true;
			}
		}
		break;
	case FOSCAM_NET_CONFIG_PTZ_SPEED:
		{
			if(netConfig->info == NULL)
				return false;
			
			if( FosSdk_PTZGetSpeed(fFosHandle, fTimeout, (int*)netConfig->info) == FOSCMDRET_OK)
			{
				return true;
			}
		}
		break;
	case FOSCAM_NET_CONFIG_PTZ_TEST_MODE:
		{
			if(netConfig->info == NULL)
				return false;
			if(FosSdk_PTZGetSelfTestMode(fFosHandle, fTimeout, (int*)netConfig->info) == FOSCMDRET_OK)
			{
				return true;
			}
		}
		break;
	case FOSCAM_NET_CONFIG_PTZ_CRUISE:
		{
			//if(netConfig->info == NULL)
			//	return false;
			//FOS_AudioAlarmSetting *config = (FOS_AudioAlarmSetting*)netConfig->info;
			//if(FosSdk_GetAudioAlarmConfig(fFosHandle, config, fTimeout) == FOSCMDRET_OK)
			//{
			//	return true;
			//}
		}
		break;
    case FOSCAM_NET_CONFIG_VIDEO_OSD_MASK_ENABLE:
        {
            if(netConfig->info == NULL)
                return false;
            if(FosSdk_GetOSDMask(fFosHandle, fTimeout, (int*)netConfig->info) == FOSCMDRET_OK)
                return true;
        }
        break;
        case FOSCAM_NET_CONFIG_NETWORK_WIFI:
        {
            if(netConfig->info == NULL)
                return false;
            if(FosSdk_GetWifiConfig(fFosHandle, fTimeout, (FOS_WIFICONFIG*)netConfig->info) == FOSCMDRET_OK)
                return true;
        }
            break;
        case FOSCAM_NET_CONFIG_NETWORK_DDNS:
        {
            if(netConfig->info == NULL)
                return false;
            if(FosSdk_GetDDNSConfig(fFosHandle, fTimeout, (FOS_DDNSCONFIG*)netConfig->info) == FOSCMDRET_OK)
                return true;
        }
            break;
        case FOSCAM_NET_CONFIG_NETWORK_FTP:
        {
            if(netConfig->info == NULL)
                return false;
            if(FosSdk_GetFtpConfig(fFosHandle, fTimeout, (FOS_FTPCONFIG*)netConfig->info) == FOSCMDRET_OK)
                return true;
        }
            break;
        case FOSCAM_NET_CONFIG_NETWORK_SMTP:
        {
            if(netConfig->info == NULL)
                return false;
            if(FosSdk_GetSMTPConfig(fFosHandle, fTimeout, (FOS_SMTPCONFIG*)netConfig->info) == FOSCMDRET_OK)
                return true;
        }
            break;
        case FOSCAM_NET_CONFIG_DEVICE_LED_ENABLE_STATE:
        {
            if(netConfig->info == NULL)
                return false;
            if(FosSdk_GetLedEnableState(fFosHandle, fTimeout, (int*)netConfig->info) == FOSCMDRET_OK)
                return true;
        }
            break;
        case FOSCAM_NET_CONFIT_DEVICE_SYSTEM_TIME:
        {
            if(netConfig->info == NULL)
                return false;
            if(FosSdk_GetSystemTime(fFosHandle, fTimeout, (FOS_DEVSYSTEMTIME*)netConfig->info) == FOSCMDRET_OK) {
                FOS_DEVSYSTEMTIME *tm = (FOS_DEVSYSTEMTIME*)netConfig->info;
                return true;
            }
        }
            break;
        case FOSCAM_NET_CONFIG_PTZ_CRUISE_CTRL_MODE:
        {
            if (netConfig->info == NULL)
                return false;
            if (FosSdk_PTZGetCruiseCtrlMode(fFosHandle, fTimeout, (int *)netConfig->info) ==
                FOSCMDRET_OK) {
                return true;
            }
        }
            break;
        case FOSCAM_NET_CONFIG_PTZ_CRUISE_TIME:
        {
            if (netConfig->info == NULL)
                return  false;
            if (FosSdk_PTZGetCruiseTime(fFosHandle, (unsigned int *)netConfig->info, fTimeout) ==
                FOSCMDRET_OK) {
                return true;
            }
        }
            break;
        case FOSCAM_NET_CONFIG_PTZ_CRUISE_TIME_CUSTOM:
        {
            if (netConfig->info == NULL)
                return  false;
            if (FosSdk_PTZGetCruiseTimeCustomed(fFosHandle, (FOS_CRUISETIMECUSTOMED *)netConfig->info, fTimeout) ==
                FOSCMDRET_OK) {
                return true;
            }
        }
            break;
        case FOSCAM_NET_CONFIG_PTZ_CRUISE_LOOP_CNT:
        {
            if (netConfig->info == NULL)
                return  false;
            if (FosSdk_PTZGetCruiseLoopCnt(fFosHandle, fTimeout, (int *)netConfig->info) ==
                FOSCMDRET_OK) {
                return true;
            }
        }
            break;
        case FOSCAM_NET_CONFIG_PTZ_CRUISE_MAP_LIST:
        {
            if (netConfig->info == NULL)
                return  false;
            if (FosSdk_PTZGetCruiseMapList(fFosHandle, fTimeout, (FOS_CRUISEMAPLIST *)netConfig->info) ==
                FOSCMDRET_OK) {
                return true;
            }
        }
            break;
        case FOSCAM_NET_CONFIG_PTZ_CRUISE_MAP_INFO:
        {
            if (netConfig->info == NULL)
                return  false;
            FOS_CRUISEMAPINFO *mapInfo = (FOS_CRUISEMAPINFO *)netConfig->info;
            if (FosSdk_PTZGetCruiseMapInfo(fFosHandle,
                                           mapInfo->cruiseMapName,
                                           fTimeout,
                                           mapInfo) == FOSCMDRET_OK) {
                return true;
            }
        }
            break;
        case FOSCAM_NET_CONFIG_PTZ_CRUISE_MAP_PREPOINT_TINGGER_TIME:
        {
            if (netConfig->info == NULL)
                return  false;
            FOS_CRUISEMAPPREPOINTLINGERTIME *cruiseMapPrepointLingerTime = (FOS_CRUISEMAPPREPOINTLINGERTIME *)netConfig->info;
           
            if (FosSdk_PTZGetCruisePrePointLingerTime(fFosHandle,
                                                      cruiseMapPrepointLingerTime->cruiseMapName,
                                                      fTimeout,
                                                      cruiseMapPrepointLingerTime) == FOSCMDRET_OK) {
                return true;
            }
        }
            break;
        case FOSCAM_NET_CONFIG_PTZ_SELF_TEST_PRESET_NAME:
        {
            if (netConfig->info == NULL)
                return  false;
            if (FosSdk_PTZGetPrePointForSelfTest(fFosHandle,fTimeout,(char *)netConfig->info) ==
                FOSCMDRET_OK) {
                return true;
            }
        }
            break;
        case FOSCAM_NET_CONFIG_PTZ_SELF_TEST_MODE:
        {
            if (netConfig->info == NULL)
                return  false;
            if (FosSdk_PTZGetSelfTestMode(fFosHandle, fTimeout, (int *)netConfig->info) ==
                FOSCMDRET_OK) {
                return true;
            }
        }
            break;
        case FOSCAM_NET_CONFIG_PTZ_PRESET_POINT_LIST:
        {
            if (netConfig->info == NULL)
                return false;
            if (FosSdk_PTZGetPresetPointList(fFosHandle, fTimeout,(FOS_RESETPOINTLIST *)netConfig->info) == FOSCMDRET_OK) {
                return true;
            }
        }
            break;
        case FOSCAM_NET_CONFIG_OSD_MASK_AREA:
        {
            if (netConfig->info == NULL)
                return false;
            if (FosSdk_GetOsdMaskArea(fFosHandle, fTimeout, (FOS_OSDMASKAREA *)netConfig->info) == FOSCMDRET_OK) {
                return true;
            }
        }
            break;
        case FOSCAM_NET_CONFIG_STREAM_ENCODE_INFO:
        {
            if (netConfig->info == NULL || netConfig->info2 == NULL)
                return false;
            
            if (FosSdk_GetStreamParamInfo(fFosHandle, fTimeout, (FOS_STREAMFRAMEPARAMINFO *)netConfig->info, (FOS_STREAMINFO *)netConfig->info2) == FOSCMDRET_OK) {
                return true;
            }
        }
            break;
        case FOSCAM_NET_CONFIG_VIDEO_PWR_FREG:
        {
            if (netConfig->info == NULL)
                return false;
            
            ((FOSPWRFREQ *)netConfig->info)->freq = fEventData.pwrFreq;
            return true;
        }
            break;
        case FOSCAM_NET_CONFIG_VIDEO_IRCUT_STATE:
        {
            if(netConfig->info == NULL)
                return false;
            
            *((FOSIRCUTSTATE *)netConfig->info) = fEventData.ircutState;
            return true;
        }
            break;
        case FOSCAM_NET_CONFIG_VIDEO_SCHEDULE_SNAP:
        {
            if (netConfig->info == NULL)
                return false;
            
            if (FosSdk_GetScheduleSnapConfig(fFosHandle, fTimeout, (FOS_SCHEDULESNAPCONFIG *)netConfig->info) == FOSCMDRET_OK) {
                return true;
            }
        }
            break;
        case FOSCAN_NET_CONFIG_VIDEO_SNAP:
        {
            if (netConfig->info == NULL)
                return false;
            
            if (FosSdk_GetSnapConfig(fFosHandle, fTimeout, (FOS_SNAPCONFIG *)netConfig->info) == FOSCMDRET_OK) {
                return true;
            }
            
        }
            break;
	}

	return false;
}


#define CHECK_FOS_RESULT(FUNC,RET) if(RET != FOSCMDRET_OK) printf("call %s,ret value = %ld",FUNC,RET)
bool CFoscamIPCClient::setConfig( long type, void *config )
{
	if (config == NULL)
	{
		return false;
	}

	//CAutoLock lk(&fFoscamIPCClientBaseCS);
    pthread_auto_lock lk(&_mutex);
    
	if (!fIsLogin)
	{
		return false;
	}

	FOSCAM_NET_CONFIG *netConfig = (FOSCAM_NET_CONFIG*)config;

	switch(type)
	{
        case FOSCAM_NET_CONFIG_VIDEO_TALK_DATA:
        {
            if(netConfig->info == NULL)
                return false;
            FOSCAM_NET_TALK_DATA *talkData = (FOSCAM_NET_TALK_DATA *)netConfig->info;
            if(FosSdk_SendTalkData(fFosHandle, talkData->data, talkData->len) == FOSCMDRET_OK)
                return true;
        }
            break;
        case FOSCAM_NET_CONFIG_VIDEO_TOGGLE_TALK_STATE:
        {
            if(netConfig->info == NULL)
                return false;
            if(*((int *)netConfig->info))
                return FosSdk_OpenTalk(fFosHandle, fTimeout) == FOSCMDRET_OK;
            else
                return FosSdk_CloseTalk(fFosHandle, fTimeout) == FOSCMDRET_OK;
        }
            break;
        case FOSCAM_NET_CONFIG_DEVICE_TEMPERATURE_ALARM:
        {
            if(netConfig->info == NULL)
                return false;
            if(FosSdk_SetTemperatureAlarmConfig(fFosHandle, fTimeout, (FOS_TEMPRATUREALARMCONFIG*)netConfig->info) == FOSCMDRET_OK)
                return true;
        }
            break;
        case FOSCAM_NET_CONFIG_VIDEO_MOTION_DETECT:
        {
            if(netConfig->info == NULL)
                return false;
            if(FosSdk_SetMotionDetectConfig(fFosHandle, (FOS_MOTIONDETECTCONFIG*)netConfig->info, fTimeout) == FOSCMDRET_OK)
                return true;
        }
            break;
        case FOSCAM_NET_CONFIG_VIDEO_MOTION_DETECT1:
        {
            if(netConfig->info == NULL)
                return false;
            if(FosSdk_SetMotionDetectConfig1(fFosHandle, (FOS_MOTIONDETECTCONFIG1*)netConfig->info, fTimeout) == FOSCMDRET_OK)
                return true;
        }
        case FOSCAM_NET_CONFIG_DEVICE_NAME:
		{
			if(netConfig->info == NULL)
				return false;
			if(FosSdk_SetDevName(fFosHandle, fTimeout, (char*)netConfig->info) == FOSCMDRET_OK)
				return true;
		}
		break;
        case FOSCAM_NET_CONFIG_NETWORK_IP:
		{
			if(netConfig->info == NULL)
				return false;
			if(FosSdk_SetIpInfo(fFosHandle, fTimeout, (FOS_IPINFO*)netConfig->info) == FOSCMDRET_OK)
				return true;
		}
		break;
	case FOSCAM_NET_CONFIG_NETWORK_PPPOE:
		{
			if(netConfig->info == NULL)
				return false;
			if(FosSdk_SetPPPoEConfig(fFosHandle, fTimeout, (FOS_PPPOECONFIG*)netConfig->info) == FOSCMDRET_OK)
				return true;
		}
		break;
	case FOSCAM_NET_CONFIG_NETWORK_UPNP:
		{
			if(netConfig->info == NULL)
				return false;
			if(FosSdk_SetUPnPConfig(fFosHandle, fTimeout, (FOS_UPNPCONFIG*)netConfig->info) == FOSCMDRET_OK)
				return true;
		}
		break;
	case FOSCAM_NET_CONFIG_NETWORK_PORT:
		{
			if(netConfig->info == NULL)
				return false;
			if(FosSdk_SetPortInfo(fFosHandle, fTimeout, (FOS_PORTINFO*)netConfig->info) == FOSCMDRET_OK)
				return true;
		}
		break;
	case FOSCAM_NET_CONFIG_NETWORK_P2P_ENABLE:
		{
			if(netConfig->info == NULL)
				return false;
			if(FosSdk_SetP2PEnable(fFosHandle, fTimeout, (FOS_P2PENABLE*)netConfig->info) == FOSCMDRET_OK)
				return true;
		}
		break;
	case FOSCAM_NET_CONFIG_NETWORK_P2P_PORT:
		{
			if(netConfig->info == NULL)
				return false;
			if(FosSdk_SetP2PPort(fFosHandle, fTimeout, (FOS_P2PPORT*)netConfig->info) == FOSCMDRET_OK)
				return true;
		}
		break;
	case FOSCAM_NET_CONFIG_SYSTEM_RESTART:
		{
			if(FosSdk_RebootSystem(fFosHandle, fTimeout) == FOSCMDRET_OK)
				return true;
		}
		break;
	case FOSCAM_NET_CONFIG_SYSTEM_RESET:
		{
			if(FosSdk_RestoreToFactorySetting(fFosHandle, fTimeout) == FOSCMDRET_OK)
				return true;
		}
		break;
	case FOSCAM_NET_CONFIG_SYSTEM_UPDATE:
		{
			if(netConfig->info == NULL)
				return false;
			int ret;
			if(FosSdk_FwUpgrade(fFosHandle, fTimeout, (char*)netConfig->info, &ret) == FOSCMDRET_OK)
			{
				if(FOSCMDRET_OK == ret)
					return true;
			}
		}
		break;
	case FOSCAM_NET_CONFIG_SYSTEM_EXPORT:
		{
			if(netConfig->info == NULL)
				return false;
			if(FosSdk_ExportConfig(fFosHandle, fTimeout, (char*)netConfig->info) == FOSCMDRET_OK)
			{
				return true;
			}
		}
		break;
	case FOSCAM_NET_CONFIG_SYSTEM_IMPORT:
		{
			if(netConfig->info == NULL)
				return false;
			int ret;
			if(FosSdk_ImportConfig(fFosHandle, fTimeout, (char*)netConfig->info, &ret) == FOSCMDRET_OK)
			{
				if(ret == FOSCMDRET_OK)
					return true;
			}
		}
		break;
	case FOSCAM_NET_CONFIG_VIDEO_OSD:
		{
			if(netConfig->info == NULL)
				return false;
			if(FosSdk_SetOSDSetting(fFosHandle, (FOS_OSDSETTING*)netConfig->info, fTimeout) == FOSCMDRET_OK)
			{
				return true;
			}
		}
		break;
    
	case FOSCAM_NET_CONFIG_VIDEO_IRLAMP_TYPE:
		{
			if(netConfig->info == NULL)
				return false;
			if(FosSdk_SetInfraLedConfig(fFosHandle, fTimeout, *(int*)netConfig->info) == FOSCMDRET_OK)
			{
				return true;
			}
		}
		break;
	case FOSCAM_NET_CONFIG_VIDEO_IRLAMP_OPEN:
		{
			int ret = 0;
			if(FosSdk_OpenInfraLed(fFosHandle, fTimeout, &ret) == FOSCMDRET_OK)
			{
				if (ret == 0)
				{
					return true;
				}
			}
		}
		break;
	case FOSCAM_NET_CONFIG_VIDEO_IRLAMP_CLOSE:
		{
			int ret = 0;
			if(FosSdk_CloseInfraLed(fFosHandle, fTimeout, &ret) == FOSCMDRET_OK)
			{
				if(ret == 0)
					return true;
			}
		}
		break;
	case FOSCAM_NET_CONFIG_VIDEO_IMAGE_PARAM_HUE:
		{
			if(netConfig->info == NULL)
				return false;
			FOSIMAGE_CMD cmd = FOSIMAGE_HUE;
			if(FosSdk_ImageCmd(fFosHandle, cmd, *(int*)netConfig->info, fTimeout) == FOSCMDRET_OK)
			{
				return true;
			}
		}
		break;	
	case FOSCAM_NET_CONFIG_VIDEO_IMAGE_PARAM_SATURATION:
		{
			if(netConfig->info == NULL)
				return false;
			FOSIMAGE_CMD cmd = FOSIMAGE_SATURATION;
			if(FosSdk_ImageCmd(fFosHandle, cmd, *(int*)netConfig->info, fTimeout) == FOSCMDRET_OK)
			{
				return true;
			}
		}
		break;	
	case FOSCAM_NET_CONFIG_VIDEO_IMAGE_PARAM_CONTRAST:
		{
			if(netConfig->info == NULL)
				return false;
			FOSIMAGE_CMD cmd = FOSIMAGE_CONTRAST;
			if(FosSdk_ImageCmd(fFosHandle, cmd, *(int*)netConfig->info, fTimeout) == FOSCMDRET_OK)
			{
				return true;
			}
		}
		break;	
	case FOSCAM_NET_CONFIG_VIDEO_IMAGE_PARAM_SHARPNESS:
		{
			if(netConfig->info == NULL)
				return false;
			FOSIMAGE_CMD cmd = FOSIMAGE_SHARPNESS;
			if(FosSdk_ImageCmd(fFosHandle, cmd, *(int*)netConfig->info, fTimeout) == FOSCMDRET_OK)
			{
				return true;
			}
		}
		break;	
	case FOSCAM_NET_CONFIG_VIDEO_IMAGE_PARAM_BRIGHTNESS:
		{
			if(netConfig->info == NULL)
				return false;
			FOSIMAGE_CMD cmd = FOSIMAGE_BRIGHTNESS;
			if(FosSdk_ImageCmd(fFosHandle, cmd, *(int*)netConfig->info, fTimeout) == FOSCMDRET_OK)
			{
				return true;
			}
		}
		break;	
	case FOSCAM_NET_CONFIG_VIDEO_IMAGE_PARAM_DEFALUT:
		{
			if(netConfig->info == NULL)
				return false;
			FOSIMAGE_CMD cmd = FOSIMAGE_DEFALUT;
			if(FosSdk_ImageCmd(fFosHandle, cmd, *(int*)netConfig->info, fTimeout) == FOSCMDRET_OK)
			{
				return true;
			}
		}
		break;	
	case FOSCAM_NET_CONFIG_VIDEO_IRLAMP_PLAN:
		{
			if(netConfig->info == NULL)
				return false;
			if(FosSdk_SetScheduleInfraLedConfig(fFosHandle, fTimeout, (FOS_SCHEDULEINFRALEDCONFIG*)netConfig->info) == FOSCMDRET_OK)
				return true;
		}
		break;
	case FOSCAM_NET_CONFIG_DEVICE_TIME:
		{
			if(netConfig->info == NULL)
				return false;
            if(FosSdk_SetSystemTime(fFosHandle, fTimeout, (FOS_DEVSYSTEMTIME*)netConfig->info) == FOSCMDRET_OK) {
                FOS_DEVSYSTEMTIME *tm = (FOS_DEVSYSTEMTIME*)netConfig->info;
                
                return true;
            }
		}
		break;
	case FOSCAM_NET_CONFIG_VIDEO_ENCODE_MAIN:
		{
			if(netConfig->info == NULL)
				return false;
            
            char cmd[256];
            FOS_VIDEOSTREAMPARAM *param = (FOS_VIDEOSTREAMPARAM*)netConfig->info;
            int lbrRation = *((int *)netConfig->info2);
            sprintf(cmd, "cmd=setVideoStreamParam&streamType=%d&resolution=%d&bitRate=%d&frameRate=%d&GOP=%d&isVBR=%d&lbrRatio=%d",
                    param->streamType,param->resolution,param->bitRate,param->frameRate,param->GOP,param->isVBR,lbrRation);
            
            if (FosSdk_CallCGIRaw(fFosHandle, cmd, (char *)netConfig->info3, (int *)netConfig->info4,fTimeout) == FOSCMDRET_OK) {
                return true;
            }
//			if(FosSdk_SetVideoStreamParam(fFosHandle, (FOS_VIDEOSTREAMPARAM*)netConfig->info, fTimeout) == FOSCMDRET_OK)
//				return true;
		}
		break;
	case FOSCAM_NET_CONFIG_VIDEO_ENCODE_SUB:
		{
			if(netConfig->info == NULL)
				return false;
            
            char cmd[256];
            FOS_VIDEOSTREAMPARAM *param = (FOS_VIDEOSTREAMPARAM*)netConfig->info;
            int lbrRation = *((int *)netConfig->info2);
            sprintf(cmd, "cmd=setSubVideoStreamParam&streamType=%d&resolution=%d&bitRate=%d&frameRate=%d&GOP=%d&isVBR=%d&lbrRatio=%d",
                    param->streamType,param->resolution,param->bitRate,param->frameRate,param->GOP,param->isVBR,lbrRation);
            
            if (FosSdk_CallCGIRaw(fFosHandle, cmd, (char *)netConfig->info3, (int *)netConfig->info4,fTimeout) == FOSCMDRET_OK) {
                return true;
            }
//			if(FosSdk_SetSubVideoStreamParam(fFosHandle, (FOS_VIDEOSTREAMPARAM*)netConfig->info, fTimeout) == FOSCMDRET_OK)
//				return true;
		}
		break;
	case FOSCAM_NET_CONFIG_VIDEO_ENCODE_MAIN_STREAM_TYPE:
		{
			if(netConfig->info == NULL)
				return false;
			if(FosSdk_SetMainVideoStreamType(fFosHandle, *(int*)netConfig->info, fTimeout) == FOSCMDRET_OK)
				return true;
		}
		break;
	case FOSCAM_NET_CONFIG_VIDEO_ENCODE_SUB_STREAM_TYPE:
		{
			if(netConfig->info == NULL)
				return false;
			char cmd[100] = {0};
			sprintf(cmd, "cmd=setSubVideoStreamType&streamtype=%d", *(int*)netConfig->info);
			char ret[200] = {0};
			int retLen = 200;
			if(FosSdk_CallCGIRaw(fFosHandle, cmd, ret, &retLen, fTimeout) == FOSCMDRET_OK)
				return true;
		}
		break;
	case FOSCAM_NET_CONFIG_MOTION:
		{
			if(netConfig->info == NULL)
				return false;
			if(FosSdk_SetMotionDetectConfig(fFosHandle, (FOS_MOTIONDETECTCONFIG*)netConfig->info, fTimeout) == FOSCMDRET_OK)
			{
				return true;
			}
		}
		break;
	case FOSCAM_NET_CONFIG_VIDEO_MIRROR:
		{
			if(netConfig->info == NULL)
				return false;
			if(FosSdk_MirrorVideo(fFosHandle, *(int*)netConfig->info, fTimeout) == FOSCMDRET_OK)
			{
				return true;
			}
		}
		break;
	case FOSCAM_NET_CONFIG_VIDEO_FLIP:
		{
			if(netConfig->info == NULL)
				return false;
			if(FosSdk_FlipVideo(fFosHandle, *(int*)netConfig->info, fTimeout) == FOSCMDRET_OK)
			{
				return true;
			}
		}
		break;
	case FOSCAM_NET_CONFIG_VIDEO_PWR_FREG:
		{
			if(netConfig->info == NULL)
				return false;
			if(FosSdk_SetPwrFreq(fFosHandle, *(int*)netConfig->info, fTimeout) == FOSCMDRET_OK)
			{
				return true;
			}
		}
		break;
	case FOSCAM_NET_CONFIG_ALARM_AUDIO:
		{
			if(netConfig->info == NULL)
				return false;
			FOS_AudioAlarmSetting *config = (FOS_AudioAlarmSetting*)netConfig->info;
			if(FosSdk_SetAudioAlarmConfig(fFosHandle, fTimeout, config) == FOSCMDRET_OK)
			{
				return true;
			}
		}
		break;
	case FOSCAM_NET_CONFIG_PTZ_SPEED:
		{
			if(netConfig->info == NULL)
				return false;

			if( FosSdk_PTZSetSpeed(fFosHandle, (FOSPTZ_SPEED)*(int*)netConfig->info, fTimeout) == FOSCMDRET_OK)
			{
				return true;
			}
		}
		break;
	case FOSCAM_NET_CONFIG_PTZ_TEST_MODE:
		{
			if(netConfig->info == NULL)
				return false;
			if(FosSdk_PTZSetSelfTestMode(fFosHandle, (FOS_PTZSELFTESTMODE)*(int*)netConfig->info, fTimeout) == FOSCMDRET_OK)
			{
				return true;
			}
		}
		break;
    case FOSCAM_NET_CONFIG_VIDEO_OSD_MASK_ENABLE:
        {
            if(netConfig->info == NULL)
                return false;
            if(FosSdk_SetOSDMask(fFosHandle, *((int*)netConfig->info), fTimeout) == FOSCMDRET_OK)
                return true;
        }
        break;
        case FOSCAM_NET_CONFIG_NETWORK_WIFI:
        {
            if(netConfig->info == NULL)
                return false;
            if(FosSdk_SetWifiSetting(fFosHandle, fTimeout, (FOS_WIFISETTING*)netConfig->info) == FOSCMDRET_OK)
                return true;
        }
            break;
        case FOSCAM_NET_CONFIG_NETWORK_DDNS:
        {
            if(netConfig->info == NULL)
                return false;
            if(FosSdk_SetDDNSConfig(fFosHandle, fTimeout, (FOS_DDNSCONFIG*)netConfig->info) == FOSCMDRET_OK)
                return true;
        }
            break;
        case FOSCAM_NET_CONFIG_NETWORK_DDNS_RESTORE_TO_FACTORY:
        {
            return false;
        }
            break;
        case FOSCAM_NET_CONFIG_NETWORK_FTP:
        {
            if(netConfig->info == NULL)
                return false;
            if(FosSdk_SetFtpConfig(fFosHandle, fTimeout, (FOS_FTPCONFIG*)netConfig->info) == FOSCMDRET_OK)
                return true;
        }
            break;
        case FOSCAM_NET_CONFIG_NETWORK_SMTP:
        {
            if(netConfig->info == NULL)
                return false;
            if(FosSdk_SetSMTPConfig(fFosHandle, fTimeout, (FOS_SMTPCONFIG*)netConfig->info) == FOSCMDRET_OK)
                return true;
        }
            break;
        case FOSCAM_NET_CONFIG_DEVICE_LED_ENABLE_STATE:
        {
            if(netConfig->info == NULL)
                return false;
            if(FosSdk_SetLedEnableState(fFosHandle, fTimeout, *((int *)netConfig->info)) == FOSCMDRET_OK)
                return true;
        }
            break;
        case FOSCAM_NET_CONFIT_DEVICE_SYSTEM_TIME:
        {
            if(netConfig->info == NULL)
                return false;
            if(FosSdk_SetSystemTime(fFosHandle, fTimeout, (FOS_DEVSYSTEMTIME*)netConfig->info) == FOSCMDRET_OK) {
                FOS_DEVSYSTEMTIME *tm = (FOS_DEVSYSTEMTIME*)netConfig->info;
                return true;
            }
        }
            break;
            case FOSCAM_NET_CONFIG_PTZ_CRUISE_CTRL_MODE:
        {
            if(netConfig->info == NULL)
                return false;
            FOS_CRUISECTRLMODE mode = *((FOS_CRUISECTRLMODE *)netConfig->info);
            FOSCMD_RESULT ret = FosSdk_PTZSetCruiseCtrlMode(fFosHandle, mode, fTimeout);
            
            if (ret == FOSCMDRET_OK) {
                return true;
            }
            
            CHECK_FOS_RESULT("FosSdk_PTZSetCruiseCtrlMode", ret);
        }
            break;
            case FOSCAM_NET_CONFIG_PTZ_CRUISE_LOOP_CNT:
        {
            if(netConfig->info == NULL)
                return false;
            
            int count = *((int *)netConfig->info);
            FOSCMD_RESULT ret = FosSdk_PTZSetCruiseLoopCnt(fFosHandle, count, fTimeout);
            
            if (ret == FOSCMDRET_OK) {
                return true;
            }
            else {
                printf("Call FosSdk_PTZSetCruiseLoopCnt faied,ret code = %d",ret);
                return false;
            }
        }
            break;
            case FOSCAM_NET_CONFIG_PTZ_CRUISE_TIME:
        {
            if(netConfig->info == NULL)
                return false;
            unsigned int time = *((unsigned int *)netConfig->info);
            if (FosSdk_PTZSetCruiseTime(fFosHandle, time, fTimeout) == FOSCMDRET_OK) {
                return true;
            }
        }
            break;
            case FOSCAM_NET_CONFIG_PTZ_CRUISE_TIME_CUSTOM:
        {
            if(netConfig->info == NULL)
                return false;
            if (FosSdk_PTZSetCruiseTimeCustomed(fFosHandle, (FOS_CRUISETIMECUSTOMED *)netConfig->info, fTimeout) == FOSCMDRET_OK ) {
                return true;
            }
        }
            break;
            case FOSCAM_NET_CONFIG_PTZ_SELF_TEST_PRESET_NAME:
        {
            if(netConfig->info == NULL)
                return false;
            if (FosSdk_PTZSetPrePointForSelfTest(fFosHandle,(char *)netConfig->info,fTimeout) == FOSCMDRET_OK) {
                return true;
            }
        }
            break;
            case FOSCAM_NET_CONFIG_PTZ_SELF_TEST_MODE:
        {
            if(netConfig->info == NULL)
                return false;
            FOS_PTZSELFTESTMODE mode = *((FOS_PTZSELFTESTMODE *)netConfig->info);
            if (FosSdk_PTZSetSelfTestMode(fFosHandle, mode, fTimeout) == FOSCMDRET_OK) {
                return true;
            }
        }
            break;
            case FOSCAM_NET_CONFIG_PTZ_PATTERN_MAP_INFO:
        {
            if(netConfig->info == NULL)
                return false;
            if (FosSdk_PTZSetCruiseMap(fFosHandle, (FOS_CRUISEMAPINFO *)netConfig->info, fTimeout) == FOSCMDRET_OK) {
                return true;
            }
        }
            break;
            case FOSCAM_NET_CONFIG_PTZ_PATTERN_DEL:
        {
            if(netConfig->info == NULL)
                return false;
            if(FosSdk_PTZDelCruiseMap(fFosHandle,(char *)netConfig->info, fTimeout) == FOSCMDRET_OK) {
                return true;
            }
        }
            case FOSCAM_NET_CONFIG_PTZ_CRUISE_MAP_PREPOINT_TINGGER_TIME:
        {
            if(netConfig->info == NULL)
                return false;
            if (FosSdk_PTZSetCruisePrePointLingerTime(fFosHandle, (FOS_CRUISEMAPPREPOINTLINGERTIME *)netConfig->info, fTimeout) == FOSCMDRET_OK) {
                return true;
            }
        }
            break;
        case FOSCAM_NET_CONFIG_PTZ_ADD_PRESET_POINT: {
            if(netConfig->info == NULL)
                return false;
            FOSCAM_NET_CONFIG_TEST *test = (FOSCAM_NET_CONFIG_TEST *)netConfig->info;
            if (FosSdk_PTZAddPresetPoint(fFosHandle, (char *)test->input, fTimeout, (FOS_RESETPOINTLIST *)test->result) == FOSCMDRET_OK) {
                return true;
            }
        }
            break;
        case FOSCAM_NET_CONFIG_PTZ_DEL_PRESET_POINT:
        {
            if (netConfig->info == NULL)
                return  false;
            FOSCAM_NET_CONFIG_TEST *test = (FOSCAM_NET_CONFIG_TEST *)netConfig->info;
            if (FosSdk_PTZDelPresetPoint(fFosHandle, (char *)test->input, fTimeout, (FOS_RESETPOINTLIST *)test->result) == FOSCMDRET_OK) {
                return true;
            }
        }
            break;
            case FOSCAM_NET_CONFIG_PTZ_RUN_PRESET_POINT:
        {
            if (netConfig->info == NULL)
                return  false;
            
            if (FosSdk_PTZGoToPresetPoint(fFosHandle, (char *)netConfig->info, fTimeout) == FOSCMDRET_OK) {
                return true;
            }
        }
            break;
        case FOSCAM_NET_CONFIG_PTZ_START_CRUISE:
        {
            if (netConfig->info == NULL)
                return  false;
            
            if (FosSdk_PTZStartCruise(fFosHandle, (char *)netConfig->info, fTimeout) == FOSCMDRET_OK) {
                return true;
            }
        }
            break;
        case FOSCAM_NET_CONFIG_PTZ_STOP_CRUISE:
        {
            if (netConfig->info == NULL)
                return  false;
            if (FosSdk_PTZStopCruise(fFosHandle, fTimeout) == FOSCMDRET_OK) {
                return true;
            }
        }
            break;
        case FOSCAM_NET_CONFIG_OSD_MASK_AREA:
        {
            if (netConfig->info == NULL)
                return  false;
            if (FosSdk_SetOsdMaskArea(fFosHandle, (FOS_OSDMASKAREA *)netConfig->info, fTimeout) == FOSCMDRET_OK) {
                return true;
            }
        }
            break;
        case FOSCAM_NET_CONFIG_PC_AUDIO_ALARM:
        {
            if (netConfig->info == NULL)
                return  false;
            if (FosSdk_SetPCAudioAlarmCfg(fFosHandle, *((int *)netConfig->info), fTimeout) == FOSCMDRET_OK) {
                return true;
            }
        }
            break;
        case FOSCAM_NET_CONFIG_VIDEO_SCHEDULE_SNAP:
        {
            if (netConfig->info == NULL)
                return false;
            if (FosSdk_SetScheduleSnapConfig(fFosHandle, (FOS_SCHEDULESNAPCONFIG *)netConfig->info, fTimeout) == FOSCMDRET_OK) {
                return true; 
            }
        }
        case FOSCAN_NET_CONFIG_VIDEO_SNAP:
        {
            if (netConfig->info == NULL)
                return false;
            if (FosSdk_SetSnapConfig(fFosHandle, (FOS_SNAPCONFIG *)netConfig->info, fTimeout) == FOSCMDRET_OK) {
                return true;
            }
        }
            break;
	}

	return false;
}

bool CFoscamIPCClient::setEventCB( NET_Event_CallBack cbNetEvent, void *userData )
{
	//CAutoLock lk(&fFoscamIPCClientBaseCS);
    pthread_auto_lock lk(&_mutex);
    
	fEventCB = cbNetEvent;
	fEventUserData = userData;

	return true;
}

bool CFoscamIPCClient::retain()
{
	//CAutoLock lk(&fFoscamIPCClientBaseCS);
    pthread_auto_lock lk(&_mutex);
    
	return fRetain;
	
}

void CFoscamIPCClient::retain( bool val )
{
	//CAutoLock lk(&fFoscamIPCClientBaseCS);
    pthread_auto_lock lk(&_mutex);
    
	fRetain = val;
}

bool CFoscamIPCClient::getEventData( FOSCAM_IPC_NET_EVENT_DATA* eventData )
{
	//CAutoLock lk(&fFoscamIPCClientBaseCS);
    pthread_auto_lock lk(&_mutex);
    
	if (eventData == NULL)
	{
		return false;
	}
	memcpy(eventData, &fEventData, sizeof(FOSCAM_IPC_NET_EVENT_DATA));

	return true;
}

bool CFoscamIPCClient::talk( char* data, int dataLen )
{
    if (!fIsLogin)
    {
        return false;
    }
    if (data == NULL || dataLen < 0)
    {
        return false;
    }
    
    if(FosSdk_SendTalkData(fFosHandle, data, dataLen) == FOSCMDRET_OK)
        return true;
    
    return false;
}

bool CFoscamIPCClient::openTalk()
{
    if (!fIsLogin)
    {
        return false;
    }
    
    int ret = FosSdk_OpenTalk(fFosHandle, fTimeout);
    if(ret == FOSCMDRET_OK)
        return true;

    
    printf("failed to open talk ,ret = %d\n",ret);
    return false;
}

bool CFoscamIPCClient::closeTalk()
{
    if (!fIsLogin)
    {
        return false;
    }
    
    if(FosSdk_CloseTalk(fFosHandle, fTimeout) == FOSCMDRET_OK)
        return true;
    
    return false;
}
