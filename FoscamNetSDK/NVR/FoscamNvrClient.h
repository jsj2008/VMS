#pragma once

#include "../IPCSDK_for_mac150629/include/fosnvrsdk.h"
#include "FoscamNvrNetSDK.h"
#include "pthread_auto_lock.h"
#include "Stream.h"

typedef enum
{
	FOSCAM_NVR_STREAM_TYPE_NONE = -1,
	FOSCAM_NVR_STREAM_TYPE_FIRST = 0,
	FOSCAM_NVR_STREAM_TYPE_SECOND = 1
}FOSCAM_NVR_STREAM_TYPE;

#define MAX_FOSCAM_NVR_STREAM		32

static int short_timeout_ms = 500;
static int long_timeout_ms = 100000;

class CFoscamNvrClient
{
public:
	CFoscamNvrClient(void);
	~CFoscamNvrClient(void);

	bool login(LOGIN_DATA *loginData);
	bool login(FOSHANDLE& fos, LOGIN_DATA *loginData);
	bool logout();
	bool logout(FOSHANDLE fos, char* url);
    bool modifyLoginInfo(char *newName, char* newPwd,char *result,int *len);
	void stop();
	bool ptz(long channel, PTZ_CMD ptz);
	bool isExist(LOGIN_DATA loginData);
	bool isLogin();
	void isLogin(bool val) ;
	long userID();
	void userID(long val);
	bool retain();
	void retain(bool val);
	long realPlay(LPPREVIEW_INFO previewInfo, FOSCAM_NVR_DataCB dataCB, void* user);
	bool stopRealPlay(long realHandle);    
    long playback(LPPLAYBACK_INFO playbackInfo, FOSCAM_NVR_FILEDataCB dataCB,FOSCAM_NVR_FILEEventCB eventCB, void* user);
    bool stopPlayback(long realHandle);
    bool sendPlaybackCmd(long realHandle,FOSNVR_PBCMD cmd,int value);
    bool setDownloadPath(char *path);
    bool downloadRecord(FOSNVR_RecordNode *files, int count);
    void downLoadCancel();
	bool getConfig(long type, void *config);
	bool setConfig(long type, void *config);
	int	 getChannelCount();
    bool searchRecordFiles(int channels,long long st,long long et,FOSNVR_RECORDTYPE type,int *nodeCount);
    bool getIPCList(FOSNVR_IpcNode* ipcNode, int *size);
    bool getRecordNodeInfo(long userID,int nodeIdx,FOSNVR_RecordNode *node);
	bool setEventCB(FOSCAM_NVR_EventCB cbNetEvent, void *userData);
    void setTimeOut(int shortTimeOutMS,int longTimeOutMS);
	void doEvent();
private:
	FOSHANDLE	fHandle;
	CStream		fStream[MAX_FOSCAM_NVR_STREAM];
	LOGIN_DATA	fLoginData;
	long		fUserID;	// UserID
	bool		fIsLogin;
	bool		fRetain;

	// event thread
    pthread_t   fEventThread;
    pthread_cond_t fEventHandle;
	
	bool		fIsEventThread;
	//int			fTimeout;
    int         fShortTimeOutMS;
    int         fLongTimeOutMS;
	// get event data
    pthread_mutex_t _mutex;
    pthread_mutex_t _mutex_cond;
    
    int     _chn_cnt;
    FOSCAM_NVR_EventCB	fEventCB;
    void 		*fEventUserData;
};
