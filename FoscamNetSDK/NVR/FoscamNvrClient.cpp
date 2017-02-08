#include "FoscamNvrClient.h"
#include <iostream>

void *doEventCB(void* pParam)
//unsigned int __stdcall doEventCB(void* pParam)
{
	if(pParam != NULL)
	{
		CFoscamNvrClient* p = (CFoscamNvrClient*)pParam;
		p->doEvent();
	}

	return 0;
}


CFoscamNvrClient::CFoscamNvrClient(void):
fRetain(false),
fIsLogin(false),
fShortTimeOutMS(500),
fLongTimeOutMS(10000),
/*fEventHandle(NULL),*/
fEventThread(NULL),
fIsEventThread(false),
_chn_cnt(0)
{
    fHandle = 0;
    
    pthread_mutexattr_t attr;
    pthread_mutexattr_init(&attr);
    pthread_mutexattr_settype(&attr,PTHREAD_MUTEX_RECURSIVE);
    
    pthread_mutex_init(&_mutex, NULL);
    pthread_mutex_init(&_mutex, &attr);
    
    //初始化条件锁
    pthread_mutex_init(&_mutex_cond, NULL);
    pthread_mutex_init(&_mutex_cond, &attr);
}

CFoscamNvrClient::~CFoscamNvrClient(void)
{
	stop();
}

bool CFoscamNvrClient::isLogin()
{
	//CAutoLock lk(&fFoscamNvrClientCS);
    pthread_auto_lock lk(&_mutex);
	return fIsLogin;
}

void CFoscamNvrClient::isLogin( bool val )
{
	//CAutoLock lk(&fFoscamNvrClientCS);
    pthread_auto_lock lk(&_mutex);
	fIsLogin = val;	
}

long CFoscamNvrClient::userID()
{
	//CAutoLock lk(&fFoscamNvrClientCS);
    pthread_auto_lock lk(&_mutex);
	return fUserID;
}

void CFoscamNvrClient::userID( long val )
{
	//CAutoLock lk(&fFoscamNvrClientCS);
    pthread_auto_lock lk(&_mutex);
	fUserID = val;
}

bool CFoscamNvrClient::login( LOGIN_DATA *loginData )
{
	//CAutoLock lk(&fFoscamNvrClientCS);
    pthread_auto_lock lk(&_mutex);
    
	if (fHandle > 0)
	{
		return true;
	}
	
	bool ret = login(fHandle, loginData);
	if (ret)
	{
		fLoginData = *loginData;
		fIsLogin = ret;

        pthread_condattr_t condattr;
        pthread_condattr_init(&condattr);
        pthread_cond_init(&fEventHandle, &condattr);
        
        
		fIsEventThread = true;
		
        pthread_attr_t attr;
        pthread_attr_init(&attr);
        pthread_create(&fEventThread, &attr, doEventCB, (void *)this);
	}

	return ret;
}

bool CFoscamNvrClient::searchRecordFiles(int channels,
                                         long long st,
                                         long long et,
                                         FOSNVR_RECORDTYPE type,
                                         int *nodeCount)
{
    pthread_auto_lock lk(&_mutex);
    if (!fIsLogin)
    {
        return false;
    }
    
    FOSCMD_RESULT result = FosNvr_SearchRecordFiles(fHandle,st,et,channels,type,nodeCount,fLongTimeOutMS);
    
    return FOSCMDRET_OK == result;
}

bool CFoscamNvrClient::getIPCList(FOSNVR_IpcNode* ipcNode, int *size)
{
    pthread_auto_lock lk(&_mutex);
    
    if (!fIsLogin) {
        return false;
    }
    
    FOSCMD_RESULT result = FosNvr_GetIPCList(fHandle, ipcNode, size, fLongTimeOutMS);
    
    return FOSCMDRET_OK == result;
}

bool CFoscamNvrClient::getRecordNodeInfo(long userID,int nodeIdx,FOSNVR_RecordNode *node)
{
    pthread_auto_lock lk(&_mutex);
    if (!fIsLogin)
    {
        return false;
    }
    
    return FOSCMDRET_OK == FosNvr_GetRecordNodeInfo(fHandle,nodeIdx,node);
}

bool CFoscamNvrClient::login( FOSHANDLE& fos, LOGIN_DATA *loginData)
{
    pthread_auto_lock lk(&_mutex);
    loginData->result = FOSCMDRET_FAILD;
    
    fos = FosNvr_Create(loginData->ip,
                        loginData->port,
                        loginData->ip,
                        loginData->port,
                        loginData->uid,
                        loginData->mac,
                        loginData->user,
                        loginData->psw);
    
	if (fos <= 0)
	{
		return false;
	}
	
	int usrRight = 0;
    int ret = FosNvr_Login(fos, &usrRight, &_chn_cnt, fShortTimeOutMS);
	
    
    loginData->result = ret;
    
    
    switch (ret) {
        case FOSCMDRET_NEED_SET_PASSWORD:
        case FOSCMDRET_OK:
            return true;
            
        default:
            break;
    }
    
    FosNvr_Release(fos);
    fos = 0;
    
    return false;
}

bool CFoscamNvrClient::logout()
{
	//CAutoLock lk(&fFoscamNvrClientCS);
    pthread_auto_lock lk(&_mutex);
    
	if (fHandle > 0)
	{
		int count = 0;
		for (int i = 0; i < MAX_CHANNEL_NUMBER; i++)
		{
			if (fStream[i].isPlay() && fStream[i].getHandle() == fHandle)
            {
                fStream[i].stopRealPlay();
                fStream[i].stopPlayback();
			}
		}

        logout(fHandle, fLoginData.ip);
        fHandle = 0;
	}

//	if (fHandle[1] > 0)
//	{
//		int count = 0;
//		for (int i = 0; i < MAX_CHANNEL_NUMBER; i++)
//		{
//			if (fStream[i].isPlay() && fStream[i].getHandle() == fHandle[1])
//			{
//				count++;
//			}
//		}
//
//		if (count <= 0)
//		{
//			logout(fHandle[1], fLoginData.ip);
//			fHandle[1] = 0;
//		}
//	}
//
//	if (fHandle[0] == 0 && fHandle[1] == 0)
//	{
//		fIsLogin = false;
//	}

//	if(fEventHandle != NULL)
//		SetEvent(fEventHandle);
//	if(fEventThread != NULL)
//		WaitForSingleObject(fEventThread, INFINITE);
//	CLOSE_HANDLE(fEventHandle);
//	CLOSE_HANDLE(fEventThread);

    //通知事件线程退出
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
    //销毁等待信号
    pthread_cond_destroy(&fEventHandle);
    return true;
}

bool CFoscamNvrClient::modifyLoginInfo(char *newName, char* newPwd,char *result,int *len)
{
    pthread_auto_lock lk(&_mutex);
    
    if (fHandle == 0) {
        return false;
    }
    
    char data[256];
    sprintf(data, "cmd=changeUserNameAndPwdTogether&usrName=admin&newUsrName=%s&oldPwd=&newPwd=%s",newName,newPwd);
    return FOSCMDRET_OK == FosNvr_GetCGIResult2(fHandle, data, result, len, fLongTimeOutMS);
}

bool CFoscamNvrClient::logout( FOSHANDLE fos, char* url )
{
    pthread_auto_lock lk(&_mutex);
    
    if (fos == 0 )
    {
        return false;
    }
    
    FosNvr_LogOut(fos, fShortTimeOutMS);
    FosNvr_Release(fos);
    //NVRSdk_LoginOut(fos);
    //NVRSdk_Release(fos, url);
    
#if 0
    char msg[255] = {0};
    //sprintf(msg, "input data pt %f\r\n", time_2_dbl(pt));
	sprintf(msg, "foscam nvr sdk NVRSdk_Logout success ip %s\n", fLoginData.ip);
	::OutputDebugString(msg);
#endif

	return true;
}

bool CFoscamNvrClient::ptz( long channel, PTZ_CMD ptz )
{
	//CAutoLock lk(&fFoscamNvrClientCS);
    pthread_auto_lock lk(&_mutex);
    
	if (!fIsLogin)
	{
		return false;
	}

	char cmd[128] = {0};
    int len = 32;
    char result[len];
    
	switch (ptz.ptzCmd)
	{
	case FOSCAM_IPC_PTZ_CMD_STOP_ALL:
		break;
	case FOSCAM_IPC_PTZ_CMD_ZOOM_IN:
		if (ptz.param1 == 1)
		{
			sprintf(cmd,"cmd=ptzCMD&chnnl=%ld&value=10004",channel);
		}
		else
		{
			sprintf(cmd,"cmd=ptzCMD&chnnl=%ld&value=10006",channel);
		}
		break;
	case FOSCAM_IPC_PTZ_CMD_ZOOM_OUT:
		if (ptz.param1 == 1)
		{
			sprintf(cmd,"cmd=ptzCMD&chnnl=%ld&value=10005",channel);
		}
		else
		{
			sprintf(cmd,"cmd=ptzCMD&chnnl=%ld&value=10006",channel);
		}
		break;
	case FOSCAM_IPC_PTZ_CMD_FOCUS_NEAR:
		break;
	case FOSCAM_IPC_PTZ_CMD_FOCUS_FAR:
		break;
	case FOSCAM_IPC_PTZ_CMD_IRIS_OPEN:
		break;
	case FOSCAM_IPC_PTZ_CMD_IRIS_CLOSE:
		break;

	case FOSCAM_IPC_PTZ_CMD_UP:
		if (ptz.param1 == 1)
		{
			sprintf(cmd,"cmd=ptzCMD&chnnl=%ld&value=10007",channel);
		}
		else
		{
			sprintf(cmd,"cmd=ptzCMD&chnnl=%ld&value=10001",channel);
		}
		break;
	case FOSCAM_IPC_PTZ_CMD_DOWN:
		if (ptz.param1 == 1)
		{
			sprintf(cmd,"cmd=ptzCMD&chnnl=%ld&value=10008",channel);
		}
		else
		{
			sprintf(cmd,"cmd=ptzCMD&chnnl=%ld&value=10001",channel);
		}
		break;
	case FOSCAM_IPC_PTZ_CMD_LEFT:
		if (ptz.param1 == 1)
		{
			sprintf(cmd,"cmd=ptzCMD&chnnl=%ld&value=10009",channel);
		}
		else
		{
			sprintf(cmd,"cmd=ptzCMD&chnnl=%ld&value=10001",channel);
		}
		break;
	case FOSCAM_IPC_PTZ_CMD_RIGHT:
		if (ptz.param1 == 1)
		{
			sprintf(cmd,"cmd=ptzCMD&chnnl=%ld&value=10010",channel);
		}
		else
		{
			sprintf(cmd,"cmd=ptzCMD&chnnl=%ld&value=10001",channel);
		}
		break;
	case FOSCAM_IPC_PTZ_CMD_LEFT_UP:
		if (ptz.param1 == 1)
		{
			sprintf(cmd,"cmd=ptzCMD&chnnl=%ld&value=10011",channel);
		}
		else
		{
			sprintf(cmd,"cmd=ptzCMD&chnnl=%ld&value=10001",channel);
		}
		break;
	case FOSCAM_IPC_PTZ_CMD_LEFT_DOWN:
		if (ptz.param1 == 1)
		{
			sprintf(cmd,"cmd=ptzCMD&chnnl=%ld&value=10013",channel);
		}
		else
		{
			sprintf(cmd,"cmd=ptzCMD&chnnl=%ld&value=10001",channel);
		}
		break;
	case FOSCAM_IPC_PTZ_CMD_RIGHT_UP:
		if (ptz.param1 == 1)
		{
			sprintf(cmd,"cmd=ptzCMD&chnnl=%ld&value=10012",channel);
		}
		else
		{
			sprintf(cmd,"cmd=ptzCMD&chnnl=%ld&value=10001",channel);
		}
	case FOSCAM_IPC_PTZ_CMD_RIGHT_DOWN:
		if (ptz.param1 == 1)
		{
			sprintf(cmd,"cmd=ptzCMD&chnnl=%ld&value=10014",channel);
		}
		else
		{
			sprintf(cmd,"cmd=ptzCMD&chnnl=%ld&value=10001",channel);
		}
		break;
	case FOSCAM_IPC_PTZ_CMD_AUTO:
		if (ptz.param1 == 1)
		{
			sprintf(cmd,"cmd=ptzCMD&chnnl=%ld&value=10000",channel);
		}
		else
		{
			sprintf(cmd,"cmd=ptzCMD&chnnl=%ld&value=10001",channel);
		}
		break;
	case FOSCAM_IPC_PTZ_CMD_ADD_PRESET:
        sprintf(cmd,"cmd=ptzAddPresetPoint&chnnl=%ld&point=%s&Token=xxxx",channel, ptz.param5);
        break;
	case FOSCAM_IPC_PTZ_CMD_CLEAR_PRESET:
		sprintf(cmd,"cmd=ptzDeletePresetPoint&chnnl=%ld&point=%s&Token=xxxx",channel, ptz.param5);
		break;
	case FOSCAM_IPC_PTZ_CMD_GOTO_RRESET:
		sprintf(cmd,"cmd=ptzGotoPresetPoint&chnnl=%ld&point=%s&Token=xxxx",channel, ptz.param5);
		break;
	case FOSCAM_IPC_PTZ_CMD_BEGIN_PATTERN:
		break;
	case FOSCAM_IPC_PTZ_CMD_SET_PATTERN:
		break;
	case FOSCAM_IPC_PTZ_CMD_END_PATTERN:
		break;
	case FOSCAM_IPC_PTZ_CMD_START_PATTERN:
        sprintf(cmd, "cmd=ptzCMD&chnnl=%ld&name=%s&value=10002",channel,ptz.param5);
		break;
	case FOSCAM_IPC_PTZ_CMD_STOP_PATTERN:
        sprintf(cmd, "cmd=ptzCMD&chnnl=%ld&value=10003",channel);
		break;
	}

    return FOSCMDRET_OK == FosNvr_GetCGIResult(fHandle, cmd, result, &len, fShortTimeOutMS);
}

bool CFoscamNvrClient::isExist( LOGIN_DATA loginData )
{
	//CAutoLock lk(&fFoscamNvrClientCS);
    pthread_auto_lock lk(&_mutex);
    
	if (strcmp(loginData.ip, fLoginData.ip) == 0 &&
        strcmp(loginData.user, fLoginData.user) == 0 &&
        strcmp(loginData.uid, fLoginData.uid) == 0 &&
        loginData.port == fLoginData.port)
	{
		return true;
	}
	return false;
}

bool CFoscamNvrClient::retain()
{
	//CAutoLock lk(&fFoscamNvrClientCS);
    pthread_auto_lock lk(&_mutex);
    
	return fRetain;
}

void CFoscamNvrClient::retain( bool val )
{
	//CAutoLock lk(&fFoscamNvrClientCS);
    pthread_auto_lock lk(&_mutex);
    
	fRetain = val;
}


long CFoscamNvrClient::realPlay( LPPREVIEW_INFO previewInfo, FOSCAM_NVR_DataCB dataCB, void* user )
{
    pthread_auto_lock lk(&_mutex);
    
    if (previewInfo == NULL)
    {
        return -1;
    }
    
    if (!fIsLogin)
    {
        return -1;
    }
    
    if (fLoginData.connectType == FOSCNTYPE_P2P) {
        previewInfo->streamType = FOSSTREAM_SUB;
    }
    /*for (int i = 0; i < MAX_FOSCAM_NVR_STREAM; i++)
    {
        if(fStream[i].isPlay())
            return i;
    }*/
    
    FOSHANDLE fos = fHandle;
    if (fos > 0) {
        for (int i = 0; i < MAX_FOSCAM_NVR_STREAM; i++)
        {
            if (!fStream[i].isPlay())
            {
                if(fStream[i].realPlay(fos, previewInfo, dataCB, user))
                    return i;
                else return -1;
            }
            
        }
    }
   
    return -1;
}

/*long CFoscamNvrClient::realPlay( LPPREVIEW_INFO previewInfo, FOSCAM_NVR_DataCB dataCB, void* user )
{
	//CAutoLock lk(&fFoscamNvrClientCS);
    pthread_auto_lock lk(&_mutex);
    
	if (previewInfo == NULL)
	{
		return -1;
	}

	if (!fIsLogin)
	{
		return -1;
	}

	for (int i = 0; i < MAX_FOSCAM_NVR_STREAM; i++)
	{
		if(fStream[i].isPlay() && fStream[i].isExist(previewInfo))
			return i;
	}

	// ∑÷≈‰FOSHANDLE
	FOSHANDLE fos = -1;
	bool isExist = false;
	for (int i = 0; i < MAX_FOSCAM_NVR_STREAM; i++)
	{
		if (fStream[i].isExist((int)previewInfo->channel))
		{
			isExist = true;
			break;
		}
	}
	if (isExist)
	{
		if (fHandle[1] == 0)
		{
			login(fHandle[1], fLoginData);
		}
		fos = fHandle[1];
	}
	else
	{
		fos = fHandle[0];
	}

	if (fos < 0)
	{
		return -1;
	}

	// play
	for (int i = 0; i < MAX_FOSCAM_NVR_STREAM; i++)
	{
		if (!fStream[i].isPlay())
		{
			if(fStream[i].realPlay(fos, previewInfo, dataCB, user))
				return i;
			else return -1;
		}

	}

	return -1;
}*/

bool CFoscamNvrClient::stopRealPlay( long realHandle )
{
	//CAutoLock lk(&fFoscamNvrClientCS);
    pthread_auto_lock lk(&_mutex);
    
	if (realHandle < 0 || realHandle >= MAX_FOSCAM_NVR_STREAM)
	{
		return false;
	}

	return fStream[realHandle].stopRealPlay();
}


long CFoscamNvrClient::playback(LPPLAYBACK_INFO playbackInfo,
                                FOSCAM_NVR_FILEDataCB dataCB,
                                FOSCAM_NVR_FILEEventCB eventCB,
                                void* user)
{
    pthread_auto_lock lk(&_mutex);
    
    if (playbackInfo == NULL)
    {
        return -1;
    }
    
    if (playbackInfo->channels == 0)
    {
        return -1;
    }
    
    if (!fIsLogin)
    {
        return -1;
    }
    

    FOSHANDLE fos = fHandle;
    if (fos > 0) {
        for (int i = 0; i < MAX_FOSCAM_NVR_STREAM; i++)
        {
            if (!fStream[i].isPlay())
            {
                if (fStream[i].playback(fos, playbackInfo, dataCB, eventCB,user))
                    return i;
                else
                    return -1;
            }
        }
    }
    
    return -1;
}

bool CFoscamNvrClient::stopPlayback(long realHandle)
{
    pthread_auto_lock lk(&_mutex);

    if (realHandle < 0 || realHandle >= MAX_FOSCAM_NVR_STREAM)
    {
        return false;
    }
    
    return fStream[realHandle].stopPlayback();
}

bool CFoscamNvrClient::setDownloadPath(char *path)
{
    pthread_auto_lock lk(&_mutex);
    
    return FOSCMDRET_OK == FosNvr_SetDownLoadPath(fHandle, path);
}

bool CFoscamNvrClient::downloadRecord(FOSNVR_RecordNode *files, int count)
{
    pthread_auto_lock lk(&_mutex);
    
    FOSCMD_RESULT ret = FosNvr_DownLoadRecord(fHandle, files, count);
    if (ret != FOSCMDRET_OK) {
        printf("ret=%d,indexNO=%d,tmStart=%u,tmEnd=%u\n",ret,files->indexNO,files->tmStart,files->tmEnd);
    }
    return FOSCMDRET_OK == ret;
}

void CFoscamNvrClient::downLoadCancel()
{
    pthread_auto_lock lk(&_mutex);
    FosNvr_DownLoadCancel(fHandle);
    printf("FosNvr_DownLoadCancel ret=");
}

bool CFoscamNvrClient::sendPlaybackCmd(long realHandle,FOSNVR_PBCMD cmd,int value)
{
    pthread_auto_lock lk(&_mutex);
    
    if (realHandle < 0 || realHandle >= MAX_FOSCAM_NVR_STREAM)
    {
        return false;
    }
    
    return fStream[realHandle].playbackCmd(cmd, value);
}

void CFoscamNvrClient::stop()
{
	//CAutoLock lk(&fFoscamNvrClientCS);
    pthread_auto_lock lk(&_mutex);
    
	for (int i = 0; i < MAX_FOSCAM_NVR_STREAM; i++)
	{
		fStream[i].stopRealPlay();
	}

	if(fHandle > 0)
		logout(fHandle, fLoginData.ip);

//	if(fHandle[1] > 0)
//		logout(fHandle[1], fLoginData.ip);

	fIsLogin = false;
	fHandle = 0;
//	fHandle[1] = 0;
}


void CFoscamNvrClient::doEvent()
{
	DWORD dwWaitTime = 100;//ms
    FOSNVR_EvetData eventData;
    
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
			{
				fIsEventThread = false;
			}
			break;
		case ETIMEDOUT:
			{
				if (FosNvr_GetEvent(fHandle,&eventData) == FOSCMDRET_OK)
				{
                    if (fEventCB) {
                        fEventCB(fUserID, &eventData, fEventUserData);
                    }
				}
			}
			break;
		}
        
        //printf("getEvent\n");
	}
	//DeleteObject(msgdata);
}

bool CFoscamNvrClient::getConfig(long type, void *config)
{
	//CAutoLock lk(&fFoscamNvrClientCS);
    pthread_auto_lock lk(&_mutex);
    
	if (!fIsLogin)
	{
		return false;
	}	

    if (config == NULL)
    {
        return false;
    }
    
    FOSCAM_NVR_CONFIG *nvrCfg = (FOSCAM_NVR_CONFIG *)config;
    
    char cmd[255] = {0};
    switch (type) {
        case FOSCAM_NVR_CONFIG_ABILITY: {
            sprintf(cmd, "cmd=ipcGetAbility&chnnl=%d",*((int *)nvrCfg->input));
        }
            break;
        case FOSCAM_NVR_CONFIG_DEVICE_INFO:
            sprintf(cmd, "cmd=getDevInfo");
            break;
        case FOSCAM_NVR_CONFIG_USER_P2P_INFO:
            sprintf(cmd, "cmd=getUserP2PInfo");
            break;
        case FOSCAM_NVR_CONFIG_DEVICE_SYSTEM_TIME:
            sprintf(cmd, "cmd=getSystemTime");
            break;
        case FOSCAM_NVR_CONFIG_NET:
            sprintf(cmd, "cmd=getIPInfo");
            break;
        case FOSCAM_NVR_CONFIG_SMTP:
            sprintf(cmd, "cmd=getSMTPConfig");
            break;
        case FOSCAM_NVR_CONFIG_SMTP_TEST:
            sprintf(cmd, "cmd=smtpTest");
            break;
        case FOSCAM_NVR_CONFIG_FTP:
            sprintf(cmd, "cmd=getFtpConfig");
            break;
        case FOSCAM_NVR_CONFIG_FTP_TEST:
            sprintf(cmd, "cmd=testFtpServer");
            break;
        case FOSCAM_NVR_CONFIG_DDNS:
            //测试结果有问题
            sprintf(cmd, "cmd=getDDNSConfig");
            break;
        case FOSCAM_NVR_CONFIG_VIDEO_STREAM_PARAM: {
            FOSCAM_NVR_REAL_CH *realChn = (FOSCAM_NVR_REAL_CH *)nvrCfg->input;
            sprintf(cmd, "cmd=getVideoStreamParam&chnnl=%d&streamType=%d",realChn->chn,realChn->streamType);
        }
            break;
        case FOSCAM_NVR_CONFIG_VIDEO_STREAM_CAPABILITIES: {
            FOSCAM_NVR_REAL_CH *realChn = (FOSCAM_NVR_REAL_CH *)nvrCfg->input;
            
            switch (realChn->streamType) {
                case 0:
                    sprintf(cmd, "cmd=getMainStreamCapabilities&chnnl=%d",realChn->chn);
                    break;
                case 1:
                    sprintf(cmd, "cmd=getSubStreamCapabilities&chnnl=%d",realChn->chn);
                    break;
                default:
                    break;
            }
        }
            break;
        case FOSCAM_NVR_CONFIG_HS_MOTION_DETECT: {
            int chn = *((int *)nvrCfg->input);
            sprintf(cmd, "cmd=getMotionDetectConfig&chnnl=%d",chn);
        }
            break;
        case FOSCAM_NVR_CONFIG_AMBA_MOTION_DETECT: {
            int chn = *((int *)nvrCfg->input);
            sprintf(cmd, "cmd=getAnbaMotion&chnnl=%d",chn);
        }
            break;
        case FOSCAM_NVR_CONFIG_RECORD_SCHEDULE: {
            int chn = *((int *)nvrCfg->input);
            sprintf(cmd, "cmd=getScheduleRecordConfig&chnnl=%d",chn);
        }
            
            break;
        case FOSCAM_NVR_CONFIG_IO_ALARM: {
            int chn = *((int *)nvrCfg->input);
            sprintf(cmd, "getIOAlarmConfig&chnnl=%d",chn);
        }
            break;
        case FOSCAM_NVR_CONFIG_OTHER_ALARM: {
            FOSCAM_NVR_OTHER_ALARM alarm = *((FOSCAM_NVR_OTHER_ALARM *)nvrCfg->input);
            switch (alarm) {
                case FOSCAM_NVR_HDD_LOST_ALARM:
                    sprintf(cmd, "cmd=getHDDLostAlarm");
                    break;
                case FOSCAM_NVR_HDD_FULL_ALARM:
                    sprintf(cmd, "cmd=getHDDFullAlarm");
                    break;
                case FOSCAM_NVR_HDD_ERR_ALARM:
                    sprintf(cmd, "cmd=getHDDErrAlarm");
                    break;
                case FOSCAM_NVR_VIDEO_LOST_ALARM:
                    sprintf(cmd, "cmd=getVLAlarm");
                    break;
                case FOSCAM_NVR_NET_LINK_ALARM:
                    sprintf(cmd, "cmd=getNetLinkAlarm");
                    break;
                default:
                    break;
            }
        }
            break;
        case FOSCAM_NVR_CONFIG_OSD: {
            int chn = *((int *)nvrCfg->input);
            sprintf(cmd, "cmd=getOSDSetting&chnnl=%d",chn);
        }
            break;
        case FOSCAM_NVR_CONFIG_OSD_MASK_AREA: {
            int chn = *((int *)nvrCfg->input);
            sprintf(cmd, "cmd=getOsdMaskArea&chnnl=%d",chn);
        }
            break;
        case FOSCAM_NVR_CONFIG_PTZ_SPEED: {
            int chn = *((int *)nvrCfg->input);
            sprintf(cmd, "cmd=getPTZSpeed&chnnl=%d",chn);
        }
            break;
        case FOSCAM_NVR_CONFIG_PTZ_CRUISE_MAP_LIST: {
            int chn = *((int *)nvrCfg->input);
            sprintf(cmd, "cmd=ptzGetCruiseMapList&chnnl=%d",chn);
        }
            break;
        case FOSCAM_NVR_CONFIG_PTZ_CRUISE_MAP_INFO: {
            FOSCAM_NVR_CRUISE_MAP_INFO *nvrCruiseMapInfo = (FOSCAM_NVR_CRUISE_MAP_INFO *)nvrCfg->input;
            sprintf(cmd, "cmd=ptzGetCruiseMapInfo&chnnl=%d&name=%s",
                    nvrCruiseMapInfo->chn,
                    nvrCruiseMapInfo->cruiseMapInfo.cruiseMapName);
        }
            break;
        case FOSCAM_NVR_CONFIG_PTZ_PRESET_POINT_LIST: {
            int chn = *((int *)nvrCfg->input);
            sprintf(cmd, "cmd=getPTZPresetPointList&chnnl=%d",chn);
        }
            break;
        case FOSCAM_NVR_CONFIG_IPC_LIST:{
            int chn = *((int *)nvrCfg->input);
            sprintf(cmd, "cmd=getIPCList&chnnl=%d",chn);
        }
            break;
        case FOSCAM_NVR_CONFIG_DISK_INFO:
            sprintf(cmd, "cmd=getDiskConfig");
            break;
        case FOSCAM_NVR_CONFIG_AUTO_ADD_IPC:
            sprintf(cmd, "cmd=getaddAutoIpc");
            break;
        default:
            break;
    }
	
    //发送cgi命令
    FOSCMD_RESULT ret = FosNvr_GetCGIResult(fHandle, cmd, (char *)nvrCfg->output, &(nvrCfg->outputLen), fLongTimeOutMS);
    
    if (ret == FOSCMDRET_OK) {
        return true;
    }
    else {
        printf("call FosNvr_GetCGIResult failed,return %d\n",ret);
    }

	return false;
}

bool CFoscamNvrClient::setConfig( long type,void *config)
{
	//CAutoLock lk(&fFoscamNvrClientCS);
    pthread_auto_lock lk(&_mutex);
    
	if (!fIsLogin)
	{
		return false;
	}

    if (config == NULL)
    {
        return false;
    }
    
    FOSCAM_NVR_CONFIG *nvrCfg = (FOSCAM_NVR_CONFIG *)config;
    char cmd[1024] = {0};
    switch (type) {
        case FOSCAM_NVR_CONFIG_DEVICE_INFO: {
            sprintf(cmd, "cmd=setDevInfo&devName=%s",(char *)nvrCfg->input);
        }
            break;
        case FOSCAM_NVR_CONFIG_DEVICE_SYSTEM_TIME: {
            FOS_NVR_DEVSYSTEMTIME *nvrSystemTime = (FOS_NVR_DEVSYSTEMTIME *)nvrCfg->input;
            sprintf(cmd, "cmd=setSystemTime&timeSource=%d&ntpServer=%s&\
                    dateFormat=%d&timeFormat=%d&timeZone=%d&year=%d&month=%d&\
                    day=%d&hour=%d&min=%d&sec=%d&isDst=%d&dst=%d&syncIPCTime=%d",
                    1 - nvrSystemTime->devSystemTime.timeSource,
                    nvrSystemTime->devSystemTime.ntpServer,
                    nvrSystemTime->devSystemTime.dateFormat,
                    nvrSystemTime->devSystemTime.timeFormat,
                    nvrSystemTime->devSystemTime.timeZone,
                    nvrSystemTime->devSystemTime.year,
                    nvrSystemTime->devSystemTime.mon,
                    nvrSystemTime->devSystemTime.day,
                    nvrSystemTime->devSystemTime.hour,
                    nvrSystemTime->devSystemTime.minute,
                    nvrSystemTime->devSystemTime.sec,
                    nvrSystemTime->devSystemTime.isDst,
                    nvrSystemTime->devSystemTime.dst,
                    nvrSystemTime->syncIPCTime);
        }
            break;
        case FOSCAM_NVR_CONFIG_NET:{
            FOS_NVR_NETINFO *netInfo = (FOS_NVR_NETINFO *)nvrCfg->input;
            sprintf(cmd, "cmd=setIpInfo&isDHCP=%d&mediaPort=&httpPort=%d&ip=%s&gate=%s&mask=%s&PPPoEUser=&PPPoEPwd=&dns1=%s&dns2=%s&isUPNP=%d&httpsPort=%d",
                    netInfo->ipInfo.isDHCP,
                    netInfo->portInfo.webPort,
                    netInfo->ipInfo.ip,
                    netInfo->ipInfo.gate,
                    netInfo->ipInfo.mask,
                    netInfo->ipInfo.dns1,
                    netInfo->ipInfo.dns2,
                    netInfo->isUPNP,
                    netInfo->portInfo.httpsPort);
        }
            break;
        case FOSCAM_NVR_CONFIG_SMTP:{
            FOS_SMTPCONFIG *smtpCfg = (FOS_SMTPCONFIG *)nvrCfg->input;
            sprintf(cmd, "cmd=setSMTPConfig&isEnable=%d&server=%s&port=%d&isNeedAuthen=%d&isEnableSSL=%d&username=%s&password=%s&sender=%s",
                    smtpCfg->isEnable,
                    smtpCfg->server,
                    smtpCfg->port,
                    smtpCfg->isNeedAuth,
                    smtpCfg->tls,
                    smtpCfg->user,
                    smtpCfg->password,
                    smtpCfg->sender);
            char *token = strtok(smtpCfg->reciever, ",");
            int i = 1;
            while (token != NULL) {
                //判断是否是空
                const char *tmp = (strcmp(token, "#") == 0)? "" : token;
                sprintf(cmd, "%s&reciever%d=%s",cmd,i,tmp);
                token = strtok( NULL, ",");
                i++;
            }
            
        }
            break;
        case FOSCAM_NVR_CONFIG_FTP: {
            FOS_FTPCONFIG *ftpCfg = (FOS_FTPCONFIG *)nvrCfg->input;
            sprintf(cmd, "cmd=setFtpConfig&ftpPort=%d&ftpAddr=%s&ftpMode=%d&ftpuser=%s&ftppwd=%s",
                    ftpCfg->ftpPort,
                    ftpCfg->ftpAddr,
                    ftpCfg->mode,
                    ftpCfg->userName,
                    ftpCfg->password);
        }
            break;
        case FOSCAM_NVR_CONFIG_DDNS: {
            FOS_DDNSCONFIG *ddnsCfg = (FOS_DDNSCONFIG *)nvrCfg->input;
            sprintf(cmd, "cmd=setDDNSConfig&isEnable=%d&hostName=%s&server=%d&userName=%s&passWord=%s",
                    ddnsCfg->isEnable,
                    ddnsCfg->hostName,
                    ddnsCfg->ddnsServer,
                    ddnsCfg->user,
                    ddnsCfg->password);
        }
            break;
        case FOSCAM_NVR_CONFIG_DDNS_RESTORE_TO_FACTORY:{
            
        }
            break;
        case FOSCAM_NVR_CONFIG_VIDEO_STREAM_PARAM: {
            FOS_NVR_VIDEOSTREAMPARAM *nvrVideoStreamParam = (FOS_NVR_VIDEOSTREAMPARAM *)nvrCfg->input;
            /*sprintf(cmd, "cmd=setVideoStreamParam&chnnl=%d&streamType=%d&resWidth=%d&resHeight=%d&bitRate=%d&frameRate=%d&gop=%d&isVbr=%d",
                    nvrVideoStreamParam->chn,
                    nvrVideoStreamParam->videoStreamParam.streamType,
                    nvrVideoStreamParam->resWidth,
                    nvrVideoStreamParam->resHeight,
                    nvrVideoStreamParam->videoStreamParam.bitRate,
                    nvrVideoStreamParam->videoStreamParam.frameRate,
                    nvrVideoStreamParam->videoStreamParam.GOP,
                    nvrVideoStreamParam->videoStreamParam.isVBR);*/
            sprintf(cmd, "cmd=setVideoStreamParam&chnnl=%d&streamType=%d&resWidth=%d&resHeight=%d&bitRate=%d&frameRate=%d&gop=%d&isVbr=%d",
                    nvrVideoStreamParam->chn,
                    nvrVideoStreamParam->videoStreamParam.streamType,
                    nvrVideoStreamParam->resWidth,
                    nvrVideoStreamParam->resHeight,
                    nvrVideoStreamParam->videoStreamParam.bitRate,
                    nvrVideoStreamParam->videoStreamParam.frameRate,
                    nvrVideoStreamParam->videoStreamParam.GOP,
                    nvrVideoStreamParam->videoStreamParam.isVBR);
            printf("%s\n",cmd);
        }
            break;
        case FOSCAM_NVR_CONFIG_HS_MOTION_DETECT:{
            FOS_NVR_MOTION_DETECT_CONFIG *nvrMotionDetectCfg = (FOS_NVR_MOTION_DETECT_CONFIG *)nvrCfg->input;
            sprintf(cmd, "cmd=setMotionDetectConfig&isEnable=%d&linkage=%d&recordTime=%d&sensitivity=%d&triggerInterval=%d&ipcalarmsound=%d",
                    nvrMotionDetectCfg->motionDetectCfg.isEnable,
                    nvrMotionDetectCfg->motionDetectCfg.linkage,
                    nvrMotionDetectCfg->recordTime,
                    nvrMotionDetectCfg->motionDetectCfg.sensitivity,
                    nvrMotionDetectCfg->motionDetectCfg.triggerInterval,
                    nvrMotionDetectCfg->isEnableIPCAudioAlarm);
            
            for (int i = 0; i < FOS_MAX_SCHEDULE_COUNT; i++) {
                sprintf(cmd, "%s&schedule%d=%lld",cmd,i,nvrMotionDetectCfg->motionDetectCfg.schedules[i]);
            }
            
            for (int i = 0; i < FOS_MAX_AREA_COUNT; i++) {
                sprintf(cmd, "%s&area%d=%d",cmd,i,nvrMotionDetectCfg->motionDetectCfg.areas[i]);
            }
            
            sprintf(cmd, "%s&chnnl=%d",cmd,nvrMotionDetectCfg->chn);
            printf("%s\n",cmd);
        }
            break;
        case FOSCAM_NVR_CONFIG_AMBA_MOTION_DETECT:{
            FOS_NVR_MOTION_DETECT_CONFIG1 *nvrMotionDetectCfg = (FOS_NVR_MOTION_DETECT_CONFIG1 *)nvrCfg->input;
            sprintf(cmd, "cmd=setAnbaMotion&enable=%d&linkage=%d&ipcalarmsound=%d&recordTime=%d&triggerInt=%d",
                    nvrMotionDetectCfg->motionDetectCfg.isEnable,
                    nvrMotionDetectCfg->motionDetectCfg.linkage,
                    nvrMotionDetectCfg->isEnableIPCAudioAlarm,
                    nvrMotionDetectCfg->recordTime,
                    nvrMotionDetectCfg->motionDetectCfg.triggerInterval);
            for (int i = 0; i < FOS_MAX_SCHEDULE_COUNT; i++) {
                sprintf(cmd, "%s&schedule%d=%lld",cmd,i,nvrMotionDetectCfg->motionDetectCfg.schedules[i]);
            }
            
            for (int i = 0; i < ANBAMOTIONCOUNT; i++) {
                sprintf(cmd, "%s&x%d=%d&y%d=%d&width%d=%d&height%d=%d",
                        cmd,
                        i,
                        nvrMotionDetectCfg->motionDetectCfg.x[i],
                        i,
                        nvrMotionDetectCfg->motionDetectCfg.y[i],
                        i,
                        nvrMotionDetectCfg->motionDetectCfg.width[i],
                        i,
                        nvrMotionDetectCfg->motionDetectCfg.height[i]);
            }
            for (int i = 0; i < ANBAMOTIONCOUNT; i++) {
                sprintf(cmd, "%s&sensitivity%d=%d&valid%d=%d",
                        cmd,
                        i,
                        nvrMotionDetectCfg->motionDetectCfg.sensitivity[i],
                        i,
                        nvrMotionDetectCfg->motionDetectCfg.valid[i]);
            }
        
            sprintf(cmd, "%s&chnnl=%d",cmd,nvrMotionDetectCfg->chn);
            printf("%s\n",cmd);
        }
            break;
        case FOSCAM_NVR_CONFIG_PTZ_SPEED:{
            FOS_NVR_PTZ_SPEED *nvrPtzSpeed = (FOS_NVR_PTZ_SPEED *)nvrCfg->input;
            sprintf(cmd, "cmd=setPTZSpeed&chnnl=%d&ptzSpeed=%d",
                    nvrPtzSpeed->chn,
                    nvrPtzSpeed->speed);
        }
            break;
        case FOSCAM_NVR_CONFIG_PTZ_CRUISE_MAP_INFO:{
            FOSCAM_NVR_CRUISE_MAP_INFO *nvrCruiseMapInfo = (FOSCAM_NVR_CRUISE_MAP_INFO *)nvrCfg->input;
            sprintf(cmd, "cmd=ptzSetCruiseMap&chnnl=%d&name=%s",
                    nvrCruiseMapInfo->chn,
                    nvrCruiseMapInfo->cruiseMapInfo.cruiseMapName);
            int ptCnt = 0;
            for (int i = 0; i < FOS_MAX_PRESETPOINT_COUNT_OF_MAP; i++) {
                char *pointName = nvrCruiseMapInfo->cruiseMapInfo.pointName[i];
                if (0 == strcmp("", pointName)) {
                    ptCnt++;
                }
                sprintf(cmd, "%s&point%d=%s",cmd,i,pointName);
            }
            sprintf(cmd, "%s&pointNum=%d",cmd,ptCnt);
            printf("%s\n",cmd);
        }
            break;
        case FOSCAM_NVR_CONFIG_PTZ_DEL_CRUISE_MAP:{
            FOSCAM_NVR_CRUISE_MAP_INFO *nvrCruiseMapInfo = (FOSCAM_NVR_CRUISE_MAP_INFO *)nvrCfg->input;
            sprintf(cmd, "cmd=ptzDelCruiseMap&chnnl=%d&name=%s",
                    nvrCruiseMapInfo->chn,
                    nvrCruiseMapInfo->cruiseMapInfo.cruiseMapName);
            printf("%s\n",cmd);
        }
            break;
        case FOSCAM_NVR_CONFIG_RECORD_SCHEDULE: {
            FOS_NVR_SCHEDULERECORDCONFIG *nvrScheduleRecordCfg = (FOS_NVR_SCHEDULERECORDCONFIG *)nvrCfg->input;
            sprintf(cmd, "cmd=setScheduleRecordConfig&chnnl=%d&isEnable=%d",
                    nvrScheduleRecordCfg->chn,
                    nvrScheduleRecordCfg->scheduleRecordCfg.isEnable);
            for (int i = 0; i < FOS_MAX_SCHEDULE_COUNT; i++) {
                sprintf(cmd, "%s&schedule%d=%lld",
                        cmd,
                        i,
                        nvrScheduleRecordCfg->scheduleRecordCfg.schedules[i]);
            }
        }
            break;
        case FOSCAM_NVR_CONFIG_OTHER_ALARM:{
            FOS_NVR_OTHER_ALARM_CONFIG *nvrOtherAlarmConfig = (FOS_NVR_OTHER_ALARM_CONFIG *)nvrCfg->input;
            switch (nvrOtherAlarmConfig->alarmType) {
                case FOSCAM_NVR_HDD_LOST_ALARM:
                    sprintf(cmd, "cmd=setHDDLostAlarm&buzzer=%d",
                            nvrOtherAlarmConfig->buzzer);
                
                    break;
                case FOSCAM_NVR_HDD_FULL_ALARM:
                    sprintf(cmd, "cmd=setHDDFullAlarm&buzzer=%d",
                            nvrOtherAlarmConfig->buzzer);
                    break;
                case FOSCAM_NVR_HDD_ERR_ALARM:
                    sprintf(cmd, "cmd=setHDDErrAlarm&buzzer=%d",
                            nvrOtherAlarmConfig->buzzer);
                    break;
                case FOSCAM_NVR_VIDEO_LOST_ALARM:
                    sprintf(cmd, "cmd=setVLAlarm&buzzer=%d",
                            nvrOtherAlarmConfig->buzzer);
                    break;
                case FOSCAM_NVR_NET_LINK_ALARM:
                    sprintf(cmd, "cmd=setNetLinkAlarm&buzzer=%d",
                            nvrOtherAlarmConfig->buzzer);
                    break;
                default:
                    break;
            }
        }
            break;
        case FOSCAM_NVR_CONFIG_OSD:{
            FOS_NVR_OSDConfigMsg *nvrOsdConfigMsg = (FOS_NVR_OSDConfigMsg *)nvrCfg->input;
            sprintf(cmd, "cmd=setOSDSetting&chnnl=%d&name=%s&isEnableChName=%d&disPosition=%d&isEnableTimeDisplay=%d",
                    nvrOsdConfigMsg->chn,
                    nvrOsdConfigMsg->osdConfigMsg.devName,
                    nvrOsdConfigMsg->osdConfigMsg.isEnableDevName,
                    nvrOsdConfigMsg->osdConfigMsg.dispPos,
                    nvrOsdConfigMsg->osdConfigMsg.isEnableTimeStamp);
        }
            break;
        case FOSCAM_NVR_CONFIG_OSD_MASK_AREA:{
            FOS_NVR_OSDMASKAREA_CONFIG *nvrOsdMaskAreaConfig = (FOS_NVR_OSDMASKAREA_CONFIG *)nvrCfg->input;
            sprintf(cmd, "cmd=setOsdMaskArea&chnnl=%d&isEnableOsdMask=%d",
                    nvrOsdMaskAreaConfig->chn,
                    nvrOsdMaskAreaConfig->isEnableOsdMask);
            for (int i = 0; i < FOS_MAX_OSDMASKAREA_COUNT; i++) {
                sprintf(cmd, "%s&x1_%d=%d&y1_%d=%d&x2_%d=%d&y2_%d=%d",
                        cmd,
                        i,
                        nvrOsdMaskAreaConfig->osdMaskArea.x1[i],
                        i,
                        nvrOsdMaskAreaConfig->osdMaskArea.y1[i],
                        i,
                        nvrOsdMaskAreaConfig->osdMaskArea.x2[i],
                        i,
                        nvrOsdMaskAreaConfig->osdMaskArea.y2[i]);
                
            }
            sprintf(cmd, "%s&copy=1",cmd);
        }
            break;
        case FOSCAM_NVR_CONFIG_SYSTEM_EXPORT:
            sprintf(cmd, "cmd=exportConfig");
            break;
        case FOSCAM_NVR_CONFIG_SYSTEM_IMPORT:
            sprintf(cmd, "cmd=importConfig");
            break;
        case FOSCAM_NVR_CONFIG_SYSTEM_UPDATE:
            sprintf(cmd, "cmd=fwUpgrade");
            break;
        case FOSCAM_NVR_CONFIG_SYSTEM_RESET:
            sprintf(cmd, "cmd=restoreToFactorySetting");//restoreToFactorySetting
            break;
        case FOSCAM_NVR_CONFIG_SYSTEM_RESTART:
            sprintf(cmd, "cmd=rebootSystem");
            break;
        case FOSCAM_NVR_CONFIG_ADD_IPC_LIST: {
            FOS_CHANNEL_INFO *chnInfo = (FOS_CHANNEL_INFO *)nvrCfg->input;
            sprintf(cmd, "cmd=addIPCList&chnnl=%d&ipAddr=%s&httpPort=%d&mediaPort=%d&userName=%s&pwd=%s&devName=%s&isEnable=1&productType=%d&xAddr=%s&ptcls=%d&devMac=%s",
                    chnInfo->ch,
                    chnInfo->url,
                    chnInfo->webPort,
                    chnInfo->mediaPort,
                    chnInfo->username,
                    chnInfo->password,
                    chnInfo->devName,
                    chnInfo->productType,
                    chnInfo->xAddr,
                    chnInfo->protocol,
                    chnInfo->devMac);
        }
            break;
        case FOSCAM_NVR_CONFIG_DEL_IPC_LIST: {
            int chn = *((int *)nvrCfg->input);
            sprintf(cmd, "cmd=delIPCList&chnnl=%d",chn);
        }
            break;
        case FOSCAM_NVR_CONFIG_DISK_INFO:{
            FOS_NVR_DISK_CONFIG *diskCfg = (FOS_NVR_DISK_CONFIG *)nvrCfg->input;
            sprintf(cmd, "cmd=setDiskConfig&diskRewrite=%d&previewTime=%d",
                    diskCfg->diskRewrite,
                    diskCfg->previewTime);
        }
            break;
        case FOSCAM_NVR_CONFIG_DISK_FORMAT:{
            FOS_NVR_DISK_FORMAT_CONFIG *nvrDiskFormatCfg = (FOS_NVR_DISK_FORMAT_CONFIG *)nvrCfg->input;
            sprintf(cmd, "cmd=formatHardDisk&diskNum=%d&type=%d",
                    nvrDiskFormatCfg->diskNum,
                    nvrDiskFormatCfg->type);
        }
            break;
        case FOSCAM_NVR_CONFIG_AUTO_ADD_IPC:{
            int autoAddIpc = *((int *)nvrCfg->input);
            sprintf(cmd, "cmd=setaddAutoIpc&isEnabledAdd=%d",
                    autoAddIpc);
        }
            break;
    }
    
    if (FOSCMDRET_OK == FosNvr_GetCGIResult(fHandle, cmd, (char *)nvrCfg->output, &(nvrCfg->outputLen), fLongTimeOutMS))
    {
        return true;
    }
	return true;
}

int CFoscamNvrClient::getChannelCount()
{
    pthread_auto_lock lk(&_mutex);
	
    return _chn_cnt;
}

bool CFoscamNvrClient::setEventCB(FOSCAM_NVR_EventCB cbNetEvent, void *userData)
{
    pthread_auto_lock lk(&_mutex);
    
    fEventCB = cbNetEvent;
    fEventUserData = userData;
    
    return true;
}

void CFoscamNvrClient::setTimeOut(int shortTimeOutMS,int longTimeOutMS)
{
    pthread_auto_lock lk(&_mutex);
    
    fShortTimeOutMS = shortTimeOutMS;
    fLongTimeOutMS = longTimeOutMS;
}
