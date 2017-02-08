#ifndef __FOSCAM_NET_SDK_H__
#define __FOSCAM_NET_SDK_H__

//#include "PublicDef.h"
#import "../PublicDef.h"
#import "../IPCSDK_for_mac150629/include/FosDef.h"

#ifdef _WIN32
    #define FOS_NET_API				__stdcall

    #ifdef FOSSDK_EXPORTS
        #define FOS_NET_SDK				__declspec(dllexport)
    #else
        #define FOS_NET_SDK				__declspec(dllimport)
    #endif
#else
    #define FOS_NET_API
    #define FOS_NET_SDK
#endif

//#pragma pack(push) //±£¥Ê∂‘∆Î◊¥Ã¨
//#pragma pack(1) 

#define  STREAM_TYPE_FIRST		0
#define  STREAM_TYPE_SECOND		1


//“Ù ”∆µªÿµ˜∫Ø ˝∂®“Â
typedef struct _FOSCAM_IPC_NET_EVENT_DATA
{
    int		pwrFreq;
    FOSIRCUTSTATE ircutState;
//    _FOSCAM_IPC_NET_EVENT_DATA()
//    {
//        pwrFreq = 0;
//    };
    
}FOSCAM_IPC_NET_EVENT_DATA, *LPFOSCAM_IPC_NET_EVENT_DATA;



typedef enum
{
    FOSCAM_NET_CONFIG_PRODUCT_INFO,
    FOSCAM_NET_CONFIG_DEVICE_NAME,
    FOSCAM_NET_CONFIG_DEVICE_INFO,
    FOSCAM_NET_CONFIG_DEVICE_STATE,
    FOSCAM_NET_CONFIG_NETWORK_IP,
    FOSCAM_NET_CONFIG_NETWORK_PPPOE,
    FOSCAM_NET_CONFIG_NETWORK_UPNP,
	FOSCAM_NET_CONFIG_NETWORK_PORT,
	FOSCAM_NET_CONFIG_NETWORK_P2P_INFO,
	FOSCAM_NET_CONFIG_NETWORK_P2P_ENABLE,
	FOSCAM_NET_CONFIG_NETWORK_P2P_PORT,
	FOSCAM_NET_CONFIG_SYSTEM_RESTART,
	FOSCAM_NET_CONFIG_SYSTEM_RESET,
	FOSCAM_NET_CONFIG_SYSTEM_UPDATE,
	FOSCAM_NET_CONFIG_SYSTEM_EXPORT,
	FOSCAM_NET_CONFIG_SYSTEM_IMPORT,
	FOSCAM_NET_CONFIG_VIDEO_OSD,
    FOSCAM_NET_CONFIG_VIDEO_OSD_MSG,
	FOSCAM_NET_CONFIG_VIDEO_IRLAMP_TYPE,
    FOSCAM_NET_CONFIG_VIDEO_IRCUT_STATE,
	FOSCAM_NET_CONFIG_VIDEO_IRLAMP_OPEN,
	FOSCAM_NET_CONFIG_VIDEO_IRLAMP_CLOSE,
	FOSCAM_NET_CONFIG_VIDEO_IMAGE_PARAM,
	FOSCAM_NET_CONFIG_VIDEO_IMAGE_PARAM_HUE,
	FOSCAM_NET_CONFIG_VIDEO_IMAGE_PARAM_SATURATION,
	FOSCAM_NET_CONFIG_VIDEO_IMAGE_PARAM_CONTRAST,
	FOSCAM_NET_CONFIG_VIDEO_IMAGE_PARAM_SHARPNESS,
	FOSCAM_NET_CONFIG_VIDEO_IMAGE_PARAM_BRIGHTNESS,
	FOSCAM_NET_CONFIG_VIDEO_IMAGE_PARAM_DEFALUT,
	FOSCAM_NET_CONFIG_VIDEO_IRLAMP_PLAN,
	FOSCAM_NET_CONFIG_DEVICE_TIME,
	FOSCAM_NET_CONFIG_VIDEO_ENCODE_MAIN,
	FOSCAM_NET_CONFIG_VIDEO_ENCODE_SUB,
	FOSCAM_NET_CONFIG_VIDEO_ENCODE_MAIN_STREAM_TYPE,
	FOSCAM_NET_CONFIG_VIDEO_ENCODE_SUB_STREAM_TYPE,
    FOSCAM_NET_CONFIG_STREAM_ENCODE_INFO,
	FOSCAM_NET_CONFIG_MOTION,
	FOSCAM_NET_CONFIG_VIDEO_MIRROR_FLIP,
	FOSCAM_NET_CONFIG_VIDEO_MIRROR,
	FOSCAM_NET_CONFIG_VIDEO_FLIP,
    FOSCAM_NET_CONFIG_OSD_MASK_AREA,
	FOSCAM_NET_CONFIG_VIDEO_PWR_FREG,
	FOSCAM_NET_CONFIG_ALARM_AUDIO,
	FOSCAM_NET_CONFIG_PTZ_SPEED,
    FOSCAM_NET_CONFIG_PTZ_PATTERN_GOTO,
    FOSCAM_NET_CONFIG_PTZ_PATTERN_STOP,
    FOSCAM_NET_CONFIG_PTZ_PATTERN_DEL,
    FOSCAM_NET_CONFIG_PTZ_PATTERN_MAP_LIST,
    FOSCAM_NET_CONFIG_PTZ_PATTERN_MAP_INFO,
	FOSCAM_NET_CONFIG_PTZ_CRUISE,
	FOSCAM_NET_CONFIG_PTZ_TEST_MODE,
    FOSCAM_NET_CONFIG_PTZ_CRUISE_CTRL_MODE,
    FOSCAM_NET_CONFIG_PTZ_CRUISE_TIME,
    FOSCAM_NET_CONFIG_PTZ_CRUISE_TIME_CUSTOM,
    FOSCAM_NET_CONFIG_PTZ_SELF_TEST_PRESET_NAME,
    FOSCAM_NET_CONFIG_PTZ_SELF_TEST_MODE,
    FOSCAM_NET_CONFIG_PTZ_CRUISE_LOOP_CNT,
    FOSCAM_NET_CONFIG_PTZ_CRUISE_MAP_LIST,
    FOSCAM_NET_CONFIG_PTZ_CRUISE_MAP_INFO,
    FOSCAM_NET_CONFIG_PTZ_CRUISE_MAP_PREPOINT_TINGGER_TIME,
    FOSCAM_NET_CONFIG_PTZ_PRESET_POINT_LIST,
    FOSCAM_NET_CONFIG_PTZ_ADD_PRESET_POINT,
    FOSCAM_NET_CONFIG_PTZ_DEL_PRESET_POINT,
    FOSCAM_NET_CONFIG_PTZ_RUN_PRESET_POINT,
    FOSCAM_NET_CONFIG_PTZ_START_CRUISE,
    FOSCAM_NET_CONFIG_PTZ_STOP_CRUISE,
    FOSCAM_NET_CONFIG_VIDEO_OSD_MASK_ENABLE,
    FOSCAM_NET_CONFIG_NETWORK_WIFI,
    FOSCAM_NET_CONFIG_NETWORK_DDNS,
    FOSCAM_NET_CONFIG_NETWORK_DDNS_RESTORE_TO_FACTORY,
    FOSCAM_NET_CONFIG_NETWORK_FTP,
    FOSCAM_NET_CONFIG_NETWORK_SMTP,
    FOSCAM_NET_CONFIG_DEVICE_LED_ENABLE_STATE,
    FOSCAM_NET_CONFIT_DEVICE_SYSTEM_TIME,
    FOSCAM_NET_CONFIG_VIDEO_MOTION_DETECT,
    FOSCAM_NET_CONFIG_VIDEO_MOTION_DETECT1,
    FOSCAM_NET_CONFIG_PC_AUDIO_ALARM,
    FOSCAM_NET_CONFIG_DEVICE_TEMPERATURE_ALARM,
    FOSCAM_NET_CONFIG_NETWORK_WIFI_REFRESH,
    FOSCAM_NET_CONFIG_NETWORK_WIFI_LIST,
    FOSCAM_NET_CONFIG_NETWORK_SMTP_TEST,
    FOSCAM_NET_CONFIG_NETWORK_FTP_TEST,
    FOSCAM_NET_CONFIG_VIDEO_TOGGLE_TALK_STATE,
    FOSCAM_NET_CONFIG_VIDEO_TALK_DATA,
    FOSCAM_NET_CONFIG_VIDEO_SCHEDULE_SNAP,
    FOSCAN_NET_CONFIG_VIDEO_SNAP,
}FOSCAM_NET_CONFIG_TYPE;


typedef struct
{
    char *data;
    int len;
}FOSCAM_NET_TALK_DATA;

typedef struct
{
	void	*info;
    void    *info2;
    void    *info3;
    void    *info4;
}FOSCAM_NET_CONFIG;

typedef struct
{
	int mirror;
	int flip;

}FOSCAM_NET_CONFIG_MIRROR_FLIP;

typedef struct
{
    void *input;
    void *result;
}FOSCAM_NET_CONFIG_TEST;

typedef void  (FOS_NET_API* NET_DataCallBack)
(long realHandle,
 unsigned long  dataType ,
 unsigned char* buffer,
 unsigned long bufferSize,
 void *userData,
 double pt);

typedef void (FOS_NET_API* NET_Event_CallBack)
(long userId,
 void *netEvent,
 void *userData);

/*
∑¢ÀÕ‘∆Ã®√¸¡Ó∫Ø ˝
int nCameraID
int nPtzCmd
int nParam1
int nParam2
int nParam3
int nParam4

1 µΩ 54  « nPtzCmd √¸¡Ó

1	£≠	Õ£÷πÀ˘”–¡¨–¯¡ø(æµÕ∑,‘∆Ã®)∂Ø◊˜	(Param1: Œﬁ–ß, Param2: Œﬁ–ß, Param3: Œﬁ–ß, Param4: Œﬁ–ß)
2	£≠	Ωπæ‡±‰¥Û(±∂¬ ±‰¥Û)		(Param1: 1-ø™ º/0-Õ£÷π, Param2: ÀŸ∂» [0-10,0±Ì æƒ¨»œÀŸ∂»,1-10±Ì æÀŸ∂»º∂±], Param3: Œﬁ–ß, Param4: Œﬁ–ß)
3	£≠	Ωπæ‡±‰–°(±∂¬ ±‰–°)		(Param1: 1-ø™ º/0-Õ£÷π, Param2: ÀŸ∂» [0-10,0±Ì æƒ¨»œÀŸ∂»,1-10±Ì æÀŸ∂»º∂±], Param3: Œﬁ–ß, Param4: Œﬁ–ß)
4	£≠	Ωπµ„«∞µ˜				(Param1: 1-ø™ º/0-Õ£÷π, Param2: ÀŸ∂» [0-10,0±Ì æƒ¨»œÀŸ∂»,1-10±Ì æÀŸ∂»º∂±], Param3: Œﬁ–ß, Param4: Œﬁ–ß)
5	£≠	Ωπµ„∫Ûµ˜				(Param1: 1-ø™ º/0-Õ£÷π, Param2: ÀŸ∂» [0-10,0±Ì æƒ¨»œÀŸ∂»,1-10±Ì æÀŸ∂»º∂±], Param3: Œﬁ–ß, Param4: Œﬁ–ß)
6	£≠	π‚»¶¿©¥Û				(Param1: 1-ø™ º/0-Õ£÷π, Param2: ÀŸ∂» [0-10,0±Ì æƒ¨»œÀŸ∂»,1-10±Ì æÀŸ∂»º∂±], Param3: Œﬁ–ß, Param4: Œﬁ–ß)
7	£≠	π‚»¶Àı–°				(Param1: 1-ø™ º/0-Õ£÷π, Param2: ÀŸ∂» [0-10,0±Ì æƒ¨»œÀŸ∂»,1-10±Ì æÀŸ∂»º∂±], Param3: Œﬁ–ß, Param4: Œﬁ–ß)
8	£≠	ø™◊‘∂ØΩπæ‡(◊‘∂Ø±∂¬ )	(Param1: 1-ø™ º/0-Õ£÷π, Param2: Œﬁ–ß, Param3: Œﬁ–ß, Param4: Œﬁ–ß)
9	£≠	ø™◊‘∂Øµ˜Ωπ				(Param1: 1-ø™ º/0-Õ£÷π, Param2: Œﬁ–ß, Param3: Œﬁ–ß, Param4: Œﬁ–ß)
10	£≠	ø™◊‘∂Øπ‚»¶				(Param1: 1-ø™ º/0-Õ£÷π, Param2: Œﬁ–ß, Param3: Œﬁ–ß, Param4: Œﬁ–ß)
11	£≠	‘∆Ã®…œ—ˆ				(Param1: 1-ø™ º/0-Õ£÷π, Param2: ÀŸ∂» [0-10,0±Ì æƒ¨»œÀŸ∂»,1-10±Ì æÀŸ∂»º∂±], Param3: Œﬁ–ß, Param4: Œﬁ–ß)
12	£≠	‘∆Ã®œ¬∏©				(Param1: 1-ø™ º/0-Õ£÷π, Param2: ÀŸ∂» [0-10,0±Ì æƒ¨»œÀŸ∂»,1-10±Ì æÀŸ∂»º∂±], Param3: Œﬁ–ß, Param4: Œﬁ–ß)
13	£≠	‘∆Ã®◊Û◊™				(Param1: 1-ø™ º/0-Õ£÷π, Param2: ÀŸ∂» [0-10,0±Ì æƒ¨»œÀŸ∂»,1-10±Ì æÀŸ∂»º∂±], Param3: Œﬁ–ß, Param4: Œﬁ–ß)
14	£≠	‘∆Ã®”“◊™				(Param1: 1-ø™ º/0-Õ£÷π, Param2: ÀŸ∂» [0-10,0±Ì æƒ¨»œÀŸ∂»,1-10±Ì æÀŸ∂»º∂±], Param3: Œﬁ–ß, Param4: Œﬁ–ß)
15	£≠	‘∆Ã®…œ—ˆ∫Õ◊Û◊™			(Param1: 1-ø™ º/0-Õ£÷π, Param2: ÀŸ∂» [0-10,0±Ì æƒ¨»œÀŸ∂»,1-10±Ì æÀŸ∂»º∂±], Param3: Œﬁ–ß, Param4: Œﬁ–ß)
16	£≠	‘∆Ã®…œ—ˆ∫Õ”“◊™			(Param1: 1-ø™ º/0-Õ£÷π, Param2: ÀŸ∂» [0-10,0±Ì æƒ¨»œÀŸ∂»,1-10±Ì æÀŸ∂»º∂±], Param3: Œﬁ–ß, Param4: Œﬁ–ß)
17	£≠	‘∆Ã®œ¬∏©∫Õ◊Û◊™			(Param1: 1-ø™ º/0-Õ£÷π, Param2: ÀŸ∂» [0-10,0±Ì æƒ¨»œÀŸ∂»,1-10±Ì æÀŸ∂»º∂±], Param3: Œﬁ–ß, Param4: Œﬁ–ß)
18	£≠	‘∆Ã®œ¬∏©∫Õ”“◊™			(Param1: 1-ø™ º/0-Õ£÷π, Param2: ÀŸ∂» [0-10,0±Ì æƒ¨»œÀŸ∂»,1-10±Ì æÀŸ∂»º∂±], Param3: Œﬁ–ß, Param4: Œﬁ–ß)
19	£≠	‘∆Ã®◊Û”“◊‘∂Ø…®√Ë		(Param1: 1-ø™ º/0-Õ£÷π, Param2: ÀŸ∂» [0-10,0±Ì æƒ¨»œÀŸ∂»,1-10±Ì æÀŸ∂»º∂±], Param3: Œﬁ–ß, Param4: Œﬁ–ß)

30	£≠	…Ë÷√‘§÷√µ„				(Param1: ‘§÷√µ„–Ú∫≈[>=0], Param2: Œﬁ–ß, Param3: Œﬁ–ß, Param4: Œﬁ–ß)
31	£≠	«Â≥˝‘§÷√µ„				(Param1: ‘§÷√µ„–Ú∫≈[>=0], Param2: Œﬁ–ß, Param3: Œﬁ–ß, Param4: Œﬁ–ß)
32	£≠	◊™µΩ‘§÷√µ„				(Param1: ‘§÷√µ„–Ú∫≈[>=0], Param2: Œﬁ–ß, Param3: Œﬁ–ß, Param4: Œﬁ–ß)

41	£≠	∆Ù∂Ø—≤∫Ωº«“‰			(Param1: —≤∫Ω¬∑œﬂ∫≈[>=0], Param2: Œﬁ–ß, Param3: Œﬁ–ß, Param4: Œﬁ–ß)
42	£≠	πÿ±’—≤∫Ωº«“‰			(Param1: —≤∫Ω¬∑œﬂ∫≈[>=0], Param2: Œﬁ–ß, Param3: Œﬁ–ß, Param4: Œﬁ–ß)
43	£≠	Ω´‘§÷√µ„º”»Î—≤∫Ω–Ú¡–	(Param1: —≤∫Ω¬∑œﬂ∫≈[>=0], Param2: ‘§÷√µ„–Ú∫≈[>=0], Param3: Õ£∂Ÿ ±º‰[√Î,>=0], Param4: —≤∫ΩÀŸ∂»[1-10])
44	£≠	ø™ º—≤∫Ω				(Param1: —≤∫Ω¬∑œﬂ∫≈[>=0], Param2: Œﬁ–ß, Param3: Œﬁ–ß, Param4: Œﬁ–ß)
45	£≠	Õ£÷π—≤∫Ω				(Param1: —≤∫Ω¬∑œﬂ∫≈[>=0], Param2: Œﬁ–ß, Param3: Œﬁ–ß, Param4: Œﬁ–ß)

51	£≠	∆Ù∂ØπÏº£º«“‰			(Param1: πÏº£∫≈[>=0], Param2: Œﬁ–ß, Param3: Œﬁ–ß, Param4: Œﬁ–ß)
52	£≠	πÿ±’πÏº£º«“‰			(Param1: πÏº£∫≈[>=0], Param2: Œﬁ–ß, Param3: Œﬁ–ß, Param4: Œﬁ–ß)
53	£≠	ø™ ºπÏº£				(Param1: πÏº£∫≈[>=0], Param2: Œﬁ–ß, Param3: Œﬁ–ß, Param4: Œﬁ–ß)
54	£≠	Õ£÷ππÏº£				(Param1: πÏº£∫≈[>=0], Param2: Œﬁ–ß, Param3: Œﬁ–ß, Param4: Œﬁ–ß)
*/

#define  FOSCAM_IPC_PTZ_CMD_STOP_ALL		1
#define  FOSCAM_IPC_PTZ_CMD_ZOOM_IN			2
#define  FOSCAM_IPC_PTZ_CMD_ZOOM_OUT		3
#define  FOSCAM_IPC_PTZ_CMD_FOCUS_NEAR		4
#define  FOSCAM_IPC_PTZ_CMD_FOCUS_FAR		5
#define  FOSCAM_IPC_PTZ_CMD_IRIS_OPEN		6
#define  FOSCAM_IPC_PTZ_CMD_IRIS_CLOSE		7
#define  FOSCAM_IPC_PTZ_CMD_UP			11
#define  FOSCAM_IPC_PTZ_CMD_DOWN		12
#define  FOSCAM_IPC_PTZ_CMD_LEFT		13
#define  FOSCAM_IPC_PTZ_CMD_RIGHT		14
#define  FOSCAM_IPC_PTZ_CMD_LEFT_UP		15
#define  FOSCAM_IPC_PTZ_CMD_LEFT_DOWN	17
#define  FOSCAM_IPC_PTZ_CMD_RIGHT_UP	16
#define  FOSCAM_IPC_PTZ_CMD_RIGHT_DOWN	18
#define  FOSCAM_IPC_PTZ_CMD_AUTO		19
#define  FOSCAM_IPC_PTZ_CMD_ADD_PRESET      29
#define  FOSCAM_IPC_PTZ_CMD_SET_PRESET		30
#define  FOSCAM_IPC_PTZ_CMD_CLEAR_PRESET	31
#define  FOSCAM_IPC_PTZ_CMD_GOTO_RRESET		32
#define  FOSCAM_IPC_PTZ_CMD_BEGIN_PATTERN		41
#define  FOSCAM_IPC_PTZ_CMD_SET_PATTERN		43
#define  FOSCAM_IPC_PTZ_CMD_END_PATTERN		42
#define  FOSCAM_IPC_PTZ_CMD_START_PATTERN		44
#define  FOSCAM_IPC_PTZ_CMD_STOP_PATTERN		45

#ifdef __cplusplus
extern "C" {
#endif
    FOS_NET_SDK bool FOSCAM_NET_Init(void);
    FOS_NET_SDK bool FOSCAM_NET_Cleanup(void);
    //FOS_NET_SDK long FOSCAM_NET_Login1(long,int,FOSDEV_TYPE,LOGIN_DATA,int *);
    FOS_NET_SDK long FOSCAM_NET_Login(LOGIN_DATA *loginData);
    FOS_NET_SDK bool FOSCAM_NET_Logout(long userID);
    
    FOS_NET_SDK bool FOSCAM_NET_ModifyLoginInfo(long userID, char *newName, char* newPwd);
    //FOS_NET_SDK void FOSCAM_NET_Logout1(long user_id);
    //FOS_NET_SDK bool FOSCAM_NET_RealPlay1(long userID, LPPREVIEW_INFO lpPreviewInfo, NET_DataCallBack netDataCB, void* user);
    FOS_NET_SDK long FOSCAM_NET_RealPlay(long userID, LPPREVIEW_INFO lpPreviewInfo, NET_DataCallBack netDataCB, void* user);  // ∑µªÿ‘§¿¿æ‰±˙ realHandle
    FOS_NET_SDK bool FOSCAM_NET_StopRealPlay(long userID);
    FOS_NET_SDK int FOSCAM_NET_PTZ(long userID, PTZ_CMD ptz);
    FOS_NET_SDK bool FOSCAM_NET_Search(void* node, long* size);
    FOS_NET_SDK bool FOSCAM_NET_GetConfig(long userID, long type, void *config);
    FOS_NET_SDK bool FOSCAM_NET_SetConfig(long userID, long type, void *config);
    FOS_NET_SDK bool FOSCAM_NET_SetEventCB(long userID, NET_Event_CallBack cbNetEvent, void *userData);
    FOS_NET_SDK bool FOSCAM_NET_GetEventData(long userID, FOSCAM_IPC_NET_EVENT_DATA* eventData);
    FOS_NET_SDK bool FOSCAM_NET_OpenTalk( long userID );
    FOS_NET_SDK bool FOSCAM_NET_Talk(long userID, char* data, int dataLen);
    FOS_NET_SDK bool FOSCAM_NET_CloseTalk( long userID );
    //#pragma pack(pop) //ª÷∏¥∂‘∆Î◊¥Ã¨
#ifdef __cplusplus
}
#endif

// ≥ı ºªØ
#define INVALID_IPC      -2
#define INVALID_NVR      -3

#endif
