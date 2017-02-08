/*
* Copyright (c) 2014,FOSNVRcam
* All rights reserved.
*
* File Name: FOSNVRDef.h
* Abstract: FOSNVRSdk Definition File
*
* Current Version: 1.0
* Author: FOSCam
*
* Completion Date: 2014-09-22
*/

#ifndef __FOSNVRSDK_SRC_INCLUDE_FOSNVRDEF__
#define __FOSNVRSDK_SRC_INCLUDE_FOSNVRDEF__
#include <string.h>
#include "FosCom.h"

typedef void (*HOOKSTREAMFUN)(FOSDEC_DATA* pData, int datalen, void *usrdata);

//=============================new add start --hongwh
typedef enum
{
    NVR_MEIDA_1CH = 1,
    NVR_MEIDA_4CH = 4,
    NVR_MEIDA_8CH = 8,  //8Õ®µ¿NVR
    NVR_MEIDA_9CH = 9,
    NVR_MEIDA_16CH = 16,
    NVR_MEIDA_32CH = 32,
}FOSNVR_MEDIATYPE;

typedef enum
{
    NVR_P2P,
    NVR_IP,
}FOSNVR_CONTYPE;


typedef enum {
    AUTOFMT = 0x100,
    IMAADPCM,
    H264,
    MJPEG,
    PCM,
    G726,
    HIG726,
}FOSNVR_DECFMT;

typedef struct VideoHead{
    int  VWidth;
    int  VHeight;
    int  VFrameRate;
    int  VBitRate;
}VideoHead;

typedef struct AudioHead {
    int  sampleRate;
    int  bitsPerSample;
}AudioHead;

typedef struct FrameData
{
    char	frameType;
    char	channel;  //Õ®µ¿∫≈
    char    encodeType;
    int		dataLen;
    int     isKey;   // «∑ÒI÷°
    union {
        VideoHead video;
        AudioHead audio;
    };
    long long pts;
    long long time;
    unsigned int index;
    char	*frameData;
}FOSNVR_FrameData;


typedef enum {
    NVR_PIX_YUYV422,
    NVR_PIX_UYVY422,
    NVR_PIX_YUV420,
    NVR_PIX_RGB32,
    NVR_PIX_ARGB32,	  //packed ARGB 8:8:8:8, 32bpp, ARGBARGB...
    NVR_PIX_RGBA32,    //packed RGBA 8:8:8:8, 32bpp, RGBARGBA...
    NVR_PIX_ABGR32,    //packed ABGR 8:8:8:8, 32bpp, ABGRABGR...
    NVR_PIX_BGRA32,    //packed BGRA 8:8:8:8, 32bpp, BGRABGRA...
    NVR_PIX_RGB24,	  //packed RGB 8:8:8, 24bpp, RGBRGB...
    NVR_PIX_BGR24,     //packed RGB 8:8:8, 24bpp, BGRBGR...
    NVR_PIX_RGB565BE,  //packed RGB 5:6:5, 16bpp, (msb)   5R 6G 5B(lsb), big-endian
    NVR_PIX_RGB565LE,  //packed RGB 5:6:5, 16bpp, (msb)   5R 6G 5B(lsb), little-endian
    NVR_PIX_BGR565BE,  //packed BGR 5:6:5, 16bpp, (msb)   5B 6G 5R(lsb), big-endian
    NVR_PIX_BGR565LE,  //packed BGR 5:6:5, 16bpp, (msb)   5B 6G 5R(lsb), little-endian
}FOSNVR_PIXFORMAT;



//==============================new add end --hongwh

typedef enum{
	FOSNVRVIDEOMODE_NOMAL,
	FOSNVRVIDEOMODE_RECODEC,
}FOSNVR_VIDEOMODE;

typedef enum{
	FOSNVRVIDEOMODE_1CH = 1,
	FOSNVRVIDEOMODE_4CH = 4,
	FOSNVRVIDEOMODE_9CH = 9,
	FOSNVRVIDEOMODE_16CH = 16,
}FOSNVR_REDECMODE;

typedef enum{
	FOSNVRPQ_LOW, // 流畅
	FOSNVRPQ_MID,// 均衡
	FOSNVRPQ_HIGH, // 清晰
}FOSNVR_REDECPQMODE;

typedef enum{
	FOSNVRRDTYPE_NONE = 0,
	FOSNVRRDTYPE_SCHEDULE = 1,	  //定时录像
	FOSNVRRDTYPE_MANUAL = 2,	 //手动录像
	FOSNVRRDTYPE_MOTION = 4,	 //移动侦测报警录像
	FOSNVRRDTYPE_IOALARM = 8,	  //传感器报警录像
	FOSNVRRDTYPE_ALL = 1 | 2 | 4 | 8,
}FOSNVR_RECORDTYPE;

typedef enum{
	FOSNVRPBCMD_SEEK = 0,
	FOSNVRPBCMD_PAUSEPLAY,
	FOSNVRPBCMD_RESUMEPLAY,
	FOSNVRPBCMD_FASTPLAY, // x4 x8 x16 x32 
	FOSNVRPBCMD_SLOWPLAY, // x4 x8 x16 x32
	FOSNVRPBCMD_BACKPLAY, // x4 x8 x16 x32
}FOSNVR_PBCMD;

typedef enum{
    FOSNVR_PBCMD_MULTIPLE_1X = 1,
    FOSNVR_PBCMD_MULTIPLE_4X = 4,
    FOSNVR_PBCMD_MULTIPLE_8X = 8,
    FOSNVR_PBCMD_MULTIPLE_16X = 16,
    FOSNVR_PBCMD_MULTIPLE_32X = 32,
}FOSNVR_PBCMD_MULTIPLE;


typedef struct 
{ 
	int version; 
	int screen_type; 
	int ch_bit; 
	int resolution; 
	int pqmode;//definition:0,1,2 
	int liveORpb;//live:0 or playback:1 
	int reserve[254]; 
}ScreenSplitCtl_t;  //多屏重编码信息结构

typedef struct{
	int		frameCount; //Unreaded frame count
	int		memSize;//Unreaded frame size
}FOSNVR_CacheInfo;

typedef struct tagSearchNodeResp
{
	char				channel;
	unsigned int		fileSize;
	unsigned int		tmStart;  //开始时间
	unsigned int		tmEnd;  
	unsigned int		indexNO;
	char			status;
	char			recordType;
	char			diskIndex;
	char			recSegIndex;
} NVR_SearchNodeResp;

typedef struct tagPBSearchStartResp{
	int		result;
	int		total;
} NVR_PBSearchStartResp;

typedef enum{
	FOSNVRPTZCMD_UP,
	FOSNVRPTZCMD_DOWN,
	FOSNVRPTZCMD_LEFT,
	FOSNVRPTZCMD_RIGHT,
}FOSNVR_PTZCMD;

typedef struct NVR_tagSearchDevResp
{
	char  ipCamID[64];
	char  ipCamName[21];
	char  xAddr[128];
	int		ip;
	unsigned short	mediaPort;
	unsigned short	port;
	char  protocol;
	char  deviceType;
	int mask;
	int gate;
	int dns;
}NVR_SearchDevResp;

typedef struct NVR_tagDevSearchStartResp{
	int		result;
	int		total;
}NVR_DevSearchStartResp;

typedef struct
{
	unsigned int			indexNO;
	char			        channel;
	unsigned int			fileSize;
	unsigned int			tmStart;
	unsigned int			tmEnd;
	char			        recordType;
}FOSNVR_RecordNode;

typedef struct
{
	char	ipCamID[64];
	char	ipCamName[21];
	char	xAddr[128];
	int		ip;
	short	mediaPort;
	short	port;
	char	protocol;
	char	deviceType;
	int		mask; 
	int		gate;
	int		dns;
}FOSNVR_IpcNode;

typedef struct
{
	unsigned int	id;					//id.
	int				len;				//size of data.
	char			data[2048];			//data. 
}FOSNVR_EvetData;

typedef enum{
	FOSNVR_EVENT_INIT_INFO = 1,
	FOSNVR_EVENT_RECORD_STATE_CHG,
	FOSNVR_EVENT_LED_STATE_CHG,
	FOSNVR_EVENT_PRESET_POINT_CHG,
	FOSNVR_EVENT_CRUISE_MAP_CHG,
	FOSNVR_EVENT_MIRROR_FLIP_CHG,
	FOSNVR_EVENT_STREAM_PARAM_CHG,
	FOSNVR_EVENT_IMG_SETTING_CHG,
	FOSNVR_EVENT_ALARM_STATE_CHG,
	FOSNVR_EVENT_PWR_FREQ_CHG,
	FOSNVR_EVENT_STREAM_TYPE_CHG,
	FOSNVR_EVENT_WORKMODE_CHG,
	FOSNVR_EVENT_VIDEO_STATE_CHG,
	FOSNVR_EVENT_DISK_STATE_CHG,
	FOSNVR_EVENT_ABILITY_CHG,
	//FOSNVR_EVENT_EXECUTE_IPC_CGI_RESP,
	FOSNVR_EVENT_ABILITY_RESP,
	//FOSNVR_EVENT_APP_UPGRADE_RESP,
	FOSNVR_EVENT_IPC_LOGIN_RESP, 
	FOSNVR_EVENT_IPC_APPUPGRADEIPC_RESP,
	FOSNVR_EVENT_APP_UPGRADE_RESP,
	FOSNVR_EVENT_LOGIN_RESP,


	FOSNVR_EVENT_NVR_DLRECORD_PROGRESS = 100,	// 只上层处理的消息，录像下载进度返回
}FOSNVR_EVENT_MSG;

typedef struct
{
	unsigned int		RecordMan;
	unsigned int		RecordAlarmIO;
	unsigned int		RecordAlarmMV;
	unsigned int		RecordPlan;
}FOSNVR_RecordState;

typedef struct
{
	int		ch;
	int		infraLedMode;		// 0=Auto 1=Manual
	int		infraLedState;	// 0=ON 1=OFF
} FOSNVR_LedState;

typedef struct
{
	int				ch;
	unsigned char		presetPointCnt;
	char				presetPointList[16][32];
	char				curPresetint[32];
} FOSNVR_Preset;

typedef struct
{
	int				ch;
	unsigned char		cruiseMapCnt;
	char				cruiseMapList[8][32];
	char				curCruiseMap[32];
} FOSNVR_Cruise;

typedef struct
{
	int					ch;
	unsigned char			brightness;
	unsigned char			contrast;
	unsigned char			hue;
	unsigned char			saturation;
	unsigned char			sharpness;
} FOSNVR_ImageParam;

typedef struct{
	int			AlarmIO;
	int			AlarmMV;
} FOSNVR_AlarmState;

typedef struct{
	int			mode;
} FOSNVR_WorkMode;

typedef struct{
	int  ch;
	int  enCh;
	int  state;    //0:Off line, 1:On line
	int  protocol;
} FOSNVR_ConnectConfig;

typedef struct{
	int buzzer;
} FOSNVR_VideoAlarmInfo;

typedef struct{
	FOSNVR_ConnectConfig connectcfg[32];
	FOSNVR_VideoAlarmInfo VAinfo;
} FOSNVR_IPCVideoST_Compatible;

typedef struct{
	int			isDiskErr;
} FOSNVR_DiskState;


typedef struct tagNVRDev_Ability
{
	int		downloadMode;
	int		playbackMode;
	int		playbackColour;
	int		isEnableP2P;
	int		P2PMode;
	int		res0;
	int		res1;
	int		res2;
	int		res3;
} NVRDev_Ability;

typedef struct{
	unsigned int chn;
	unsigned int model; 
	unsigned int language; 
	unsigned int sensorType; 
	unsigned int wifiType; 
	unsigned int sdFlag; 
	unsigned int outdoorFlag; 
	unsigned int ptFlag;		//PtSupport
	unsigned int zoomFlag;		//ZoomSupport
	unsigned int rs485Flag; 
	unsigned int ioAlarmFlag; 
	unsigned int onvifFlag; 
	unsigned int p2pFlag; 
	unsigned int wpsFlag; 
	unsigned int audioFlag; 
	unsigned int talkFlag; 
	char appVer[64]; 
	char modelName[64]; 
} FOSNVR_Ability;

typedef struct
{ 
	int ret; 
	int reserve[16]; 
}FOSNVR_IpcUpgradeResult;

typedef struct
{ 
	int			result;
	int			mode;
	char        url[1025]; 
}FOSNVR_NVRUpgradeResult;

typedef struct
{ 
	char				mac[13];
	int				usrRight;
	unsigned int		machineType;
	int				NVRioAlarmFlag;
}FOSNVR_InitInfo;

typedef struct tagDownloadProgress{
	float progress;
	int index;
}FOSNVR_DownloadProgress;

typedef struct tagDownloadState
{
	unsigned long long   iDownloadByte;
	unsigned long long	fileSize;

}FOSNVR_DownLoadState;

typedef struct tagLoginResp
{
	int		result;
	int		number;
	int		usrRight;
	int		pbtoken;
	int		dltoken;
	int		cgitoken;
	int		token[TOKEN_LEN];
} FOSNVR_LoginResp;

typedef enum DOWNLOAD_STATUS
{
	FOSNVR_DL_FAILED_FLAG =101,
}FOSNVR_DOWNLOAD_STATUS;

#endif
