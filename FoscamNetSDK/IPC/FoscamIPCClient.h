#pragma once
#include "FoscamNetSDK.h"
#include "fossdk.h"
#include "pthread_auto_lock.h"
#include "commons.h"

class CFoscamIPCClient
{
public:
	CFoscamIPCClient(void);
	~CFoscamIPCClient(void);

	bool login(LOGIN_DATA *loginData);
	bool logout();
    bool modifyLoginInfo(char *newName,char* newPwd);
	long realPlay(LPPREVIEW_INFO previewInfo, NET_DataCallBack avnetDataCB, void* user);
	bool stopRealPlay();
	int ptz(PTZ_CMD ptz );
    bool getConfig(long type, void *config);
    bool setConfig(long type, void *config);
    bool setEventCB(NET_Event_CallBack cbNetEvent, void *userData);
    bool getEventData( FOSCAM_IPC_NET_EVENT_DATA* eventData );
    bool openTalk();
    bool closeTalk();
    bool talk(char* data, int dataLen);
    
    bool IsLogin();
	void IsLogin(bool val);
	long UserID();
	void UserID(long val);
	bool retain();
	void retain(bool val);
    void DoData();
    void doEvent();
private:
	LOGIN_DATA	fLoginData;
	FOSHANDLE	fFosHandle;

	long		fUserID;	// UserID
	bool		fIsLogin;
	bool		fRetain;

    //stream
    PLAYBACK_INFO   fPlaybackInfo;
	PREVIEW_INFO	fPreviewInfo;
	void            *fUserData;
	NET_DataCallBack fDataCB;
    pthread_t   streamThread;
    pthread_cond_t streamHandle;
    bool		isStream;
    bool		fIsAudio;
 
    //event
    bool fIsEventThread;
    pthread_t   fEventThread;
    pthread_cond_t fEventHandle;
    NET_Event_CallBack	fEventCB;
    void 		*fEventUserData;
    FOSCAM_IPC_NET_EVENT_DATA		fEventData;
    

	int			fTimeout;
	//CBaseCS		fFoscamIPCClientBaseCS;
    pthread_mutex_t _mutex;
    pthread_mutex_t _mutex_cond;
};
