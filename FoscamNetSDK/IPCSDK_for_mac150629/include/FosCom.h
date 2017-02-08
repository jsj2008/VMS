/*
* Copyright (c) 2014,foscam
* All rights reserved.
*
* File Name: FosCom.h
* Abstract: FosSdk Definition File
*
* Current Version: 1.0
* Author: FosCam
*
* Completion Date: 2014-09-22
*/

#ifndef __FOSSDK_SRC_INCLUDE_FOSCOM__
#define __FOSSDK_SRC_INCLUDE_FOSCOM__

#ifdef _WIN32
#define FOSAPI				__stdcall
#ifdef FOSSDK_EXPORTS
#define FOSSDK				__declspec(dllexport)
#else
#define FOSSDK				__declspec(dllimport)
#endif
#else
#define FOSAPI
#define FOSSDK
#endif

#define FOSHANDLE		unsigned int

#define FOSSDK_VERSION  "2.0.1.3621"

#ifdef DISABLE_4200
#pragma warning (disable : 4200)	//disable zero byte data[0] warning.
#endif

#define FOSHANDLE_INVALID		 0x0FFFFFFF				//Invalid handle.
#define FOSHANDLE_ERR			 0x0F000000				//Error handle.
#define FOS_TIMEOUT			 0x0FF00000				//Time out.
#define FOS_CANCEL				 0x0FE00000				//Cancel.
#define FOS_APITIMEERR			 0x0FD00000				//Api time error.
#define FOS_OK					0						//Ok.

#define USRCOUNT							8			//User count.
#define NAMESIZE							32			//Name size.
#define COMMSIZE							64			//Comment size.
#define NODESIZE                            50
#define FOSBABY_SCHEDULE_COUNT				7			//Fosbaby schedule count.
#define FOS_PUBKEY_LEN						128			//Pubkey len.
#define FOS_URL_LEN						258				//url len
#define FOS_NTPSERVER_LEN					64			//NTP server len
#define FOS_MAX_PRESETPOINT_COUNT			16			
#define FOS_MAX_PRESETPOINT_NAME_LEN			128
#define FOS_MAX_CURISEMAP_COUNT				8
#define FOS_MAX_CURISEMAP_NAME_LEN			128
#define FOS_MAX_PRESETPOINT_COUNT_OF_MAP		8
#define FOS_MAX_OSDMASKAREA_COUNT			4
#define FOS_MAX_SCHEDULE_COUNT				7
#define FOS_MAX_AREA_COUNT					10
#define FOS_MAX_RECORD_COUNT				10
#define FOS_MAX_VIDEOSTREAM_TYPE			4
#define FOS_LED_SCHEDULE_COUNT				3
#define FOS_MAX_RECORDINFO_LEN				256
#define IPADDR_LEN		32
#define GATE_LEN 16
#define MASK_LEN 16
#define DNS_LEN 16
#define SSID_LEN 128
#define PSK_LEN 128
#define KEY_LEN 63
#define CONNECTEDAP_LEN 20
#define HOSTNAME_LEN 32
#define USER_LEN 32
#define PASSWORD_LEN 64
#define FACTORYDDNS_LEN 64
#define FTPADDR_LEN 32
#define USERNAME_LEN 32
#define RECIEVER_LEN 32	     //需要确认		 
#define SENDER_LEN 1
#define SERVER_LEN 32
#define AP_LEN 128
#define AP_NUM 10
#define DEV_LEN	64
#define DEVLIST_SIZE	9
#define MUSICNAME_LEN	256
#define MUSICLISTNAME_LEN	256
#define MAX_MUSIC_COUNT	10
#define AUTHORIZATIONCODE_LEN	128
#define TOKEN_LEN	64
#define LOG_CNT	1000
#define LOG_LEN	128
#define UID_LEN 32
#define PASSWORDKEY_LEN 32
#define STREAMID_LEN    64
#define PUBLISHTOKEN_LEN 64
#define GUID_LEN         64
#define DEVID_LEN        32
#define ACCESSTOKEN_LEN  128
#define REFRESHTOKEN_LEN 128
#define AUTHADDR_LEN     256
#define STATUSMSG_LEN    128

#ifndef MAX_PATH
#define MAX_PATH							260
#endif

typedef enum{
	FOSCMDRET_OK,									//ok.
	FOSCMDRET_FAILD,								//faild.
	FOSUSRRET_USRNAMEORPWD_ERR,						//username or password error.
	FOSCMDRET_EXCEEDMAXUSR,						//exceed max user number.
	FOSCMDRET_NO_PERMITTION,						//no permit.
	FOSCMDRET_UNSUPPORT,							//not support.
	FOSCMDRET_BUFFULL,								//buf is full.
	FOSCMDRET_ARGS_ERR,							//
	FOSCMDRET_UNKNOW,								//unknow.
	FOSCMDRET_NOLOGIN,								//user no login.
	FOSCMDRET_NOONLINE,							//the device is no online.
	FOSCMDRET_ACCESSDENY,							//the access deny.
	FOSCMDRET_DATAPARSEERR,						//parse data failed.
	FOSCMDRET_USRNOTEXIST,
	FOSCMDRET_SYSBUSY,
	FOSUSRRET_USRPWD_ERR,
	FOSCMDRET_NEED_SET_PASSWORD,
	FOSCMDRET_USR_LOCKED,
	FOSCMDRET_APITIMEERR = FOS_APITIMEERR,			//api time error.
	FOSCMDRET_INTERFACE_CANCEL_BYUSR = FOS_CANCEL,	//cancle
	FOSCMDRET_TIMEOUT = FOS_TIMEOUT,				//time out.
	FOSCMDRET_HANDLEERR = FOSHANDLE_ERR,
}FOSCMD_RESULT;									//Result code.

typedef enum  
{
	FOSDECTYPE_VIDEORAW,

	FOSDECTYPE_ARGB32,	  //packed ARGB 8:8:8:8, 32bpp, ARGBARGB...
	FOSDECTYPE_RGBA32,    //packed RGBA 8:8:8:8, 32bpp, RGBARGBA...
	FOSDECTYPE_ABGR32,    //packed ABGR 8:8:8:8, 32bpp, ABGRABGR...
	FOSDECTYPE_BGRA32,    //packed BGRA 8:8:8:8, 32bpp, BGRABGRA...
	FOSDECTYPE_RGB24,	  //packed RGB 8:8:8, 24bpp, RGBRGB...
	FOSDECTYPE_BGR24,     //packed RGB 8:8:8, 24bpp, BGRBGR...
	FOSDECTYPE_RGB565BE,  //packed RGB 5:6:5, 16bpp, (msb)   5R 6G 5B(lsb), big-endian
	FOSDECTYPE_RGB565LE,  //packed RGB 5:6:5, 16bpp, (msb)   5R 6G 5B(lsb), little-endian
	FOSDECTYPE_BGR565BE,  //packed BGR 5:6:5, 16bpp, (msb)   5B 6G 5R(lsb), big-endian
	FOSDECTYPE_BGR565LE,  //packed BGR 5:6:5, 16bpp, (msb)   5B 6G 5R(lsb), little-endian

	FOSDECTYPE_YUV420,
	FOSDECTYPE_YUYV422,
	FOSDECTYPE_UYVY422,
	FOSDECTYPE_H264,
	FOSDECTYPE_MJPEG,	
	FOSDECTYPE_MJPEG_BASE64,
	FOSDECTYPE_H264_BASE64,

	FOSDECTYPE_AUDIORAW,
	FOSDECTYPE_G726,
	FOSDECTYPE_G711U,
	FOSDECTYPE_PCM,
	FOSDECTYPE_ADPCM,
	FOSDECTYPE_G711A,
	FOSDECTYPE_AAC,
}FOSDECFMT;								//The format of data which come from device.

typedef enum{
	FOSRDTYPE_AVI,
	FOSCNTYPE_MP4,
	FOSCNTYPE_TS,
	FOSCNTYPE_PS,
}FOSRECORDTYPE;							//Record type,different type save different file.

typedef enum
{
	FOSRECORD_ERROR_NO_ENOUGE_SPACE = 10000,			//No enouge space.
	FOSRECORD_ERROR_ACHIEVE_FILE_MAXSIZE,		//File has set a maxsize,achieve file maxsize will stop record.
	FOSRECORD_ERROR_RESOLUTION_CHANGE,			//Video resolution change.
	FOSRECORD_ERROR_FILE_PATH_NOEXIST,			//The file path does not exist
	FOSRECORD_ERROR_UNKNOW,					//
}FOSRECORD_ERROR;								//The error of record.

typedef enum
{
	FOSMEDIATYPE_VIDEO,
	FOSMEDIATYPE_AUDIO,
	FOSMEDIATYPE_ZFRAME, //RecodecZframe
}FOSMEDIATYPE;								//Media type.

typedef enum{
	FOSSTREAM_MAIN,						//Main stream 
	FOSSTREAM_SUB,						//Sub stream.
}FOSSTREAM_TYPE;							//Stream type.

typedef enum {
	FOS_HANDLE_INIT,
	FOS_HANDLE_CONNECTTING,
	FOS_HANDLE_ONLINE,
	FOS_HANDLE_OFFLINE,
	FOS_HANDLE_ONLINE_LOGINERR,
	FOS_HANDLE_INVALIDE,
	FOS_HANDLE_LOGOUT,
	FOS_HANDLE_ONLINE_USRORPWDERR,
	FOS_HANDLE_ONLINE_EXCEEDMAXUSR,
}FOS_HANDLE_STATE;

typedef enum{
	FOSCNTYPE_P2P,
	FOSCNTYPE_IP,
}FOSIPC_CONNECTTION_TYPE;						//IPC connection type.

typedef enum{
	FOSIPC_H264,
	FOSIPC_MJ,
	FOSNVR,
	FOS_UNKNOW,
}FOSDEV_TYPE;

typedef struct {							//Discovery IPC,save ipc information.
	char		mac[16];
	char		name[24];
	unsigned int			ip;
	unsigned int			mask;
	unsigned int			gateway;
	unsigned int			dns;
	FOSDEV_TYPE				type;
	unsigned short			mediaPort;
	unsigned short			port;
	unsigned int			sys_ver;
	unsigned int			app_ver;
	unsigned int			dhcp_enabled;
	char					uid[36];//p2p uid.
} FOSDISCOVERY_NODE;

typedef struct							//Save Video info.
{ 
	unsigned int   picWidth;				//video width.
	unsigned int   picHeight;				//video height.
	unsigned int   frameRate;				//video frame rate.
	unsigned int   bitRate;				//video framerate.
}FOSVIDEO_INFO; 

typedef struct							//Save Audio info.
{ 
	unsigned int   bitRate;				//Bit rate.
	unsigned int   channel;				//Channels.
	int			  sampale;				//Sampale.
}FOSAUDIO_INFO;

#ifndef _WIN32
#define ATTRIBUTE_PACKED __attribute__((packed))
#else
#define ATTRIBUTE_PACKED
#pragma pack(push)
#pragma pack(1)
#endif
typedef struct   
{ 
	int						  channel;
    long long                 time;
    unsigned int              index;
	FOSMEDIATYPE			  type;		//Is video or audio
	FOSDECFMT				  fmt;		//The format of video or audio.
	short					  isKey;
	short                     multiAudioPage;
	int						  frameTag;	
	union{ 
		FOSVIDEO_INFO      video;		//Media type is video.
		FOSAUDIO_INFO      audio;		//Media type is audio.
	} media;
	unsigned long long      pts;		//Pts.
	unsigned int			  len;		//Size of data.
	char					  data[0];	//Just data.
}ATTRIBUTE_PACKED FOSDEC_DATA;							//Save the video or audio data,include video or audio information.
#ifdef _WIN32
#pragma pack(pop)
#endif

typedef struct P2PMODE
{
	unsigned char mode;
	char RemoteIP[17];
	unsigned char NatType;
} FOS_P2PMODE;

typedef enum
{
	LEVEL_NONE,		
	LEVEL_ERROR,			
	LEVEL_WARNING,		
	LEVEL_INFO,		
	LEVEL_ALL,			
}LogLevel;		

#endif
