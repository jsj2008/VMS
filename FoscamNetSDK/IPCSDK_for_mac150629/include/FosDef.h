/*
* Copyright (c) 2014,foscam
* All rights reserved.
*
* File Name: FosDef.h
* Abstract: FosSdk Definition File
*
* Current Version: 1.0
* Author: FosCam
*
* Completion Date: 2014-09-22
*/

#ifndef __FOSSDK_SRC_INCLUDE_FOSDEF__
#define __FOSSDK_SRC_INCLUDE_FOSDEF__
#include <string.h>
#include "FosCom.h"

typedef enum{
	FOSPTZ_UP,									//ptz move up.
	FOSPTZ_DOWN,
	FOSPTZ_LEFT,
	FOSPTZ_RIGHT,
	FOSPTZ_LEFT_UP,
	FOSPTZ_LEFT_DOWN,
	FOSPTZ_RIGHT_UP,
	FOSPTZ_RIGHT_DOWN,
	FOSPTZ_CENTER,						//ptz move center.
	FOSPTZ_STOP,							//stop move.
}FOSPTZ_CMD;

typedef enum
{
	FOSPTZ_VERY_SLOW,		//ptz moved very slowly
	FOSPTZ_SLOW,			//ptz moved slowly
	FOSPTZ_NORMAL_SPEED,	//ptz moved normally
	FOSPTZ_FAST,			//ptz moved fast
	FOSPTZ_VERY_FAST		//ptz moved very fast
}FOSPTZ_SPEED;

typedef enum
{
	FOSPTZZOOM_SLOW,		//ptz zoom slowly
	FOSPTZZOOM_NORMAL,		//ptz zoom normally
	FOSPTZZOOM_FAST		//ptz zoom fast
}FOSPTZZOOM_SPEED;

typedef enum{
	FOSIMAGE_HUE,					//Image hue.
	FOSIMAGE_SATURATION,			//Image saturation.
	FOSIMAGE_CONTRAST,				//Image contrast.
	FOSIMAGE_SHARPNESS,			//Image sharpness.
	FOSIMAGE_BRIGHTNESS,			//Image brightness.
	FOSIMAGE_DEFALUT,				
}FOSIMAGE_CMD;					//This is use to set image attribute.

typedef enum
{
	FOSPTZ_ZOOMIN,
	FOSPTZ_ZOOMOUT,
	FOSPTZ_ZOOMSTOP
}FOS_PTZ_ZOOM;

typedef enum
{
	FOSPTZ_FOCUSNEAR,
	FOSPTZ_FOCUSFAR,
	FOSPTZ_FOCUSSTOP
}FOS_PTZ_FOCUS;

 

#ifndef _WIN32
#define ATTRIBUTE_PACKED __attribute__((packed))
#else
#define ATTRIBUTE_PACKED
#pragma pack(push)
#pragma pack(1)
#endif

typedef struct
{
	int resolution;
	int bitRate;
	int frameRate;
	int GOP;
	int isVBR;
} ATTRIBUTE_PACKED FOSIPCPROFILEINFO;

typedef struct tagIpcProfileMsg
{ 
	int result; //0=success
	//1=fail
	//2=exceed max user cnt
	unsigned char recordState;
	unsigned char isMute;
	unsigned char volume;
	unsigned char ledState;
	unsigned char presetPointCnt;
	char presetPointList[16][32];
	char curPresetPoint[32];
	unsigned char cruiseMapCnt;
	char cruiseMapList[8][32];
	char curCruiseMap[32];
	unsigned char mainStreamType;
	unsigned char subStreamType;
	FOSIPCPROFILEINFO streamParam[4];
	unsigned char brightness;
	unsigned char contrast;
	unsigned char hue;
	unsigned char saturation;
	unsigned char sharpness;
	unsigned char isMirror;
	unsigned char isFlip;
	unsigned char isAlarming;
	unsigned char alarmType;  // 0=Motion Detect Alarm
	// 1=Sound Alarm
	// 2=IO Alarm
	// 3=TEMPERATURE Alarm
	// 4=HUMIDITY Alarm
	unsigned char pwrFreq;    // 0=60HZ
	// 1=50HZ

	char   mac[13];
	int infraLedMode;   // 0=Auto 1=Manual
	int infraLedState;  // 0=ON 1=OFF
}ATTRIBUTE_PACKED FOS_IpcProfileMsg;	

#ifdef _WIN32
#pragma pack(pop)
#endif

typedef struct  
{
	int state;
}FOSRECORD;					//The device record state.

typedef struct  
{
	int isMute;				//is mute or not.
	int volume;				//the audio volume.
}FOSVOLUME;					//Audio volume.

typedef struct OSDConfigMsg
{
	int isEnableTimeStamp;
	int isEnableDevName;
	int dispPos; // 0=topLeft 1=bottomLeft 2=topRight 3=bottomRight
	char devName[64];
}FOS_OSDConfigMsg;

typedef struct StartPlayResultMsg
{
	int result; // 0=success
	// 1=access deny
	// 2=exceed max user
	// 3=open avi file error
	int videoWidth;
	int videoHeight;
	int totalFrame;
	int totalTime;
	char reserve[32];
}FOS_StartPlayResultMsg;

typedef struct CommonResultMsg 
{ 
	int result; // 0=success // 1=access deny 
	char reserve[32]; 
}FOS_CommonResultMsg;

typedef struct
{
	int curTemperature;
}FOSTEMPRETUREMSG;

typedef struct  
{
	int isConnected;			//Is Connected.
	int quality;				//Wifi signal strength.
}FOSWIFISTATE;				//Wifi state.

typedef struct  
{
	int state;
	int mode;
}FOSIRCUTSTATE;

typedef struct  
{
	int cnt;							//the total of preset point.
	char pointList[16][32];			//the list of preset points.
	char curPoint[32];					//the current preset point.
}FOSPRESETPOINT;

typedef struct  
{
	int cnt;							//the total of cruise map.
	char mapList[8][32];				//the list of cruise maps.
	char curMap[32];					//the current cruise maps.
}FOSCRUISEMAP;

typedef struct
{
	int isMirror;						//mirror or not.
	int isFlip;						//flip or not.
}FOSMIRRORFLIP;

typedef struct  
{
	int resolution;
	int bitRate;
	int frameRate;
	int GOP;
	int isVBR;
}FOSSTREAMPARAMINFO;					//stream para info.

typedef struct  
{
	int mainStreamType;
	int subStreamType;
	FOSSTREAMPARAMINFO param[4];
}FOSSTREAMPARAM;						//stream para.

typedef struct  
{
	int		hue;
	int		saturation;
	int		contrast;
	int		sharpness;
	int		brightness;
}FOSIMAGE;							//image setting.

typedef struct  
{
	int isAlarming;					//is alarming or not.
	int alarmType;					//the type of alarm.
													 // 0=Motion Detect Alarm
													 // 1=Sound Alarm
													 // 2=IO Alarm
													 // 3=TEMPERATURE Alarm
													 // 4=HUMIDITY Alarm
	int isEnableLocalAlarmRecod; 
	int localAlarmRecordSecs;
}FOSALARM;							//Alarm.

typedef struct
{
	unsigned char isAlarming;
	unsigned char alarmType;  // 0=Motion Detect Alarm
	// 1=Sound Alarm
	// 2=IO Alarm
	unsigned char isEnablePCAudioAlarm; // PC Audio Alarm enable state
	unsigned char AlarmSecs;		//Alarm last time,default is 0
	unsigned char Reserve;		//Reserve,default is 0
} FOSPCAUDIOALARM;

typedef struct  
{
	int freq;
}FOSPWRFREQ;

typedef struct
{
	int streamType;
}FOSSTREAMTYPE;						//Stream type.

typedef struct
{
	int streamType;	
}FOSSUBSTREAMTYPE;						//Sub stream type.

typedef struct  
{
	int mainStreamType;				//Main stream type.
	int subStreamType;					//Sub stream type.
	FOSSTREAMPARAMINFO param[4];		//Param.
}FOSSUBSTREAMPARAM;					//Sub stream param.

typedef struct
{
	int result;						//The result of reconnect.
	int usrPrivilege;					//The privilege of user.
    int state;
    int isOnline;
}FOSRECONNECTPARAM;					//Reconnect param.

typedef union
{
	char state;
	char mode;	//playing mode(order or recyclable)
	char path;	//flash or sd
	char minutes;
} FOSMUSIC_PARAM;

typedef struct
{
	char error;
	char errName[100];
} FOSMUSIC_FORMATERR;

typedef struct
{
	char result;
	char cnt;
	char curListName[32];//current list name
	char list[3][32];//musics name
} FOSMUSIC_LIST;

typedef enum
{
	CLOUDSERVER_DROPBOX=1,
	CLOUDSERVER_BAIDU,
}FOS_CLOUDSERVER;

typedef enum
{
	PUSHSERVER_BAIDU=1,
}FOS_PUSHSERVER;

typedef enum
{
	PATH_FLASH,
	PATH_SDCARD,
}FOS_MUSICPATH;

typedef enum
{
	PRODUCTTYPE_H264,
	PRODUCTTYPE_MJPEG,
}FOS_PRODUCTTYPE;

typedef enum{
	RECORD_EVENT_CHG = 0x0000,					//Record event change.
	VOLUME_EVENT_CHG,					//Audio volume event change.
	WIFI_EVENT_CHG,					//Wifi event change.
	IRCUT_EVENT_CHG,
	PROTOCOL_VER,
	PRESET_EVENT_CHG,					//Preset event change.
	CRUISE_EVENT_CHG,					//Cruise event change.
	MIRRORFLIP_EVENT_CHG,				//Mirror flip event change.
	STREAMPARAM_EVENT_CHG,				//Stream param event change.
	IMAGE_EVENT_CHG,					//Image attribute event change.
	ALARM_EVENT_CHG,					//Alarm event change.
	PWRFREQ_EVENT_CHG,	
	STREAMTYPE_EVENT_CHG,				//Stream type change.
	SUBSTREAMTYPE_EVENT_CHG,			//Sub stream type event change.
	SUBSTREAMPARAM_EVENT_CHG,			//Sub stream param event change.
	NETSTATE_CONNECTERROR_EVENT_CHG,	//Net state or connect error event change.
	NETSTATE_RECONNECTRESULT,              //Net reconnect success;
	PC_AUDIO_ALARM_EVENT_CHG,			// PC audio alarm evnet change

	RECORD_ACHIEVE_FILE_MAXSIZE = 0x0100,		//
	RECORD_NO_ENOUGE_SPACE,			//
	RECORD_RESOLUTION_CHANGE,			//
	RECORD_FILE_PATH_NOEXIST,			//
	RECORD_UNKNOW,					//

	//music -- fosbaby
	MUSIC_STATE_CHG = 0x0200,
	MUSIC_FORMAT_ERR,
	MUSIC_PLAY_MODE_CHG,
	MUSIC_DORMANT_TIME_CHG,
	MUSIC_PATH_CHG,
	MUSIC_LISTS_CHG,

	AUDIO_VOLUME_CHG = 0x0300,
	CGI_ONLINE_UPGRADE_STATE,
	TEMPERATURE_CHG, 
	FTP_STATE_CHG,
	CLOUD_STATE_CHG,
	MOTION_DETECT_ENABLE_STATE_CHG,
	SDCARD_IS_FULL,
	HUMIDITY_CHG,
	TEMPERATURE_DEV_STATE_CHG,
	HUMIDITY_DEV_STATE_CHG,
	OSD_CONFIG,
	GET_ALL_PRODUCT_INFO,
	VIDEO_EPT_STATE_CHG,
	ALL_EVENT_QUIT,					//quit.
	START_PLAY_RESULT,
	IMPORT_CFG_RESULT,

	INIT_INFO_FIN = 0x0400,
	HDR_CHANGE = 0x0500,
	WDR_CHANGE,	  
	NAA_PARAM_CHANGE,
}EVENT_MSG;							//msg.

typedef struct
{
	unsigned int	id;					//id.
	int				len;				//size of data.
	char			data[1024];			//data.
}FOSEVET_DATA;						//the data of event.

//CGI Return

typedef struct UsrList					//save camera user list.
{
	unsigned int usrCnt;			    //The number of users.
	char usrName[USRCOUNT][NAMESIZE];	//user name.
	int privilege[USRCOUNT];           //user privilege.
}FOS_USERLIST;

typedef struct SessionList              //save camera sessionList.
{
	unsigned int usrCnt;                //The number of users.
	char usrName[USRCOUNT][NAMESIZE];     //user name.
	char sessionIp[USRCOUNT][NAMESIZE];   //session ip.
}FOS_SESSIONLIST;

typedef struct LogInResult                //save login result information.
{                                         
	int logInResult;                    //login result.
	int privilege;                      //user privilege.

}FOS_LOGINRESULT;

typedef struct DevSystemTime				//save device System time.
{
	int timeSource;                       // 0-Get time from NTP server    1-Set time manually.
	char ntpServer[FOS_NTPSERVER_LEN];      // ntp server addr Support ntp server:time.nist.gov   time.kriss.re.kr   time.windows.com   time.nuri.net .
	int dateFormat;                      // 0 YYYY-MM-DD    1	DD/MM/YYYY     2 MM/DD/YYYY.
	int timeFormat;                      // 0 - 12 hours        1- 24 hours.
	int timeZone;                        // The seconds between local time and GMT time.
	int isDst;                          // Daylight saving time (0-disable,1-enable).
	int dst;                            // Not in use currently.
	int year;
	int mon;
	int day;
	int hour;
	int minute;
	int sec;
}FOS_DEVSYSTEMTIME;

typedef struct DevState                   //save device state.
{
	int IOAlarm;                        //0-Disabled    1-No alarm     2-Detect alarm.
	int motionDetectAlarm;               //0-Disabled    1-No alarm.
	int soundAlarm;                     //0-Disabled    1-No alarm     2-Detect alarm.
	int record;                        //0-Not in recording   1-Recording.
	int sdState;                       //0-No sd card   1-Sd card ok   2-Sd card read only.
	char sdFreeSpace[COMMSIZE];          //Free space of sd card by unit of k.
	char sdTotalSpace[COMMSIZE];         //Total space of sd card by unit of k.
	int ntpState;                      //0-Disabled   1-Update success   2-Update fail.
	int ddnsState;                     //0-Disabled   1-Update success   2-Update fail.
	char url[FOS_URL_LEN];              //DDNS url.
	int upnpState;                     //0-Disabled   1-Update success   2-Update fail.
	int isWiiConnected;                 //0-No wifi connected    1-Connected.
	char wifiConnectedAP[COMMSIZE];      //The ssid of the ap which has been connected.
	int infraLedState;                 //0-OFF   1-ON.
}FOS_DEVSTATE;

typedef struct DevInfo                 //save device information.
{
	char productName[NAMESIZE];        //Camera model.
	char serialNo[COMMSIZE];           //Serial no.
	char devName[COMMSIZE];            //Camera name.
	char mac[COMMSIZE];                //Mac address.
	int year;
	int mon;
	int day;
	int hour;
	int min;
	int sec;
	int timeZone;                     //Time zone.
	char firmwareVer[COMMSIZE];         //Firmware version.
	char hardwareVer[COMMSIZE];         //Hardware version.
}FOS_DEVINFO;

typedef struct ProductAllInfo            // save camera Information.
{
	int model;                        // Model number.
	char modelName[NAMESIZE];           // Model Name.
	int language;                      // Main language.
	int sensorType;                    // Sensor type number.
	int wifiType;                      // Wifi Type Number.
	int reserve[4];                    // reserve.
	int sdFlag;                        // Whether machine support sd card.
	int outdoorFlag;                   // Whether machine is outdoor.
	int ptFlag;                        // Whether machine support pt.
	int zoomFlag;                      // Whether machine support zoom.
	int rs485Flag;                     // Whether machine support rs485.
	int ioAlarmFlag;                   // Whether machine support io alarm.
	int onvifFlag;                     // Whether machine support onvif.
	int p2pFlag;                       // Whether machine support p2p.
	int wpsFlag;                       // Whether machine support wps.
	int audioFlag;                     // Whether machine support audio-speak.
	int talkFlag;                      // Whether machine support audio-talk.
	int reserveFlag[4];                 // reserve.
	char appVer[COMMSIZE];              // Camera application version.
	int isEnableCloudStorage;
	int isEnableBaiDuCloudPush;
	int isEnableFoscamCloudPush;
	int isEnableOutFrameworkDetect;
	int isEnableAudioDetect;
	int isEnableTemperatureDetect;
	int isEnableHumidityDetect;
	int isEnablePIRDetect;
	int isEnableMusic;
	int isEnableEncryptionChip;
	int isEnableSoftAp;
	int isEnableEZLink;
	int isEnablePPPoE;
	int isEnableCameraDistortion;
	int isEnableRecord;
	int isEnableTimingReset;
	int isEnableWithdrawDefence;
	int isEnableLedOnOff;
	int isEnableNightLight;
}FOS_PRODUCTALLINFO; 

typedef struct GeneratePubKey            // save public key information.
{
	int genResult;                     // The result that camera generate public key for software reset.
	int genPubLen;                     // The length of public key.
	char pubKey[FOS_PUBKEY_LEN];         // Public key.
}FOS_GENERATEPUBKEY;

typedef struct StreamInfo
{
	int sensorType;				
	int model;
}FOS_STREAMINFO;

typedef struct TempratureAlarmConfig        //save temperature alarm config.
{
	int isEnable;                        // 0-disable    1-enable.
	int linkage;                         // Motion alarm linkage.
	                                    // ( bit7| bit3 | bit2 | bit1 | bit0 )	bit0:Ring   bit1:Send mail  bit2:Snap picture  bit3:Record   bit7:Push to phone.
	int topLimit;                        // Top temperature.
	int lowerLimit;                      // Lower temperature.
	int snapInterval;                    // Interval for snap picture.
	int triggerInterval;                 // Interval for trigger alarm again.
	long long schedule[FOSBABY_SCHEDULE_COUNT];  // N(0-6),alarm schedule.
}FOS_TEMPRATUREALARMCONFIG;

typedef struct HumidityAlarmConfig
{
	int isEnable;                         // 0-disable    1-enable.
	int linkage;                          // Motion alarm linkage.
									    // ( bit7| bit3 | bit2 | bit1 | bit0 ) bit0:Ring   bit1:Send mail  bit2:Snap picture  bit3:Record   bit7:Push to phone.
	int topLimit;                        // Top humidity.
	int lowerLimit;                      // Lower humidity.
	int snapInterval;                    // Interval for snap picture.
	int triggerInterval;                 // Interval for trigger alarm again.
	long long schedule[FOSBABY_SCHEDULE_COUNT];  // N(0-6), alarm schedule.
}FOS_HUMIDITYALARMCONFIG;

typedef struct OneKeyAlarmConfig
{
	int isEnable;
	int alarmLinkage;//0,1,2,3,4
}FOS_ONEKEYALARMCONFIG;

typedef struct TimingRebootConfig
{
	int isEnable;
	int intervalDay;//7或30
}FOS_TIMINGREBOOTCONFIG;

typedef struct MultiDevice
{
	int chnnl;
	FOS_PRODUCTTYPE productType;
	char ip[IPADDR_LEN];
	int port;
	int mediaPort;
	char username[USERNAME_LEN];
	char passwd[PASSWORD_LEN];
	char devName[DEV_LEN];//device name
}FOS_MULTIDEVICE;

typedef struct DeviceList
{
	char devName[DEVLIST_SIZE][DEV_LEN];//devices name
}FOS_DEVICELIST;

typedef struct LogInfo
{
	int offset;
	int count;
}FOS_LOGINFO;

typedef struct GetLogInfo
{
	int totalCnt;
	int curCnt;
	char logContents[LOG_CNT][LOG_LEN];
}FOS_GETLOGINFO;

typedef struct MusicList
{
	char musicListName[MUSICLISTNAME_LEN];//music list name
	int musicCnt;  //total number of music
	int hadGet;	 // the number of music 
	char musicName[MAX_MUSIC_COUNT][MUSICNAME_LEN];//musics name
}FOS_MUSICLIST;

typedef struct MusicInfo
{
	char musicListName[MUSICLISTNAME_LEN];//music list name
	int startNo;     // must fill in, 0: the first music file
	int musicNum;	//the number of music to be acquired, must fill in, web:50
}FOS_MUSICINFO;

typedef struct MusicListNameList
{
	int ListCount;// list count
	char musicListName[MAX_MUSIC_COUNT][MUSICLISTNAME_LEN];//music lists name
}FOS_MUSICLISTNAMELIST;

typedef struct CurListInfo
{
	int setResult;
	int listCount;
	char curListname[MUSICLISTNAME_LEN];//current playing list name
	char musicListNames[MAX_MUSIC_COUNT][MUSICLISTNAME_LEN];//music lists name
}FOS_CURLISTINFO;

typedef struct MusicPlayStart
{
	int musicTotal;
	int mode;//music playing mode (order recycle)
	int index;
	int isPlaying;
	char listName[MUSICLISTNAME_LEN];
}FOS_MUSICPLAYSTARTINFO;

typedef struct CloudConfig
{
	int isEnable;
	char statusMsg[STATUSMSG_LEN];
	FOS_CLOUDSERVER cloudServer;
	char authAddr[AUTHADDR_LEN];
	char authorizationCode[AUTHORIZATIONCODE_LEN];//authorization code
	char accessToken[ACCESSTOKEN_LEN];
	int quota;
	int userd;
}FOS_CLOUDCONFIG;

typedef struct CloudServerInfo
{
	int isEnable;
	FOS_CLOUDSERVER cloudServer;
}FOS_CLOUDSERVERINFO;

typedef struct PushConfig
{
	int isEnable;
	FOS_PUSHSERVER pushServer;
	int statusMsg;
}FOS_PUSHCONFIG;

typedef struct PushOperateInfo
{
	int cmd_oper;//code of operation
	int device_type;
	int channel_id;
	int user_id;
}FOS_PUSHOPERATEINFO;
 
typedef struct ScheduleInfraLedConfig			//save scheduleInfraLedConfig    Note N:[0-2],the number of infra led switch schedule.
{
	int startHour[FOS_LED_SCHEDULE_COUNT];   
	int startMin[FOS_LED_SCHEDULE_COUNT];
	int endHour[FOS_LED_SCHEDULE_COUNT];
	int endMin[FOS_LED_SCHEDULE_COUNT];
}FOS_SCHEDULEINFRALEDCONFIG;

typedef struct
{
	int result;  // 0: success 1: not exist  2: paramerror 3: set by reboot preset point 4: was add to cruise map
	int pointCnt;
	char pointName[FOS_MAX_PRESETPOINT_COUNT][FOS_MAX_PRESETPOINT_NAME_LEN];
}FOS_RESETPOINTLIST;							//preset point list.

typedef struct 
{
	int cruiseMapCnt;
	char cruiseMapName[FOS_MAX_CURISEMAP_COUNT][FOS_MAX_CURISEMAP_NAME_LEN];
}FOS_CRUISEMAPLIST;							//cruise map list.

typedef struct FosCruiseMapInfo
{
	char cruiseMapName[FOS_MAX_CURISEMAP_NAME_LEN];
	char pointName[FOS_MAX_PRESETPOINT_COUNT_OF_MAP][FOS_MAX_CURISEMAP_NAME_LEN];
	int getResutl;
}FOS_CRUISEMAPINFO;							//cruise map info.

typedef struct FosCruisePrePointLingerTime
{
	char cruiseMapName[FOS_MAX_CURISEMAP_NAME_LEN];
	int time[FOS_MAX_PRESETPOINT_COUNT_OF_MAP];
}FOS_CRUISEMAPPREPOINTLINGERTIME;				//cruise preset point linger time.

typedef struct CruiseTimeCustomed 
{
	unsigned int time;
	int customed;
}FOS_CRUISETIMECUSTOMED;						//cruise time customed.

typedef struct _485Info
{
	int rs485Protocol;
	int rs485Addr;
	int rs485Baud;
	int rs485DataBit;
	int rs485StopBit;
	int rs485Check;
}FOS_485INFO;									//485infomation.

typedef struct VideoStreamParam
{
	int streamType;
	int resolution;
	int bitRate;
	int frameRate;
	int GOP;
	int isVBR;
}FOS_VIDEOSTREAMPARAM;							//video stream param.

typedef struct VideoStreamListParam
{
	int streamType[FOS_MAX_VIDEOSTREAM_TYPE];
	int resolution[FOS_MAX_VIDEOSTREAM_TYPE];
	int bitRate[FOS_MAX_VIDEOSTREAM_TYPE];
	int frameRate[FOS_MAX_VIDEOSTREAM_TYPE];
	int GOP[FOS_MAX_VIDEOSTREAM_TYPE];
	int isVBR[FOS_MAX_VIDEOSTREAM_TYPE];
}FOS_VIDEOSTREAMLISTPARAM;						//video stream list param.

typedef struct OSDSetting
{
	int isEnableTimeStamp;
	int isEnableDevName;
	int dispPos;
	int isEnableOSDMask;
	int isEnableTempAndHumid;
}FOS_OSDSETTING;								//osd setting.

typedef struct OsdMaskArea
{
	int x1[FOS_MAX_OSDMASKAREA_COUNT];			//The top left X position of mask N.
	int y1[FOS_MAX_OSDMASKAREA_COUNT];			//The top left Y position of mask N.
	int x2[FOS_MAX_OSDMASKAREA_COUNT];			//The bottom right X position of mask N.
	int y2[FOS_MAX_OSDMASKAREA_COUNT];			//The bottom right Y position of mask N.
}FOS_OSDMASKAREA;

typedef struct MotionDetectConfig
{
	int isEnable;
	int isMovAlarmEnable; 
	int isPirAlarmEnable;
	int linkage;
	int snapInterval;
	int sensitivity;
	int triggerInterval;
	long long schedules[FOS_MAX_SCHEDULE_COUNT];
	int areas[FOS_MAX_AREA_COUNT];
}FOS_MOTIONDETECTCONFIG;										//motion detect config.

//anba
#define ANBAMOTIONCOUNT 3
typedef struct MotionDetectConfig1
{
	int isEnable;
	int linkage;
	int snapInterval;
	int triggerInterval;
	int isMovAlarmEnable;
	int isPirAlarmEnable;
	long long schedules[FOS_MAX_SCHEDULE_COUNT];
	int x[ANBAMOTIONCOUNT];
	int y[ANBAMOTIONCOUNT];
	int width[ANBAMOTIONCOUNT];
	int height[ANBAMOTIONCOUNT];
	int sensitivity[ANBAMOTIONCOUNT];
	int valid[ANBAMOTIONCOUNT];
}FOS_MOTIONDETECTCONFIG1;										//motion detect config.

typedef struct LocalAlarmRecordConfig
{
	int isEnableLocalAlarmRecord;
	int localAlarmRecordSecs;									//local alarm record seconds.
	
}FOS_LOCALALARMRECORDCONFIG;									//local alarm record config.

typedef struct AlarmRecordConfig
{
	int isEnablePreRecord;
	unsigned int preRecordSecs;
	unsigned int alarmRecordSecs;
	
}FOS_ALARMRECORDCONFIG;										//alarm record config.

typedef struct RecordFtpStateMsg
{
	unsigned char error;
} FOS_RECORDFTPSTATE;

typedef struct CloudStateMsg
{
	unsigned char error;	// 1:have full£¬2: remainSpace less than 200M£¬5£ºremainSpace less than 500M
}FOS_CLOUDSTATEMSG;

typedef struct SdCardNotEnoughAlarmcfg
{
	int sdCardFreeSpace;  //  1:128M; 2:256M; 3:384M, 5:512M
}FOS_SDCARDFULLINFO;

typedef struct HumidityMsg
{
	int curHumidity;
}FOS_HUNIDITYINFO;

typedef struct TemperatureDevStateMsg
{
	int devState;
}FOS_TemperatureDevStateInfo;

typedef struct HumidityDevStateMsg
{
	int devState;
}FOS_HumidityDevStateInfo;

typedef struct RecordPath
{
	int setResult;											//set时有效，get时无效
	int path;												//0-SD card，2-FTP server.
	int freeCapacity;											//The free capacity of storage device.
	int totalCapacity;											//The total capacity of storage device.
}FOS_RECORDPATH;

typedef struct ScheduleRecordConfig
{
	int isEnable;
	int recordLevel;
	int spaceFullMode;
	int isEnableAudio;
	long long schedules[FOS_MAX_SCHEDULE_COUNT];
	
}FOS_SCHEDULERECORDCONFIG;										//schedule record config.

typedef struct SnapConfig
{
	int snapPicQuality;										//snap picture quality.
	int saveLocation;
}FOS_SNAPCONFIG;												//snap config.

typedef struct ScheduleSnapConfig
{
	int isEnable;
	int snapInterval;
	long long schedule[FOS_MAX_SCHEDULE_COUNT];
	
}FOS_SCHEDULESNAPCONFIG;										//schedule snap config.

typedef struct SearchRecordPara
{
	char recordPath[MAX_PATH];
	unsigned int startTime;
	unsigned int endTime;
	int recordType;
	int startNo;
	
}FOS_SEARCHRECORDPARA;											//search record param.

typedef struct RecordList
{
	int totalCnt;												//total count.
	int curCnt;												//current count.
	char recordInfo[FOS_MAX_RECORD_COUNT][FOS_MAX_RECORDINFO_LEN];
}FOS_RECORDLIST;												//record list.

typedef struct IOAlarmConfig
{
	int isEnable;
	int linkage;
	int alarmLevel;
	int snapInterval;
	int triggerInterval;
	long long schedules[FOS_MAX_SCHEDULE_COUNT];
}FOS_IOALARMCONFIG;							//IO alarm config.


typedef enum
{
	FOSPTZSELFTESTMODE_NO_SELFTEST,
	FOSPTZSELFTESTMODE_NORMAL_SELFTEST,
	FOSPTZSELFTESTMODE_GO_PREPOINT
}FOS_PTZSELFTESTMODE;							//ptz self test mode.



typedef enum
{
	CRUISECTRLMODE_TIME,
	CRUISECTRLMODE_LOOPCOUNT
}FOS_CRUISECTRLMODE;							//cruise control mode.

typedef enum
{
	STREAMFORMAT_H264,
	STREAMFORMAT_MJPEG
}FOS_STREAMFORMAT;								//stream format.

//NetWord CGI Struct

typedef struct PortInfo						//IPC Port Info.
{
	unsigned int webPort;						//Web Port.
	unsigned int httpsPort;					//Https Port.
	unsigned int mediaPort;					//Media Port.
	unsigned int onvifPort;					//Onvif Port.
	unsigned int rtspPort;					//rtsp Port.
}FOS_PORTINFO;

typedef struct IpInfo							//IPC IP Info.
{
	int isDHCP;								//Obtain ip from DHCP server or not.
	char ip[IPADDR_LEN];						//ip address(Can only support ipv4 yet).
	char gate[GATE_LEN];						//gateway("0.0.0.0" when use DHCP).
	char mask[MASK_LEN];						//subnet mask.
	char dns1[DNS_LEN];						//The first dns server addr("0.0.0.0" when use DHCP).
	char dns2[DNS_LEN];						//The second dns server addr("0.0.0.0" when use DHCP).
}FOS_IPINFO;


typedef struct WifiSetting						//Use to set wifi config.
{
	int isEnable;								//Enable state.
	int isUseWifi;							//Use wifi or not.
	char ssid[SSID_LEN];						//AP name
	int netType;								//Network type.
	int encryptType;							//Encrypt type.
	char psk[PSK_LEN];							//The psk of WPA WPA2.
	int authMode;
	int keyFormat;							//Key format,is ASIC or Hex.
	int defaultKey;
	char key1[KEY_LEN];
	char key2[KEY_LEN];
	char key3[KEY_LEN];
	char key4[KEY_LEN];
	int key1Len;
	int key2Len;
	int key3Len;
	int key4Len;
}FOS_WIFISETTING;

typedef struct UPnPConfig						//UPnP Config.
{
	int isEnable;								//Is Enable UpnP function.
}FOS_UPNPCONFIG;

typedef struct WifiConfig						//Wifi Config.
{
	int isEnable;								//Enable state.
	int isUseWifi;							//Use wifi or not.
	int isConnected;							//Connected state.
	char connectedAP[CONNECTEDAP_LEN];			//Connected ap.
	char ssid[SSID_LEN];						//AP name.
	int encryptType;							//Encrypt type.
	char psk[PSK_LEN];							//The psk of WPA WPA2.
	int authMode;
	int keyFormat;							//Key format,is ASIC or Hex.
	int defaultKey;
	char key1[KEY_LEN];
	char key2[KEY_LEN];
	char key3[KEY_LEN];
	char key4[KEY_LEN];
	int key1Len;
	int key2Len;
	int key3Len;
	int key4Len;
}FOS_WIFICONFIG;

typedef struct DDNSConfig						//DDNS Config.
{
	int isEnable;								//Is Enable DDNS update.
	char hostName[HOSTNAME_LEN];				//DDNS domain.
	int ddnsServer;							//The server of ddns.
	char user[USER_LEN];
	char password[PASSWORD_LEN];
	char factoryDDNS[FACTORYDDNS_LEN];			//Factory ddns.

}FOS_DDNSCONFIG;

typedef struct FtpConfig						//Ftp Config.
{
	char ftpAddr[FTPADDR_LEN];					//FTP server address, you can contain sub directory in it.
	unsigned int ftpPort;
	int mode;								//Mode,PASV or PORT.
	char userName[USERNAME_LEN];
	char password[PASSWORD_LEN];

}FOS_FTPCONFIG;

typedef struct TestFtpServer					//Save ftp server test result.
{
	int testResult;							//Test result,is Success or Fail.

}FOS_TESTFTPSERVER;

typedef struct SMTPConfig						//Smtp Config.
{
	int isEnable;								//Is enable camera send mail?
	char server[128];					//SMTP server address.
	int port;								//Smtp port.
	int isNeedAuth;							//Need auth user account or not.
	int tls;									//Set tls,is None or TLS or STARTTLS.
	char user[64];
	char password[64];
	char sender[128];
	char reciever[256];				//The main use to reciever,Use "," between 2 senders,for exapler:aaa@123.com,bbb@456.com.
}FOS_SMTPCONFIG;

typedef struct SmtpTest						//Save smtp test result.
{
	int testResult;							//Test result,is Success or Fail.
}FOS_SMTPTEST;

typedef struct P2PEnable						//p2p status.
{
	int enable;
}FOS_P2PENABLE;

typedef struct P2PPort							//p2p port.
{
	int port;
}FOS_P2PPORT;

typedef struct P2PInfo							//p2p info.
{
	char uid[UID_LEN];							//p2p uid.
}FOS_P2PINFO;

typedef struct PPPoEConfig						//pppoe config.
{
	int isEnable;								//Is Enable PPPoE function.
	char userName[USERNAME_LEN];
	char password[PASSWORD_LEN];

}FOS_PPPOECONFIG;

typedef struct WifiMode						//Wifi Mode.
{
	int wifiMode;								//Wifi mode,is sta or softAp.
}FOS_WIFIMODE;

typedef struct SoftApConfig						//SoftAp Config.
{
	char ssid[SSID_LEN];						//SoftAp's ssid.
	int authMode;
	int encryptType;
	char psk[PASSWORDKEY_LEN];					//Password key.
}FOS_SOFTAPCONFIG;

typedef struct ChangeNetMode					//Change Net Mode.
{
	int netModeChange;							//Net mode change,is "Sta to softAp" or "softAp to sta".
}FOS_CHANGENETMODE;


typedef struct BaiduRtmpConfig						 
{
	int isEnable;                               //used by RTMP_TYPE

	int iProperty;                              // for record
	int isEnableAudio;
	int isMainStream;
	char szStreamId[STREAMID_LEN];
	char szPublishToken[PUBLISHTOKEN_LEN];
	char szGuid[GUID_LEN];
	char szDevId[DEVID_LEN];
	char szAccessToken[ACCESSTOKEN_LEN];
	char szRefreshToken[REFRESHTOKEN_LEN];
}FOS_BAIDURTMPCONFIG;


typedef struct WifiList						//Wifi List.
{
	int totalCnt;								//Total count of aps.
	int curCnt;								//Current aps count.
	char ap[AP_NUM][AP_LEN];
	// about ap: exp: TP-LINK-ssid+9C:21:6A:AA:BD:76+100+1+4 , 为一下结构体使用 '+" 字符连接而成 
	/*
		typedef struct tagWifiAPInfo 
		{ 
			char ssid[64]; 
			char mac[18]; 
			char quality; // 0 ~ 100 
			char encryption; // 0=OFF 1=ON 
			char encrypType; // WIFI_ENCRYPTED_TYPE 0=None 1=WEP 2=WPA 3=WPA2 4=WPA/WPA2
		} WifiAPInfo; 
	*/
}FOS_WIFILIST;

typedef struct tagUserInfo2 
{ 
	char			ddns[128];
	char			url[128]; 
	char			ip[128];
	char			uid[128]; 
	char			usr[64]; 
	char			pwd[64]; 
	unsigned short	webPort; 
	unsigned short	mediaPort;
	unsigned short	ipWebPort;
	unsigned short	ipMediaPort;
	unsigned short	ddnsWebPort;
	unsigned short	ddnsMediaPort;
	char			macAdd[16];
	FOSIPC_CONNECTTION_TYPE   connectType; 
}FOS_UserInfo, *FOS_PUserInfo;



#define  BITRATE_6M				6291456
#define  BITRATE_4M				4194304
#define  BITRATE_2M				2097152
#define  BITRATE_1M				1048576
#define  BITRATE_512K			524288
#define  BITRATE_256K			262144
#define  BITRATE_200K			204800
#define  BITRATE_128K			131072
#define  BITRATE_100K			102400
#define  BITRATE_50K			51200
#define  BITRATE_20K			20480

#define  FRAMERATE_1_30			30
#define  FRAMERATE_1_23			23
#define  FRAMERATE_1_25			25
#define  FRAMERATE_1_15			15
#define  FRAMERATE_1_10			10
#define  FRAMERATE_1_11 		11
#define  FRAMERATE_1_20			20
#define  FRAMERATE_1_19			19

typedef enum{
	RESOLUTION_NONE = -1,
	RESOLUTION_1080P = 7,
	RESOLUTION_960P = 6,
	RESOLUTION_720P = 0,
	RESOLUTION_VGA640_480 = 1,
	RESOLUTION_VGA640_360 = 3,
	RESOLUTION_QVGA320_240 = 2,
	RESOLUTION_QVGA320_180 = 4,
	RESOLUTION_QCIF176_144 = 5 ,
	RESOLUTION_3M = 8 ,
	RESOLUTION_QHD2560_1440 = 9 ,
}FOS_MODESTREAMINFO;

typedef struct tagStreamParamInfo // Default value:-1
{
	char		name[64];
	FOS_MODESTREAMINFO         streamType;
	int						   bitRate;
	int                        frameRate;
}FOS_STREAMPARAMINFO, *FOS_PSTREAMPARAMINFO;

typedef struct tagStreamFrameInfo // Default value:-1
{ 
	FOS_STREAMPARAMINFO	mainStream[10];
	FOS_STREAMPARAMINFO subStream[10];
    
}FOS_STREAMFRAMEPARAMINFO, *FOS_PSTREAMFRAMEPARAMINFO;

 
typedef struct tagFirmwareOnlineUpgradeState
{
	int state;		//		0/1/2   normal/upgrading/fail
	int progress;	//		[0,100]
	int error;		//		0/1/2/255  normal/net error /failed /internal error
}FOS_UpgradeState, *FOS_PUpgradeState;


#ifndef _WIN32
#define ATTRIBUTE_PACKEDNEW __attribute__((packed))
#else
#define ATTRIBUTE_PACKEDNEW
#pragma pack(push)
#pragma pack(1)
#endif

typedef struct tagMergeSnapInfo 
{ 
	char filename[COMMSIZE]; 
	long long datid; 
	long filepos; 
	int filepath; 
	unsigned int picnum;   
	unsigned int dataLen;     
	char data[0];
}ATTRIBUTE_PACKEDNEW FOS_SNAPPARAMINFO;

typedef struct tagNewSnapParamInfo
{
	long long snapPicId;
	int snapPicIdxOfArray;
	int snapPicNum; 
	int dataLen;
	char reserved[32];
	char data[0];
} ATTRIBUTE_PACKEDNEW FOS_NEWSNAPPARAMINFO;

typedef struct tagSnapPicInfo 
{ 
	char picname[COMMSIZE]; 
	unsigned int dataLen;     
	char data[0]; 
}ATTRIBUTE_PACKEDNEW FOS_SNAPPICINFO;//

typedef struct tagNewSnapPicInfo
{
	char snapPicName[64];  // 图片名称
	int snapPicSize;   // 图片大小
	char reserved[32];   // 保留字段
	char data[0];
}ATTRIBUTE_PACKEDNEW FOS_NEWSNAPPICINFO;

typedef struct tagGetSnapFileMsg 
{ 
	char filename[64]; //snap file name 
	int  filepath;  // 1 = SD 
	long fileid; //snap file ID 
	long filepos;//SD snap file  pointer
	char reserve[28]; 
}ATTRIBUTE_PACKEDNEW FOS_GetSnapFileMsg; 

typedef struct tagGetSnapFileNewMsg 
{ 
	char userName[64];
	char password[64];
	long long snapPicId;
	int snapPicIdxOfArray;
	char reserved[32];
}ATTRIBUTE_PACKEDNEW FOS_GetSnapFileNewMsg; 

#ifdef _WIN32
#pragma pack(pop)
#endif

typedef struct tagPlaybackInfo
{
	unsigned long long	videoTotalduration;
	unsigned int		videoFrameNum;
	unsigned long long	audioTotalduration;
	unsigned int		audioFrameNum;
}FOS_PlaybackInfo;

typedef struct tagAudioAlarmSetting 
{ 
	int isEnableAudioAlarm; 
	int audioAlarmSensitivity; 
	long long schedule[FOSBABY_SCHEDULE_COUNT]; 
	int linkage; // RECORD | SNAP | MAIL | RING 
	int triggerInterval; // seconds 
	int snapInterval;    // seconds 
} FOS_AudioAlarmSetting;

typedef struct tagAllProductInfoMsg
{
	int model;
	char modelName[33];
	int productAllVersion; 
	int ambarellaFlag;   // bit[0]-hdr, bit[1]-wdr, bit[2]-ept
} ATTRIBUTE_PACKED FOS_AllProductInfoMSG;

typedef struct tagVideoEPTValue
{
	int value;
} ATTRIBUTE_PACKED FOS_VideoEPTValue;

typedef struct tagAutoAdjust 
{ 
	int AutoAdjustEnable; 
} ATTRIBUTE_PACKED FOS_AutoAdjust;



#endif
