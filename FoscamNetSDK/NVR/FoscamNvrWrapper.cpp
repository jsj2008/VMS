#include "FoscamNvrWrapper.h"
#include "../IPCSDK_for_mac150629/include/FosNvrDef.h"
#include "../IPCSDK_for_mac150629/include/fosnvrsdk.h"
//#include "NVRDef.h"
//#include "nvrsdk.h"

static bool g_Init = false;
CFoscamNvrWrapper::CFoscamNvrWrapper(void)
{
	for (int i = 0; i < MAX_FOSCAM_NVR_CLIENT; i++)
	{
        this->fFoscamNvrClient[i].userID(i);
		//CFoscamNvrWrapper::instance().fFoscamNvrClient[i].userID(i);
	}
}

CFoscamNvrWrapper::~CFoscamNvrWrapper(void)
{
	stop();
}

bool CFoscamNvrWrapper::init()
{
	if (g_Init)
	{
		return false;
	}
	g_Init = true;
    
    return FosNvr_Init() == FOSCMDRET_OK;
	//NVRSdk_StartP2PProxy();
	//return NVRSdk_Init();
}

bool CFoscamNvrWrapper::cleanup()
{
	if (!g_Init)
	{
		return false;
	}
	CFoscamNvrWrapper::instance().stop();

	//NVRSdk_StopP2PProxy();
	//pNVRSdk_DeInit();
    FosNvr_DeInit();
	g_Init = false;
	
	return true;
}

void CFoscamNvrWrapper::setTimeOut(int shortTimeOutMS,int longTimeOutMS)
{
    if (g_Init) {
        for (int i = 0; i < MAX_FOSCAM_NVR_CLIENT; i++) {
            fFoscamNvrClient[i].setTimeOut(shortTimeOutMS, longTimeOutMS);
        }
    }
}

CFoscamNvrWrapper& CFoscamNvrWrapper::instance()
{
	static CFoscamNvrWrapper n;
	return n;
}

long CFoscamNvrWrapper::login(LOGIN_DATA *loginData)
{
    long userID = -1;
    
    //安全区，同一时刻，只有一个线程可以访问
    {
        pthread_auto_lock lk(&_mutex);
        for (int i = 0; i < MAX_FOSCAM_NVR_CLIENT; i++)
        {
            if (!fFoscamNvrClient[i].isLogin() && !fFoscamNvrClient[i].retain())
            {
                userID = i;
                fFoscamNvrClient[i].retain(true);
                break;
            }
        }
    }
    
    if (userID == -1)
    {
        return -1;
    }
    
    if (fFoscamNvrClient[userID].login(loginData))
    {
        fFoscamNvrClient[userID].retain(false);
        return userID;
    }
    else
    {
        fFoscamNvrClient[userID].retain(false);
        return -1;
    }
}

//long CFoscamNvrWrapper::login( LOGIN_DATA loginData )
//{
//	for (int i = 0; i < MAX_FOSCAM_NVR_CLIENT; i++)
//	{
//		if (fFoscamNvrClient[i].isLogin() && fFoscamNvrClient[i].isExist(loginData))
//			return i;
//	}
//	
//	long userID = -1;
//	for (int i = 0; i < MAX_FOSCAM_NVR_CLIENT; i++)
//	{
//		if (!fFoscamNvrClient[i].isLogin())
//		{
//			userID = i;
//			fFoscamNvrClient[i].retain(true);
//			break;
//		}
//	}
//
//	if (userID == -1)
//	{
//		return -1;
//	}
//
//	if (fFoscamNvrClient[userID].login(loginData))
//	{
//		fFoscamNvrClient[userID].retain(false);
//		return userID;
//	}
//	else
//	{
//		fFoscamNvrClient[userID].retain(false);
//		return -1;
//	}
//}

bool CFoscamNvrWrapper::logout( long userID )
{
	if (userID < 0 || userID >= MAX_FOSCAM_NVR_CLIENT)
	{
		return -1;
	}

	return fFoscamNvrClient[userID].logout();
}

bool CFoscamNvrWrapper::modifyLoginInfo(long userID, char *newName, char* newPwd,char *result,int *len)
{
    if (userID >= 0 && userID < MAX_FOSCAM_NVR_CLIENT) {
        return fFoscamNvrClient[userID].modifyLoginInfo(newName,newPwd,result,len);
    }
    
    return false;
}

long CFoscamNvrWrapper::realPlay( long userID, LPPREVIEW_INFO previewInfo, FOSCAM_NVR_DataCB dataCB, void* user )
{
	if (userID < 0 || userID >= MAX_FOSCAM_NVR_CLIENT)
	{
		return -1;
	}

	long ret = fFoscamNvrClient[userID].realPlay(previewInfo, dataCB, user);
	return ret;
}


bool CFoscamNvrWrapper::stopRealPlay( long userID, long realHandle )
{
	if (realHandle < 0 || realHandle >= MAX_FOSCAM_NVR_STREAM)
	{
		return -1;
	}

	return fFoscamNvrClient[userID].stopRealPlay(realHandle);
}


long CFoscamNvrWrapper::playback(long userID,LPPLAYBACK_INFO pbInfo,FOSCAM_NVR_FILEDataCB dataCB,FOSCAM_NVR_FILEEventCB eventCB,void *user)
{
    if (userID < 0 || userID >= MAX_FOSCAM_NVR_CLIENT)
    {
        return -1;
    }
    
    long ret = fFoscamNvrClient[userID].playback(pbInfo, dataCB, eventCB,user);
    return ret;
}

bool CFoscamNvrWrapper::stopPlayback(long userID, long realHandle)
{
    if (realHandle < 0 || realHandle >= MAX_FOSCAM_NVR_STREAM)
    {
        return false;
    }
    
    return fFoscamNvrClient[userID].stopPlayback(realHandle);
}

bool CFoscamNvrWrapper::sendPlaybackCmd(long userID,long realHandle,FOSNVR_PBCMD cmd,int value)
{
    if (realHandle < 0 || realHandle >= MAX_FOSCAM_NVR_STREAM)
    {
        return false;
    }
    
    return fFoscamNvrClient[userID].sendPlaybackCmd(realHandle, cmd, value);
}

bool CFoscamNvrWrapper::setDownloadPath(long userID,char *path)
{
    if (userID < 0 || userID >= MAX_FOSCAM_NVR_CLIENT)
    {
        return false;
    }
    
    return fFoscamNvrClient[userID].setDownloadPath(path);
}

bool CFoscamNvrWrapper::downloadRecord(long userID,FOSNVR_RecordNode *files, int count)
{
    if (userID < 0 || userID >= MAX_FOSCAM_NVR_CLIENT)
    {
        return false;
    }
    
    return fFoscamNvrClient[userID].downloadRecord(files, count);
}

void CFoscamNvrWrapper::downLoadCancel(long userID)
{
    if (userID < 0 || userID >= MAX_FOSCAM_NVR_CLIENT)
    {
        return;
    }
    
    return fFoscamNvrClient[userID].downLoadCancel();
}
bool CFoscamNvrWrapper::ptz( long userID, long channel, PTZ_CMD ptz )
{
	if (userID < 0 || userID >= MAX_FOSCAM_NVR_CLIENT)
	{
		return false;
	}

	return fFoscamNvrClient[userID].ptz(channel, ptz);
}

bool CFoscamNvrWrapper::search( void* node, long* size )
{
//	if(NVRSdk_Discovery((NVR_SEARCH_RESP_S*)node, (int*)size, 2000) == NVRCMD_OK)
//		return true;

    return FosNvr_Discovery((FOSDISCOVERY_NODE *)node, (int *)size) == FOSCMDRET_OK;
}

void CFoscamNvrWrapper::stop()
{
	for (int i = 0; i < MAX_FOSCAM_NVR_CLIENT; i++)
	{
		fFoscamNvrClient[i].stop();
	}
}

bool CFoscamNvrWrapper::searchRecordFiles(long userID,
                                          int channels,
                                          long long st,
                                          long long et,
                                          FOSNVR_RECORDTYPE type,
                                          int *nodeCount)
{
    if (userID < 0 || userID >= MAX_FOSCAM_NVR_CLIENT)
    {
        return false;
    }
    
    return fFoscamNvrClient[userID].searchRecordFiles(channels,
                                                      st,
                                                      et,
                                                      type,
                                                      nodeCount);
}


bool CFoscamNvrWrapper::getIPCList(long userID,FOSNVR_IpcNode* ipcNode, int *size)
{
    if (userID < 0 || userID >= MAX_FOSCAM_NVR_CLIENT)
    {
        return false;
    }
  
    return fFoscamNvrClient[userID].getIPCList(ipcNode, size);
}

bool CFoscamNvrWrapper::getRecordNodeInfo(long userID,int nodeIdx,FOSNVR_RecordNode *node)
{
    if (userID < 0 || userID >= MAX_FOSCAM_NVR_CLIENT)
    {
        return false;
    }
    
    return fFoscamNvrClient[userID].getRecordNodeInfo(userID, nodeIdx, node);
}


bool CFoscamNvrWrapper::setConfig( long userID, long type, void *config )
{
	if (userID < 0 || userID >= MAX_FOSCAM_NVR_CLIENT)
	{
		return -1;
	}

	return fFoscamNvrClient[userID].setConfig(type, config);
}

bool CFoscamNvrWrapper::getConfig( long userID, long type, void *config )
{
	if (userID < 0 || userID >= MAX_FOSCAM_NVR_CLIENT)
	{
		return -1;
	}

	return fFoscamNvrClient[userID].getConfig(type, config);
}

int CFoscamNvrWrapper::getChannelCount(long userID)
{
	if (userID < 0 || userID >= MAX_FOSCAM_NVR_CLIENT)
	{
		return -1;
	}

	return fFoscamNvrClient[userID].getChannelCount();
}

bool CFoscamNvrWrapper::setEventCB( long userID, FOSCAM_NVR_EventCB cbNetEvent, void *userData )
{
    if (userID < 0 || userID >= MAX_FOSCAM_NVR_CLIENT)
    {
        return -1;
    }
    
    return fFoscamNvrClient[userID].setEventCB(cbNetEvent, userData);
}

