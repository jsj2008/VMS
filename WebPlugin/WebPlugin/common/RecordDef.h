#pragma once
#ifndef RECORD_DEF
#define RECORD_DEF
/////////////////////////////// Record File Struct  Start ///////////////////////////////
#define		RECORD_FILE_VERSION		0x00010000

#define		RECORD_TYPE_PLAN		0
#define		RECORD_TYPE_MANUAL		1
#define		RECORD_TYPE_MOTION		2
#define		RECORD_TYPE_ALARM		3

#define		RECORD_DIRECTORY_NAME	"VMS_Record"

#ifdef __APPLE__
#define DWORD       unsigned int
#define MAX_PATH    4096
#endif
#pragma pack(1)
typedef struct _RECORD_FILE_HEAD_INFO
{
	int							Ver;
	int							Len;
	char						RecordType; // 录像类型 0: plan 1:Manual
	char						EncodeType;
	int							ChannelID;
	double						StartTime;
	double						EndTime;
	double						fps;
	DWORD						SamplesPerSec; //  波特率
	DWORD						BitsPerSample; // 采样精度
	DWORD						Channel; // 音频通道数
	DWORD						UnUse1;
	DWORD						UnUse2;
	DWORD						UnUse3;
	DWORD						UnUse4;
	char						IP[20];
	char						ChannelName[200];

	_RECORD_FILE_HEAD_INFO()
	{
		Ver = RECORD_FILE_VERSION;
		RecordType = RECORD_TYPE_PLAN;
		EncodeType = 0;
		ChannelID = 0;
		StartTime = 0.0;
		EndTime = 0.0;
		fps = 0.0;
		SamplesPerSec = 0;
		BitsPerSample = 0;
		Channel = 0;
		UnUse1 = 0;
		UnUse2 = 0;
		UnUse3 = 0;
		UnUse4 = 0;
		IP[0] = 0;
		ChannelName[0] = 0;
	}

}RECORD_FILE_HEAD_INFO, *PRECORD_FILE_HEAD_INFO;

typedef struct _RECORD_FILE_INDEX_DATA
{

	DWORD		TimeOffset;	// 毫秒
	DWORD		FileOffset;

	_RECORD_FILE_INDEX_DATA()
	{
		TimeOffset = 0;
		FileOffset = 0;
	}

}RECORD_FILE_INDEX_DATA, *PRECORD_FILE_INDEX_DATA;

#define		RECORD_FILE_INDEX_LEN		60*60

typedef struct _RECORD_FILE_INDEX_INFO
{

	int							Size;
	int							Count;
	RECORD_FILE_INDEX_DATA		Index[RECORD_FILE_INDEX_LEN];

	_RECORD_FILE_INDEX_INFO()
	{
		Count = 0;
		Size = RECORD_FILE_INDEX_LEN;
	}

}RECORD_FILE_INDEX_INFO, *PRECORD_FILE_INDEX_INFO;

#define		DATA_TYPE_AUDIO	0
#define		DATA_TYPE_VIDEO	1

typedef struct _RECORD_FILE_DATA_INFO
{
	char						Type; // audio 0 video 1
	DWORD						TimeStamp;
	int							Len; // data len
	//char*						Data;

	_RECORD_FILE_DATA_INFO()
	{
		Type = DATA_TYPE_VIDEO;
		Len = 0;
		TimeStamp = 0;
	}

}RECORD_FILE_DATA_INFO, *PRECORD_FILE_DATA_INFO;



typedef struct _RECORD_DISK_FILE_INFO
{
	int		Type; // 1:按时间打包 2:按文件大小打包 3:按时间及文件大小打包
	int		Time; // 时间 单位分钟 5 10 15 30 60 最大60
	int		Size; // 文件大小 单位M	100 200 300 500 1000 最大1000

	_RECORD_DISK_FILE_INFO()
	{
		Type = 1;
		Time = 5;
		Size = 200;
	}

}RECORD_DISK_FILE_INFO, *PRECORD_DISK_FILE_INFO;

typedef struct _RECORD_DISK_DATA
{

	char	DiskName;	// 盘符 c d e……
	char	Path[MAX_PATH];		// 路径 "c:\\VMS_RECORD\\"
	int		SwitchValue; // 磁盘切换值 单位:M
	int		WarningValue; // 磁盘警戒值 单位:M
	int		FreeValue;	// 磁盘可用空间 单位:M

	_RECORD_DISK_DATA()
	{
		DiskName = 'c';
		Path[0] = 0; // 
		SwitchValue = 3000;
		WarningValue = 6000;
		FreeValue = 0;
	}

}RECORD_DISK_DATA, *PRECORD_DISK_DATA;

typedef struct _RECORD_DISK_INFO
{

	char				CurrentDiskName; // 当前录像盘符
	int					Count;
	RECORD_DISK_DATA	DiskData[26];

	_RECORD_DISK_INFO()
	{
		CurrentDiskName = 'c';
		Count = 0;
	}

}RECORD_DISK_INFO, *PRECORD_DISK_INFO;

#pragma pack()
/////////////////////////////// Record File Struct  End	  ///////////////////////////////
#endif
