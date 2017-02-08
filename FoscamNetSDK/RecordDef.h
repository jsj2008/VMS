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

#pragma     pack(push)
#pragma     pack(1)
//typedef struct _RECORD_FILE_HEAD_INFO
//{
//	int							Ver;
//	int							Len;
//	char						RecordType; // 录像类型：0-plan 1-manual
//	char						EncodeType;
//	int							ChannelID;
//	double						StartTime;
//	double						EndTime;
//	double						fps;
//	unsigned int                SamplesPerSec; //  波特率
//	unsigned int				BitsPerSample; // 采样精度
//	unsigned int				Channel; // 音频通道数
//	unsigned int				UnUse1;
//	unsigned int				UnUse2;
//	unsigned int				UnUse3;
//	unsigned int				UnUse4;
//	char						IP[20];
//	char						ChannelName[200];
//
////	_RECORD_FILE_HEAD_INFO()
////	{
////		Ver = RECORD_FILE_VERSION;
////		RecordType = RECORD_TYPE_PLAN;
////		EncodeType = 0;
////		ChannelID = 0;
////		StartTime = 0.0;
////		EndTime = 0.0;
////		fps = 0.0;
////		SamplesPerSec = 0;
////		BitsPerSample = 0;
////		Channel = 0;
////		UnUse1 = 0;
////		UnUse2 = 0;
////		UnUse3 = 0;
////		UnUse4 = 0;
////		IP[0] = 0;
////		ChannelName[0] = 0;
////	}
//
//}RECORD_FILE_HEAD_INFO, *PRECORD_FILE_HEAD_INFO;

struct _RECORD_FILE_HEAD_INFO
{
    int							Ver;
    int							Len;
    char						RecordType; // 录像类型：0-plan 1-manual
    char						EncodeType;
    int							ChannelID;
    double						StartTime;
    double						EndTime;
    double						fps;
    unsigned int                SamplesPerSec; //  波特率
    unsigned int				BitsPerSample; // 采样精度
    unsigned int				Channel; // 音频通道数
    unsigned int				UnUse1;
    unsigned int				UnUse2;
    unsigned int				UnUse3;
    unsigned int				UnUse4;
    char						IP[20];
    char						ChannelName[200];
    
    //	_RECORD_FILE_HEAD_INFO()
    //	{
    //		Ver = RECORD_FILE_VERSION;
    //		RecordType = RECORD_TYPE_PLAN;
    //		EncodeType = 0;
    //		ChannelID = 0;
    //		StartTime = 0.0;
    //		EndTime = 0.0;
    //		fps = 0.0;
    //		SamplesPerSec = 0;
    //		BitsPerSample = 0;
    //		Channel = 0;
    //		UnUse1 = 0;
    //		UnUse2 = 0;
    //		UnUse3 = 0;
    //		UnUse4 = 0;
    //		IP[0] = 0;
    //		ChannelName[0] = 0;
    //	}
    
};
typedef struct _RECORD_FILE_HEAD_INFO RECORD_FILE_HEAD_INFO,*PRECORD_FILE_HEAD_INFO;


struct _RECORD_FILE_INDEX_DATA
{

	/*DWORD*/unsigned int		TimeOffset;	// ∫¡√Î
	/*DWORD*/unsigned int		FileOffset;

//	_RECORD_FILE_INDEX_DATA()
//	{
//		TimeOffset = 0;
//		FileOffset = 0;
//	}

};
typedef struct _RECORD_FILE_INDEX_DATA RECORD_FILE_INDEX_DATA, *PRECORD_FILE_INDEX_DATA;;


#define		RECORD_FILE_INDEX_LEN		60*60
struct _RECORD_FILE_INDEX_INFO
{

	int							Size;
	int							Count;
	RECORD_FILE_INDEX_DATA		Index[RECORD_FILE_INDEX_LEN];

//	_RECORD_FILE_INDEX_INFO()
//	{
//		Count = 0;
//		Size = RECORD_FILE_INDEX_LEN;
//	}
};
typedef struct _RECORD_FILE_INDEX_INFO RECORD_FILE_INDEX_INFO, *PRECORD_FILE_INDEX_INFO;


#define		DATA_TYPE_AUDIO	0
#define		DATA_TYPE_VIDEO	1
struct _RECORD_FILE_DATA_INFO
{
	char						Type; // audio 0 video 1
	/*DWORD*/unsigned int						TimeStamp;
	int							Len; // data len
	//char*						Data;

//	_RECORD_FILE_DATA_INFO()
//	{
//		Type = DATA_TYPE_VIDEO;
//		Len = 0;
//		TimeStamp = 0;
//	}
};
typedef struct _RECORD_FILE_DATA_INFO RECORD_FILE_DATA_INFO, *PRECORD_FILE_DATA_INFO;


struct _RECORD_DISK_FILE_INFO
{
	int		Type; // 1:∞¥ ±º‰¥Ú∞¸ 2:∞¥Œƒº˛¥Û–°¥Ú∞¸ 3:∞¥ ±º‰º∞Œƒº˛¥Û–°¥Ú∞¸
	int		Time; //  ±º‰ µ•Œª∑÷÷” 5 10 15 30 60 ◊Ó¥Û60
	int		Size; // Œƒº˛¥Û–° µ•ŒªM	100 200 300 500 1000 ◊Ó¥Û1000

//	_RECORD_DISK_FILE_INFO()
//	{
//		Type = 1;
//		Time = 5;
//		Size = 200;
//	}

};
typedef struct _RECORD_DISK_FILE_INFO RECORD_DISK_FILE_INFO, *PRECORD_DISK_FILE_INFO;





/*typedef struct _RECORD_DISK_DATA
{

	char	DiskName;	// ≈Ã∑˚ c d e°≠°≠
	char	Path[MAX_PATH];		// ¬∑æ∂ "c:\\VMS_RECORD"
	int		SwitchValue; // ¥≈≈Ã«–ªª÷µ µ•Œª:M
	int		WarningValue; // ¥≈≈ÃæØΩ‰÷µ µ•Œª:M
	int		FreeValue;	// ¥≈≈Ãø…”√ø’º‰ µ•Œª:M
	int		TotalValue;	// ¥≈≈Ã◊‹ø’º‰ µ•Œª:M

	_RECORD_DISK_DATA()
	{
		DiskName = 'c';
		Path[0] = 0; // 
		SwitchValue = 3000;
		WarningValue = 6000;
		FreeValue = 0;
		TotalValue = 0;
	}

}RECORD_DISK_DATA, *PRECORD_DISK_DATA;*/

/*typedef struct _RECORD_DISK_INFO
{

	char				CurrentDiskName; // µ±«∞¬ºœÒ≈Ã∑˚
	int					Count;
	RECORD_DISK_DATA	DiskData[26];

	_RECORD_DISK_INFO()
	{
		CurrentDiskName = 'c';
		Count = 0;
	}

}RECORD_DISK_INFO, *PRECORD_DISK_INFO;*/


/////////////////////////////// Record File Struct  End	  ///////////////////////////////
#endif