// FoscamNetSDK.cpp : ∂®“Â DLL ”¶”√≥Ã–Úµƒµº≥ˆ∫Ø ˝°£
//
#include "FoscamNetSDK.h"
#include "FoscamNetWrapper.h"

// ≥ı ºªØ
FOS_NET_SDK bool FOSCAM_NET_Init(void)
{
	return CFoscamNetWrapper::init();
}

FOS_NET_SDK bool FOSCAM_NET_Cleanup(void)
{
	return CFoscamNetWrapper::instance().cleanup();
}

// ”√ªß◊¢≤·
//FOS_NET_SDK long FOSCAM_NET_Login1(long dev_id,int chn_id,FOSDEV_TYPE dev_type,LOGIN_DATA login_data,int *chn_cnt)
//{
//    return CFoscamNetWrapper::instance().login1(dev_id, chn_id, dev_type, login_data, chn_cnt);
//}

FOS_NET_SDK long FOSCAM_NET_Login(LOGIN_DATA *loginData) // ∑µªÿ”√ªßID
{
	return CFoscamNetWrapper::instance().login(loginData);
}

FOS_NET_SDK bool FOSCAM_NET_Logout(long userID)
{
	return CFoscamNetWrapper::instance().logout(userID);
}



FOS_NET_SDK bool FOSCAM_NET_ModifyLoginInfo(long userID, char *newName, char* newPwd)
{
    return CFoscamNetWrapper::instance().modifyLoginInfo(userID, newName, newPwd);
}
//FOS_NET_SDK void FOSCAM_NET_Logout1(long user_id)
//{
//    CFoscamNetWrapper::instance().logout1(user_id);
//}

//FOS_NET_SDK bool FOSCAM_NET_RealPlay1(long userID, LPPREVIEW_INFO lpPreviewInfo, NET_DataCallBack netDataCB, void* user)
//{
//    return CFoscamNetWrapper::instance().realPlay1(userID, lpPreviewInfo, netDataCB, user);
//}

//  µ ±‘§¿¿
FOS_NET_SDK long FOSCAM_NET_RealPlay(long userID, LPPREVIEW_INFO lpPreviewInfo, NET_DataCallBack netDataCB, void* user)  // ∑µªÿ‘§¿¿æ‰±˙ realHandle
{
	return CFoscamNetWrapper::instance().realPlay(userID, lpPreviewInfo, netDataCB, user);
}

FOS_NET_SDK bool FOSCAM_NET_StopRealPlay(long realHandle)
{
	return CFoscamNetWrapper::instance().stopRealPlay(realHandle);
}

// ptz
FOS_NET_SDK int FOSCAM_NET_PTZ(long userID, PTZ_CMD ptz)
{
	return CFoscamNetWrapper::instance().ptz(userID, ptz);
}

FOS_NET_SDK bool FOSCAM_NET_Search( void* node, long* size )
{
	return CFoscamNetWrapper::search(node, size);
}

FOS_NET_SDK bool FOSCAM_NET_GetConfig( long userID, long type, void *config )
{
	return CFoscamNetWrapper::instance().getConfig(userID, type, config);
}

FOS_NET_SDK bool FOSCAM_NET_SetConfig( long userID, long type, void *config )
{
	return CFoscamNetWrapper::instance().setConfig(userID, type, config);
}

FOS_NET_SDK bool FOSCAM_NET_SetEventCB( long userID, NET_Event_CallBack cbNetEvent, void *userData )
{
	return CFoscamNetWrapper::instance().setEventCB(userID, cbNetEvent, userData);
}

FOS_NET_SDK bool FOSCAM_NET_GetEventData( long userID, FOSCAM_IPC_NET_EVENT_DATA* eventData )
{
	return CFoscamNetWrapper::instance().getEventData(userID, eventData);
}

FOS_NET_SDK bool FOSCAM_NET_Talk( long userID, char* data, int dataLen )
{
    return CFoscamNetWrapper::instance().talk(userID, data, dataLen);
}

FOS_NET_SDK bool FOSCAM_NET_OpenTalk( long userID )
{
    return CFoscamNetWrapper::instance().openTalk(userID);
}

FOS_NET_SDK bool FOSCAM_NET_CloseTalk( long userID )
{
    return CFoscamNetWrapper::instance().closeTalk(userID);
    
}
