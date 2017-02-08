#pragma  once
#include <sys/time.h>

#define WORK_INI_NAME		"CMS.INI"

#define  RECORD_BUFFER_SIZE		1024*1024


// …Ë±∏¿‡–Õ
#define		DEVICE_TYPE_NONE					0
#define		DEVICE_TYPE_AB_IPC					DEVICE_TYPE_NONE+1
#define		DEVICE_TYPE_HK_DVR					DEVICE_TYPE_NONE+2
#define		DEVICE_TYPE_HK_NVR					DEVICE_TYPE_NONE+3
#define		DEVICE_TYPE_HK_IPC					DEVICE_TYPE_NONE+4
#define		DEVICE_TYPE_DH_DVR					DEVICE_TYPE_NONE+5
#define		DEVICE_TYPE_DH_NVR					DEVICE_TYPE_NONE+6
#define		DEVICE_TYPE_DH_IPC					DEVICE_TYPE_NONE+7
#define		DEVICE_TYPE_FOSCAM_IPC				DEVICE_TYPE_NONE+8
#define		DEVICE_TYPE_FOSCAM_NVR				DEVICE_TYPE_NONE+9
#define		DEVICE_TYPE_MAX						DEVICE_TYPE_NONE+9


#define		SNAP_TYPE_MANUAL					0
#define		SNAP_TYPE_ALARM						1

//const char *device_type_name[] = 
//{
//	""
//	"HD IPC",
//	"HK DVR",
//	"HK NVR",
//	"HK IPC",
//	"DH DVR",
//	"DH NVR",
//	"DH IPC",
//	"FOSCAM IPC",
//	"FOSCAM NVR"
//};

#define		PTZ_VIEW_BK_COLOR	RGB(41, 60, 78)
#define		PTZ_VIEW_STATIC_TEXT_COLOR RGB(255, 255, 255)
#define		RGB_BK_COLOR  RGB(156,166,181)
#define		DATA_BUFSIZE 81920


#define		MAX_PRESET_NUMBER		16
#define		MAX_PATTERN_NUMBER		8

#define		WM_USER_EDIT_END	WM_USER + 202 



#define		CLIENTSOCK_MSG_CONNECT_SUCC		0x01
#define		CLIENTSOCK_MSG_CONNECT_FAILED	0x02
#define		CLIENTSOCK_MSG_RECEIVE_DATA		0x03
#define		CLIENTSOCK_MSG_SOCKET_CLOSE		0x04
#define		WM_VIDEOSWITCH                  WM_USER+333
#define		WM_DRAG							0xFF

// Õ¯¬Á¡¨Ω”¿‡–Õ
#define			CONNECT_TYPE_LAN		1	// æ÷”ÚÕ¯
#define			CONNECT_TYPE_WAN		2	// π„”ÚÕ¯


#define			TOOLBAR_BACK_COLOR		RGB(65, 65, 65)//RGB(25, 31, 47)// RGB(66, 89, 107)


#define			SYSTEM_SET_NORMAL		0
#define			SYSTEM_SET_DISK			1
#define			SYSTEM_SET_ALARMLINK	2
#define			SYSTEM_SET_RECORDPLAN	3


//double time_2_dbl(timeval time_value);
#define DELETE_OBJECT(x) {delete x; x = NULL;}

typedef struct _LOGIN_DATA
{
    char	ip[128];
    char	uid[32];
    unsigned short port;
    char	user[128];
    char	psw[128];
    int		connectType;
    char	mac[20];
    int     result;
    //    _LOGIN_DATA()
    //    {
    //        ip[0] = 0;
    //        uid[0] = 0;
    //        port = 0;
    //        user[0] = 0;
    //        psw[0] = 0;
    //        connectType = 0;
    //        mac[0] = 0;
    //    }
}LOGIN_DATA;

typedef struct _PREVIEW_INFO
{
    char		ipcUrl[200];
    long		connectType;
    long		streamType; // 码流类型
    long		channel; // 通道
    
}PREVIEW_INFO, *LPPREVIEW_INFO;

typedef struct _PLAYBACK_INFO
{
    int		channels; // 通道
    unsigned int st;
    unsigned int et;
    unsigned int offset;
}PLAYBACK_INFO, *LPPLAYBACK_INFO;

typedef struct
{
    int		ptzCmd;
    int		param1;
    int		param2;
    int		param3;
    int		param4;
    char*	param5;
    
}PTZ_CMD;

#define MAX_CHANNEL_NUMBER  12

//现在实时流回调函数只返回两种媒体流
#define        DATA_TYPE_VIDEO_H264                  1        //流数据是h264视频数据
#define        DATA_TYPE_AUDIO_PCM                  2        //流数据是g711音频数据


#ifdef __APPLE__
typedef unsigned long DWORD;
#endif
