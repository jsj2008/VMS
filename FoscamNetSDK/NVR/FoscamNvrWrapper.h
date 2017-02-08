#pragma once

#include "FoscamNvrClient.h"
#include "stream.h"

#define MAX_FOSCAM_NVR_CLIENT		200

class CFoscamNvrWrapper
{
public:
	CFoscamNvrWrapper(void);
	~CFoscamNvrWrapper(void);


	static bool init();
	static bool cleanup();
    
	static bool search(void* node, long* size);
	static CFoscamNvrWrapper& instance();

    void    setTimeOut(int shortTimeOutMS,int longTimeOutMS);
	long	login(LOGIN_DATA *loginData);
	bool	logout(long userID);
    bool    modifyLoginInfo(long userID, char *newName, char* newPwd,char *result,int *len);
	void	stop();
	long	realPlay(long userID, LPPREVIEW_INFO previewInfo, FOSCAM_NVR_DataCB dataCB, void* user);  // ·µ»ØÔ¤ÀÀ¾ä±ú realHandle
	bool	stopRealPlay(long userID, long realHandle);
	bool	ptz(long userID, long channel, PTZ_CMD ptz);
	bool    getConfig(long userID, long type, void *config);
	bool    setConfig(long userID, long type, void *config);
	int		getChannelCount(long userID);
    bool    searchRecordFiles(long userID,
                              int channels,
                              long long st,
                              long long et,
                              FOSNVR_RECORDTYPE type,
                              int *nodeCount);
    bool    getIPCList(long userID,FOSNVR_IpcNode* ipcNode, int *size);
    bool    getRecordNodeInfo(long userID,int nodeIdx,FOSNVR_RecordNode *node);
	bool setEventCB( long userID, FOSCAM_NVR_EventCB cbNetEvent, void *userData );
    long    playback(long userID,LPPLAYBACK_INFO pbInfo,FOSCAM_NVR_FILEDataCB dataCB,FOSCAM_NVR_FILEEventCB eventCB,void *user);
    bool	stopPlayback(long userID, long realHandle);
    bool    sendPlaybackCmd(long userID,long realHandle,FOSNVR_PBCMD cmd,int value);
    bool setDownloadPath(long userID,char *path);
    bool downloadRecord(long userID,FOSNVR_RecordNode *files, int count);
    void downLoadCancel(long userID);
private:
	CFoscamNvrClient	fFoscamNvrClient[MAX_FOSCAM_NVR_CLIENT];
    pthread_mutex_t         _mutex = PTHREAD_MUTEX_INITIALIZER;
};





