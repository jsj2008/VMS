#pragma once

class AvSourceCallBack
{
public:
	virtual void on_video_data(int device_id, void* data, int data_len, double timestamp)=0;
	virtual void on_audio_data(int device_id, void* data, int data_len, double timestamp)=0;
};

class AvSource
{
public:
	AvSource(AvSourceCallBack* cb);
	~AvSource(void);
	virtual int open_video(int device_id) = 0;
	virtual void close_video(int device_id) = 0 ;

	virtual int open_audio(int device_id) = 0;
	virtual void close_audio(int device_id) = 0 ;

	virtual void ptz_controll(int devide_id, int type,	int param1,	int param2,	int param3,	int param4,	const char* param5) = 0;
protected:
	AvSourceCallBack* callback;
};
AvSource* create_live_av_source(AvSourceCallBack* cb);
