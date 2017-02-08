// FoscamNvrSDK.cpp : 定义 DLL 应用程序的导出函数。
//

#include "FoscamNvrNetSDK.h"
#include "FoscamNvrWrapper.h"

FOS_NVR_SDK bool FOSCAM_NVR_Init( void )
{
	return CFoscamNvrWrapper::init();
}

FOS_NVR_SDK bool FOSCAM_NVR_Cleanup( void )
{
	return CFoscamNvrWrapper::cleanup();
}

FOS_NVR_SDK void FOSCAM_NVR_SetTimeOut(int shortTimeOutMS,int longTimeOutMS)
{
    CFoscamNvrWrapper::instance().setTimeOut(shortTimeOutMS, longTimeOutMS);
}


FOS_NVR_SDK long FOSCAM_NVR_Login( LOGIN_DATA *loginData )
{
	return CFoscamNvrWrapper::instance().login(loginData);
}

FOS_NVR_SDK bool FOSCAM_NVR_ModifyLoginInfo(long userID,char *newName, char* newPwd,char *result,int *len)
{
    return CFoscamNvrWrapper::instance().modifyLoginInfo(userID, newName, newPwd,result,len);
}

FOS_NVR_SDK bool FOSCAM_NVR_Logout( long userID )
{
	return CFoscamNvrWrapper::instance().logout(userID);
}

// 实时预览
FOS_NVR_SDK long FOSCAM_NVR_RealPlay( long userID, LPPREVIEW_INFO lpPreviewInfo, FOSCAM_NVR_DataCB dataCB, void* user )
{
	return CFoscamNvrWrapper::instance().realPlay(userID, lpPreviewInfo, dataCB, user);
}

FOS_NVR_SDK bool FOSCAM_NVR_StopRealPlay( long userID, long realHandle )
{
	return CFoscamNvrWrapper::instance().stopRealPlay(userID, realHandle);
}

FOS_NVR_SDK bool FOSCAM_NVR_PTZ( long userID, long channel, PTZ_CMD ptz )
{
	return CFoscamNvrWrapper::instance().ptz(userID, channel, ptz);
}

FOS_NVR_SDK bool FOSCAM_NVR_Search( void* node, long* size )
{
	return CFoscamNvrWrapper::search(node, size);
}

FOS_NVR_SDK bool FOSCAM_NVR_StopAll()
{
	CFoscamNvrWrapper::instance().stop();
	return true;
}

FOS_NVR_SDK bool FOSCAM_NVR_SetConfig( long userID, long type, void *config )
{
	return CFoscamNvrWrapper::instance().setConfig(userID, type, config);
}

FOS_NVR_SDK bool FOSCAM_NVR_SearchRecordFiles(long userID,
                                              int channels,
                                              long long st,
                                              long long et,
                                              FOSNVR_RECORDTYPE type,
                                              int *nodeCount)
{
    return CFoscamNvrWrapper::instance().searchRecordFiles(userID,
                                                           channels,
                                                           st,
                                                           et,
                                                           type,
                                                           nodeCount);
}

FOS_NVR_SDK bool FOSCAM_NVR_GetIPCList(long userID,FOSNVR_IpcNode* ipcNode, int *size)
{
    return CFoscamNvrWrapper::instance().getIPCList(userID, ipcNode, size);
}


FOS_NVR_SDK bool FOSCAM_NVR_GetRecordNodeInfo(long userID,int nodeIdx,FOSNVR_RecordNode *node)
{
    return CFoscamNvrWrapper::instance().getRecordNodeInfo(userID, nodeIdx, node);
}


FOS_NVR_SDK bool FOSCAM_NVR_GetConfig( long userID, long type, void *config )
{
	return CFoscamNvrWrapper::instance().getConfig(userID, type, config);
}

FOS_NVR_SDK int FOSCAM_NVR_GetChannelCount(long userID)
{
	return CFoscamNvrWrapper::instance().getChannelCount(userID);
}

FOS_NVR_SDK bool FOSCAM_NVR_SetEventCB(long userID, FOSCAM_NVR_EventCB cbNetEvent, void *userData)
{
    return CFoscamNvrWrapper::instance().setEventCB(userID, cbNetEvent, userData);
}

FOS_NVR_SDK long FOSCAM_NVR_StatPlayback(long userID,LPPLAYBACK_INFO lpPlaybackInfo,FOSCAM_NVR_FILEDataCB dataCB,FOSCAM_NVR_FILEEventCB eventCB,void *user)
{
    return CFoscamNvrWrapper::instance().playback(userID, lpPlaybackInfo, dataCB, eventCB,user);
}

FOS_NVR_SDK bool FOSCAM_NVR_StopPlayback(long userID,long realHandle)
{
    //return false;
    return CFoscamNvrWrapper::instance().stopPlayback(userID, realHandle);
}

FOS_NVR_SDK bool FOSCAM_NVR_SendPlaybackCmd(long userID,long realHandle,FOSNVR_PBCMD cmd,int value)
{
    return CFoscamNvrWrapper::instance().sendPlaybackCmd(userID, realHandle, cmd, value);
}

FOS_NVR_SDK bool FOSCAM_NVR_SetDownloadPath(long userID,char *path)
{
    return CFoscamNvrWrapper::instance().setDownloadPath(userID, path);
}

FOS_NVR_SDK bool FOSCAM_NVR_DownloadRecord(long userID,FOSNVR_RecordNode *files, int count)
{
    return CFoscamNvrWrapper::instance().downloadRecord(userID, files, count);
}

FOS_NVR_SDK void FOSCAM_NVR_DownLoadCancel(long userID)
{
    CFoscamNvrWrapper::instance().downLoadCancel(userID);
}

