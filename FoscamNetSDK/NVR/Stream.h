#pragma once
#include "../IPCSDK_for_mac150629/include/fosnvrsdk.h"
#include "FoscamNvrNetSDK.h"
#include "pthread_auto_lock.h"
#include "commons.h"


typedef enum
{
    STREAM_REAL,
    STREAM_FILE,
}FOSNVR_AV_STREAM_TYPE;

typedef struct
{
    void *p1;
    int p2;
}STREAM_THREAD_ARGCS;

#define MAX_CHANNEL_CNT 32
class CStream
{
public:
	CStream(void);
	~CStream(void);

	bool realPlay(FOSHANDLE fos, LPPREVIEW_INFO previewInfo, FOSCAM_NVR_DataCB dataCB, void* user);
	bool stopRealPlay();
    bool playback(FOSHANDLE fos, LPPLAYBACK_INFO playbackInfo,FOSCAM_NVR_FILEDataCB dataCB, FOSCAM_NVR_FILEEventCB eventCB,void *user);
    bool playbackCmd(FOSNVR_PBCMD cmd,int value);
    bool stopPlayback();
    
	void AVData();
    void AVFileData(int ch);
    void AVProgress();
    
	bool isPlay();
	bool isExist(LPPREVIEW_INFO previewInfo);
	bool isExist(int channel);
	FOSHANDLE getHandle();
    FOSNVR_AV_STREAM_TYPE avStreamType(){return fAvStreamType;};
private:
	bool					fIsPlay;
	PREVIEW_INFO			fPreviewInfo;
	void*					fUserData;
	FOSCAM_NVR_DataCB		fDataCB;
	FOSHANDLE				fFosHandle;
    FOSNVR_AV_STREAM_TYPE   fAvStreamType;
	// video thread
	//HANDLE		fStreamThread;
    //HANDLE        fStreamHandle;
    pthread_t   fStreamThread;
    pthread_cond_t fStreamHandle;
	
	bool		fIsStream;
	bool		fIsAudio;
    
    pthread_mutex_t _mutex;
    pthread_mutex_t _mutex_cond;
	//CBaseCS		fStreamCS;
private:
    //playback argcs
    PLAYBACK_INFO           fPlaybackInfo;
    FOSCAM_NVR_FILEDataCB   fFileDataCB;
    FOSCAM_NVR_FILEEventCB  fFileEventCB;
    pthread_t fpbStreamThreads[MAX_CHANNEL_CNT];
    pthread_t fpbProgressThread;
    pthread_cond_t fProCond;
    pthread_mutex_t fProCondMutex;
    pthread_mutex_t fCurMSecsMutex;
    bool fIsPro;
    bool fIsCmd;
    STREAM_THREAD_ARGCS fThreadArgcs[MAX_CHANNEL_CNT];
    int fSignals;
    int fPlays;
    FOSNVR_PBCMD fpbCmd;
    int fpbCmdValue;
    long long fCurMSecs;
};
