#pragma once
#include "FoscamNetSDK.h"
#include "fossdk.h"
#include "FoscamIPCClient.h"
//#include "FoscamSdker.h"
//#include "FoscamClient.h"
//#include "FoscamIPCSdker.h"
//#include "FoscamNVRSdker.h"
#include <vector>

#define		MAX_CLIENT		200

class CFoscamNetWrapper
{
public:
	CFoscamNetWrapper(void);
	~CFoscamNetWrapper(void);

	static CFoscamNetWrapper& instance();
	static bool init();
    static bool cleanup();
	static bool search(void* node, long* size);
    
    //long login1(long dev_id,int chn_id,FOSDEV_TYPE dev_type,LOGIN_DATA login_data,int *chn_cnt);
	long login(LOGIN_DATA *loginData); // ·µ»ØuseID
    //void logout1(long user_id);
	bool logout(long userID);
    
    bool modifyLoginInfo(long userID, char *newName, char* newPwd);
    //bool realPlay1(long userID, LPPREVIEW_INFO previewInfo, NET_DataCallBack avnetDataCB, void* user);
	long realPlay(long userID, LPPREVIEW_INFO previewInfo, NET_DataCallBack avnetDataCB, void* user);  // ·µ»ØÔ¤ÀÀ¾ä±ú realHandle
	bool stopRealPlay(long userID);
    //void stopRealPlay1(long userID);
    
    
	int ptz(long userID, PTZ_CMD ptz);
    bool openTalk(long userID);
    bool closeTalk(long userID);
    bool talk(long userID, char* data, int dataLen );
	bool getConfig(long userID, long type, void *config);
	bool setConfig(long userID, long type, void *config);
	bool setEventCB( long userID, NET_Event_CallBack cbNetEvent, void *userData );
	bool getEventData( long userID, FOSCAM_IPC_NET_EVENT_DATA* eventData );
private:
	CFoscamIPCClient		fIPCClient[MAX_CLIENT];
    //CFoscamClient           _clients[MAX_CLIENT];
    //std::vector<CFoscamSdker *>        _devices;
    pthread_mutex_t         _mutex = PTHREAD_MUTEX_INITIALIZER;
};
