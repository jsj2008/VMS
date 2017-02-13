#pragma once

#include <boost/thread/recursive_mutex.hpp>
#include <map>
#include <set>
#include "AvSource.h"

class live_video_manager:public AvSourceCallBack
{
public:
	live_video_manager(void);
	static live_video_manager& instance();
	int open_video(unsigned int cid, unsigned int vid);
	void close_video(unsigned int cid, unsigned int vid);
	int open_audio(unsigned int cid, unsigned int vid);
	void close_audio(unsigned int cid, unsigned int vid);
	void close_client(unsigned int cid);
	void ptz(unsigned int cid, unsigned int vid, std::string& xml);
	void close_all_client();
public:
	void on_video_data(int device_id, void* data, int data_len, double timestamp);
	void on_audio_data(int device_id, void* data, int data_len, double timestamp);
private:
	virtual ~live_video_manager(void);
	boost::recursive_mutex recursive_mutex_;

	class live_video
	{
	public:
		std::set<unsigned int> video_clients;
		std::set<unsigned int> audio_clients;
	};
	
#define LIVE_VIDEO_MAP std::map<unsigned int, live_video*> 
	//key is video or device id, value is live_video* 
	LIVE_VIDEO_MAP liveVideoMap ;

	AvSource* avSource;

private:
	void on_av_data(int device_id, int type, void* data, int data_len, double timestamp);
};
