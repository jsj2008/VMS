#ifndef __FOSCAM_NVR_SDK_H__
#define __FOSCAM_NVR_SDK_H__

#include "../PublicDef.h"
#include "../IPCSDK_for_mac150629/include/FosDef.h"
#include "../IPCSDK_for_mac150629/include/FosNvrDef.h"

#ifdef _WIN32
#define FOS_NVR_API				__stdcall

#ifdef FOSSDK_EXPORTS
#define FOS_NVR_SDK				__declspec(dllexport)
#else
#define FOS_NVR_SDK				__declspec(dllimport)
#endif
#else
#define FOS_NVR_API
#define FOS_NVR_SDK
#endif


//#ifdef FOSCAMNVRSDK_EXPORTS
//#define FOSCAM_NVR_SDK_API  extern "C" __declspec(dllexport)
//#else
//#define FOSCAM_NVR_SDK_API extern "C" __declspec(dllimport)
//#endif

#define  FOSCAM_IPC_PTZ_CMD_STOP_ALL            1
#define  FOSCAM_IPC_PTZ_CMD_ZOOM_IN             2
#define  FOSCAM_IPC_PTZ_CMD_ZOOM_OUT            3
#define  FOSCAM_IPC_PTZ_CMD_FOCUS_NEAR          4
#define  FOSCAM_IPC_PTZ_CMD_FOCUS_FAR           5
#define  FOSCAM_IPC_PTZ_CMD_IRIS_OPEN           6
#define  FOSCAM_IPC_PTZ_CMD_IRIS_CLOSE          7
#define  FOSCAM_IPC_PTZ_CMD_UP                  11
#define  FOSCAM_IPC_PTZ_CMD_DOWN                12
#define  FOSCAM_IPC_PTZ_CMD_LEFT                13
#define  FOSCAM_IPC_PTZ_CMD_RIGHT               14
#define  FOSCAM_IPC_PTZ_CMD_LEFT_UP             15
#define  FOSCAM_IPC_PTZ_CMD_LEFT_DOWN           17
#define  FOSCAM_IPC_PTZ_CMD_RIGHT_UP            16
#define  FOSCAM_IPC_PTZ_CMD_RIGHT_DOWN          18
#define  FOSCAM_IPC_PTZ_CMD_AUTO                19
#define  FOSCAM_IPC_PTZ_CMD_ADD_PRESET          29
#define  FOSCAM_IPC_PTZ_CMD_SET_PRESET          30
#define  FOSCAM_IPC_PTZ_CMD_CLEAR_PRESET        31
#define  FOSCAM_IPC_PTZ_CMD_GOTO_RRESET         32
#define  FOSCAM_IPC_PTZ_CMD_BEGIN_PATTERN		41
#define  FOSCAM_IPC_PTZ_CMD_SET_PATTERN         43
#define  FOSCAM_IPC_PTZ_CMD_END_PATTERN         42
#define  FOSCAM_IPC_PTZ_CMD_START_PATTERN		44
#define  FOSCAM_IPC_PTZ_CMD_STOP_PATTERN		45


typedef enum
{
    FOSNVR_PBEVENT_FILE_END,
    FOSNVR_PBEVENT_PROGRESS_START,
    FOSNVR_PBEVENT_PROGRESS_END,
}FOSNVR_PBEVENT;

typedef void (FOS_NVR_API* FOSCAM_NVR_FILEEventCB)
(long realHandle,
 FOSNVR_PBEVENT event,
 void *userData
);

typedef void (FOS_NVR_API* FOSCAM_NVR_FILEDataCB)
(long realHandle,
 int ch,
 unsigned long dataType,
 unsigned char *buffer,
 unsigned long bufferSize,
 void *userData,
 double pt);



//“Ù ”∆µªÿµ˜∫Ø ˝∂®“Â
typedef void  (FOS_NVR_API* FOSCAM_NVR_DataCB)
(long  realHandle,
 unsigned long  dataType,
 unsigned char*  buffer,
 unsigned long  bufferSize,
 void  *userData,
 double pt);


//Õ¯¬Á ¬º˛ªÿµ˜∫Ø ˝
typedef void (FOS_NVR_API* FOSCAM_NVR_EventCB)
(long userId,void *netEvent,void *userData);


typedef struct
{
    int diskNum;
    int type;
}FOS_NVR_DISK_FORMAT_CONFIG;

typedef struct
{
    int diskRewrite;
    int previewTime;
}FOS_NVR_DISK_CONFIG;

#define MAX_DISK_COUNT  3
typedef struct
{
    int diskCnt;
    FOS_NVR_DISK_CONFIG diskConfig;
    int status[MAX_DISK_COUNT];
    int type[MAX_DISK_COUNT];
    int totolSpace[MAX_DISK_COUNT];
    int freeSpace[MAX_DISK_COUNT];
    int canFormat[MAX_DISK_COUNT];
    int isBusy[MAX_DISK_COUNT];
}FOS_NVR_DISK_INFO;


typedef struct
{
    int ch;
    int isEnable;
    int status;
    int protocol;
    int productType;
    char chnName[128];
    char devName[64];
    char url[128];
    char xAddr[128];
    char devMac[16];
    unsigned int webPort;
    unsigned int mediaPort;
    char username[128];
    char password[128];
}FOS_CHANNEL_INFO;

typedef struct
{
    int chn;
    int isEnableOsdMask;
    FOS_OSDMASKAREA osdMaskArea;
}FOS_NVR_OSDMASKAREA_CONFIG;

typedef struct
{
    int chn;
    FOS_OSDConfigMsg osdConfigMsg;
}FOS_NVR_OSDConfigMsg;

typedef struct
{
    int chn;
    FOS_SCHEDULERECORDCONFIG scheduleRecordCfg;
}FOS_NVR_SCHEDULERECORDCONFIG;

typedef struct
{
    int chn;
    FOS_CRUISEMAPINFO cruiseMapInfo;
}FOSCAM_NVR_CRUISE_MAP_INFO;

typedef struct
{
    int chn;
    int streamType;
}FOSCAM_NVR_REAL_CH;


typedef struct
{
    int speed;
    int chn;
}FOS_NVR_PTZ_SPEED;

typedef struct
{
    int chn;
    FOS_MOTIONDETECTCONFIG motionDetectCfg;
    int isEnableIPCAudioAlarm;
    int recordTime;
}FOS_NVR_MOTION_DETECT_CONFIG;

typedef struct
{
    int chn;
    FOS_MOTIONDETECTCONFIG1 motionDetectCfg;
    int isEnableIPCAudioAlarm;
    int recordTime;
}FOS_NVR_MOTION_DETECT_CONFIG1;

typedef struct
{
    int chn;
    FOS_VIDEOSTREAMPARAM videoStreamParam;
    int resWidth;
    int resHeight;
}FOS_NVR_VIDEOSTREAMPARAM;

typedef struct
{
    FOS_IPINFO ipInfo;
    FOS_PORTINFO portInfo;
    int isUPNP;
}FOS_NVR_NETINFO;

typedef struct
{
    int isDHCP;
    int isUPNP;
    FOS_PORTINFO portInfo;
}FOS_NVR_PORTINFO;

typedef struct
{
    void *input;
    void *output;
    int outputLen;
    
}FOSCAM_NVR_CONFIG;



typedef enum
{
    FOSCAM_NVR_HDD_LOST_ALARM,
    FOSCAM_NVR_HDD_FULL_ALARM,
    FOSCAM_NVR_HDD_ERR_ALARM,
    FOSCAM_NVR_VIDEO_LOST_ALARM,
    FOSCAM_NVR_NET_LINK_ALARM,
}FOSCAM_NVR_OTHER_ALARM;

typedef struct
{
    FOSCAM_NVR_OTHER_ALARM alarmType;
    int buzzer;
}FOS_NVR_OTHER_ALARM_CONFIG;

typedef struct
{
    FOS_DEVSYSTEMTIME devSystemTime;
    int syncIPCTime;
}FOS_NVR_DEVSYSTEMTIME;

typedef enum
{
    FOSCAM_NVR_CONFIG_ABILITY,
    FOSCAM_NVR_CONFIG_IPC_LIST,
    FOSCAM_NVR_CONFIG_ADD_IPC_LIST,
    FOSCAM_NVR_CONFIG_DEL_IPC_LIST,
    FOSCAM_NVR_CONFIG_DISK_INFO,
    FOSCAM_NVR_CONFIG_DISK_FORMAT,
    FOSCAM_NVR_CONFIG_PRODUCT_INFO,
    FOSCAM_NVR_CONFIG_DEVICE_INFO,
    FOSCAM_NVR_CONFIG_USER_P2P_INFO,
    FOSCAM_NVR_CONFIG_DEVICE_SYSTEM_TIME,
    FOSCAM_NVR_CONFIG_NET,
    FOSCAM_NVR_CONFIG_SMTP,
    FOSCAM_NVR_CONFIG_SMTP_TEST,
    FOSCAM_NVR_CONFIG_FTP,
    FOSCAM_NVR_CONFIG_FTP_TEST,
    FOSCAM_NVR_CONFIG_DDNS,
    FOSCAM_NVR_CONFIG_DDNS_RESTORE_TO_FACTORY,
    FOSCAM_NVR_CONFIG_VIDEO_STREAM_PARAM,
    FOSCAM_NVR_CONFIG_VIDEO_STREAM_CAPABILITIES,
    FOSCAM_NVR_CONFIG_HS_MOTION_DETECT,
    FOSCAM_NVR_CONFIG_AMBA_MOTION_DETECT,
    FOSCAM_NVR_CONFIG_RECORD_SCHEDULE,
    FOSCAM_NVR_CONFIG_IO_ALARM,
    FOSCAM_NVR_CONFIG_OTHER_ALARM,
    FOSCAM_NVR_CONFIG_OSD,
    FOSCAM_NVR_CONFIG_OSD_MASK_AREA,
    FOSCAM_NVR_CONFIG_PTZ_SPEED,
    FOSCAM_NVR_CONFIG_PTZ_CRUISE_MAP_LIST,
    FOSCAM_NVR_CONFIG_PTZ_CRUISE_MAP_INFO,
    FOSCAM_NVR_CONFIG_PTZ_DEL_CRUISE_MAP,
    FOSCAM_NVR_CONFIG_PTZ_PRESET_POINT_LIST,
    FOSCAM_NVR_CONFIG_SYSTEM_EXPORT,
    FOSCAM_NVR_CONFIG_SYSTEM_IMPORT,
    FOSCAM_NVR_CONFIG_SYSTEM_UPDATE,
    FOSCAM_NVR_CONFIG_SYSTEM_RESET,
    FOSCAM_NVR_CONFIG_SYSTEM_RESTART,
    FOSCAM_NVR_CONFIG_AUTO_ADD_IPC,
}FOSCAM_NVR_CONFIG_TYPE;


#ifdef __cplusplus
extern "C" {
#endif
    
FOS_NVR_SDK bool FOSCAM_NVR_Init(void);
FOS_NVR_SDK bool FOSCAM_NVR_Cleanup(void);
FOS_NVR_SDK void FOSCAM_NVR_SetTimeOut(int shortTimeOutMS,int longTimeOutMS);
FOS_NVR_SDK long FOSCAM_NVR_Login(LOGIN_DATA *loginData);
FOS_NVR_SDK bool FOSCAM_NVR_Logout(long userID);
FOS_NVR_SDK bool FOSCAM_NVR_ModifyLoginInfo(long userID,char *newName, char* newPwd,char *result,int *len);
FOS_NVR_SDK long FOSCAM_NVR_RealPlay(long userID, LPPREVIEW_INFO lpPreviewInfo, FOSCAM_NVR_DataCB dataCB, void* user);
FOS_NVR_SDK bool FOSCAM_NVR_StopRealPlay(long userID, long realHandle);
FOS_NVR_SDK bool FOSCAM_NVR_PTZ(long userID, long channel, PTZ_CMD ptz);
FOS_NVR_SDK bool FOSCAM_NVR_Search(void* node, long* size);
FOS_NVR_SDK bool FOSCAM_NVR_StopAll();
FOS_NVR_SDK int  FOSCAM_NVR_GetChannelCount(long userID);
FOS_NVR_SDK bool FOSCAM_NVR_SetEventCB(long userID, FOSCAM_NVR_EventCB cbNetEvent, void *userData);
FOS_NVR_SDK bool FOSCAM_NVR_GetConfig(long userID, long type, void *config);
FOS_NVR_SDK bool FOSCAM_NVR_SetConfig(long userID, long type, void *config);
FOS_NVR_SDK bool FOSCAM_NVR_SearchRecordFiles(long userID,int channels,long long st,long long et,FOSNVR_RECORDTYPE type,int *nodeCount);
FOS_NVR_SDK bool FOSCAM_NVR_GetIPCList(long userID,FOSNVR_IpcNode* ipcNode, int *size);
FOS_NVR_SDK bool FOSCAM_NVR_GetRecordNodeInfo(long userID,int nodeIdx,FOSNVR_RecordNode *node);
FOS_NVR_SDK long FOSCAM_NVR_StatPlayback(long userID,LPPLAYBACK_INFO lpPlaybackInfo,FOSCAM_NVR_FILEDataCB dataCB,FOSCAM_NVR_FILEEventCB eventCB,void *user);
FOS_NVR_SDK bool FOSCAM_NVR_StopPlayback(long user,long realHandle);
FOS_NVR_SDK bool FOSCAM_NVR_SendPlaybackCmd(long userID,long realHandle,FOSNVR_PBCMD cmd,int value);
FOS_NVR_SDK bool FOSCAM_NVR_SetDownloadPath(long userID,char *path);
FOS_NVR_SDK bool FOSCAM_NVR_DownloadRecord(long userID,FOSNVR_RecordNode *files, int count);
FOS_NVR_SDK void FOSCAM_NVR_DownLoadCancel(long userID);
    
#ifdef __cplusplus
}
#endif

#endif
