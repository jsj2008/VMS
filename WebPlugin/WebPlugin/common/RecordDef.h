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
	char						RecordType; // ¼������ 0: plan 1:Manual
	char						EncodeType;
	int							ChannelID;
	double						StartTime;
	double						EndTime;
	double						fps;
	DWORD						SamplesPerSec; //  ������
	DWORD						BitsPerSample; // ��������
	DWORD						Channel; // ��Ƶͨ����
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

	DWORD		TimeOffset;	// ����
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
	int		Type; // 1:��ʱ���� 2:���ļ���С��� 3:��ʱ�估�ļ���С���
	int		Time; // ʱ�� ��λ���� 5 10 15 30 60 ���60
	int		Size; // �ļ���С ��λM	100 200 300 500 1000 ���1000

	_RECORD_DISK_FILE_INFO()
	{
		Type = 1;
		Time = 5;
		Size = 200;
	}

}RECORD_DISK_FILE_INFO, *PRECORD_DISK_FILE_INFO;

typedef struct _RECORD_DISK_DATA
{

	char	DiskName;	// �̷� c d e����
	char	Path[MAX_PATH];		// ·�� "c:\\VMS_RECORD\\"
	int		SwitchValue; // �����л�ֵ ��λ:M
	int		WarningValue; // ���̾���ֵ ��λ:M
	int		FreeValue;	// ���̿��ÿռ� ��λ:M

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

	char				CurrentDiskName; // ��ǰ¼���̷�
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
