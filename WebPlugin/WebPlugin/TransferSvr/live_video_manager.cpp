#ifdef _WIN32
#include "StdAfx.h"
#endif

#include "live_video_manager.h"
#include "vms_error.h"
#include "config.h"
#include "vms_command.h"
#include "vms_client_manager.h"
#include "ptz_xml_parser.h"

live_video_manager::live_video_manager(void)
{
	avSource = create_live_av_source(this);
}

live_video_manager::~live_video_manager(void)
{
	delete avSource;
}

live_video_manager& live_video_manager::instance()
{
	static live_video_manager lv;
	return lv;
}

int live_video_manager::open_audio(unsigned int cid, unsigned int vid)
{
	bool open = false;
	do 
	{
		boost::recursive_mutex::scoped_lock lock(recursive_mutex_);
		live_video* lv;
		LIVE_VIDEO_MAP::iterator it = liveVideoMap.find(vid);
		if(it != liveVideoMap.end())
		{
			lv = it->second;
			if(lv->audio_clients.find(cid) != lv->audio_clients.end())//the audio is opened by same client
				return AUDIO_IS_OPENED;
			lv->audio_clients.insert(cid);
			if(lv->audio_clients.size() == 1)//first client want to open audio
				open = true;
		}
		else
		{
			return VIDEO_IS_CLOSE;
		}

	} while (0);

	if(open)
		avSource->open_audio(vid);
	return VMS_SUCCESS;
}

void live_video_manager::close_audio(unsigned int cid, unsigned int vid)
{
	bool close = false;
	do 
	{
		boost::recursive_mutex::scoped_lock lock(recursive_mutex_);

		LIVE_VIDEO_MAP::iterator it = liveVideoMap.find(vid);
		if(it == liveVideoMap.end())
			return;
		live_video* lv = it->second;
		std::set<unsigned int>::size_type erase_count = lv->audio_clients.erase(cid);
		if(erase_count == 1 && lv->audio_clients.size() == 0) //no client is opening video,so close it
			close = true;
	}while (0);
	if(close)
		avSource->close_audio(vid);
}

int live_video_manager::open_video(unsigned int cid, unsigned int vid)
{
	bool open = false;
	do 
	{
		boost::recursive_mutex::scoped_lock lock(recursive_mutex_);
		live_video* lv;
		LIVE_VIDEO_MAP::iterator it = liveVideoMap.find(vid);
		if(it != liveVideoMap.end())
		{
			lv = it->second;
			if(lv->video_clients.find(cid) != lv->video_clients.end())//the video is opened by same client
				return VIDEO_IS_OPENED;
		}
		else
		{
			lv = new live_video; //first client want to open video,insert to liveVideoMap
			liveVideoMap[vid] = lv;
		}
		lv->video_clients.insert(cid);
		if(lv->video_clients.size() == 1)
			open = true;
	} while (0);

	if(open)
		avSource->open_video(vid);
	return VMS_SUCCESS;
}

void live_video_manager::close_video(unsigned int cid, unsigned int vid)
{
	bool closeVideo = false;
	bool closeAudio = false;
	do 
	{
		boost::recursive_mutex::scoped_lock lock(recursive_mutex_);

		LIVE_VIDEO_MAP::iterator it = liveVideoMap.find(vid);
		if(it == liveVideoMap.end())
			return;
		live_video* lv = it->second;
		std::set<unsigned int>::size_type erase_count = lv->video_clients.erase(cid);
		if(erase_count == 1 && lv->video_clients.size() == 0) //no client is opening video,so close it
		{
			closeVideo = true;
			closeAudio = true;
		}

		erase_count = lv->audio_clients.erase(cid); //when video closed, also close audio
		if(erase_count == 1 && lv->audio_clients.size() == 0) 
			closeAudio = true;

		if(closeVideo)
		{
			delete lv;
			liveVideoMap.erase(it);
		}
	}while (0);

	if(closeAudio)
		avSource->close_audio(vid);

	if(closeVideo)
		avSource->close_video(vid);
}

void live_video_manager::close_all_client()
{
	unsigned int* closeVideos = NULL;
	unsigned int* closeAudios = NULL;
	unsigned int closeVideoCount=0;
	unsigned int closeAudioCount=0;

	do 
	{
		boost::recursive_mutex::scoped_lock lock(recursive_mutex_);
		if(liveVideoMap.size() == 0)
			return;

		closeAudios = new unsigned int[liveVideoMap.size()];
		closeVideos = new unsigned int[liveVideoMap.size()];
		//remove the client id from liveVideoMap
		for(LIVE_VIDEO_MAP::iterator it = liveVideoMap.begin(); it!= liveVideoMap.end(); it++)
		{
			live_video* lv = it->second;
			if(lv->video_clients.size()) 
				closeVideos[closeVideoCount++] = it->first;

			if(lv->audio_clients.size()) 
				closeAudios[closeAudioCount++] = it->first;

			delete lv;
		}
		liveVideoMap.clear();
	} while (0);

	for(unsigned int i=0; i<closeAudioCount; i++)
	{
		avSource->close_audio(closeAudios[i]);
	}

	for(unsigned int i=0; i<closeVideoCount; i++)
	{
		avSource->close_video(closeVideos[i]);
	}

	delete[] closeAudios;
	delete[] closeVideos;
}
void live_video_manager::close_client(unsigned int cid)
{
	unsigned int* closeVideos = NULL;
	unsigned int* closeAudios = NULL;
	unsigned int closeVideoCount=0;
	unsigned int closeAudioCount=0;

	do 
	{
		boost::recursive_mutex::scoped_lock lock(recursive_mutex_);
		if(liveVideoMap.size() == 0)
			return;

		closeAudios = new unsigned int[liveVideoMap.size()];
		closeVideos = new unsigned int[liveVideoMap.size()];
		//remove the client id from liveVideoMap
		for(LIVE_VIDEO_MAP::iterator it = liveVideoMap.begin(); it!= liveVideoMap.end();)
		{
			live_video* lv = it->second;
			std::set<unsigned int>::size_type erase_count = lv->video_clients.erase(cid);
			if(erase_count == 1 && lv->video_clients.size() == 0) //no client is opening video,so close it
				closeVideos[closeVideoCount++] = it->first;

			erase_count = lv->audio_clients.erase(cid); 
			if(erase_count == 1 && lv->audio_clients.size() == 0) //no client is opening audio,so close it
				closeAudios[closeAudioCount++] = it->first;

			if(lv->video_clients.size() == 0)
			{
				delete lv;
				liveVideoMap.erase(it++); 
			}
			else
				++it;
		}
	} while (0);

	for(unsigned int i=0; i<closeAudioCount; i++)
	{
		avSource->close_audio(closeAudios[i]);
	}

	for(unsigned int i=0; i<closeVideoCount; i++)
	{
		avSource->close_video(closeVideos[i]);
	}

	delete[] closeAudios;
	delete[] closeVideos;
}

//send data to the clients is opening video or audio
void live_video_manager::on_av_data(int device_id, int type, void* data, int data_len, double timestamp)
{
	unsigned int* clients = NULL;
	int client_count = 0;
	do 
	{
		boost::recursive_mutex::scoped_lock lock(recursive_mutex_);
		LIVE_VIDEO_MAP::iterator it = liveVideoMap.find(device_id);
		if(it == liveVideoMap.end())
			return;

		live_video* lv = it->second;
		std::set<unsigned int>* clientSet = NULL;
		if(type == VMS_VIDEO_DATA)
			clientSet = &lv->video_clients;
		else
			clientSet = &lv->audio_clients;

		if(clientSet->size() == 0)
			return;
		clients = new unsigned int[clientSet->size()];

		for(std::set<unsigned int>::iterator itClient=clientSet->begin(); itClient!=clientSet->end(); ++itClient)
			clients[client_count++] = *itClient;
	} while (0);

	for(int i=0; i<client_count; i++)
	{	
		VMS_CMD_HEADER* cmd = create_av_data_cmd(device_id, type, (const char*)data, data_len, timestamp);
		vms_client_manager::instance().send_data_to_client(clients[i], cmd); //net_socket::handle_write will destroy the command
	}

	if(clients)
		delete[] clients;
}

void live_video_manager::on_video_data(int device_id, void* data, int data_len, double timestamp)
{
	on_av_data(device_id, VMS_VIDEO_DATA, data, data_len, timestamp);
}

void live_video_manager::on_audio_data(int device_id, void* data, int data_len, double timestamp)
{
	on_av_data(device_id, VMS_AUDIO_DATA, data, data_len, timestamp);
}

void live_video_manager::ptz(unsigned int cid, unsigned int vid, std::string& xml)
{
	ptz_xml_parser parser(xml);
	if(!parser.valid)
		return;

	avSource->ptz_controll(vid, parser.type, parser.param1, parser.param2, parser.param3, parser.param4, parser.param5.c_str());
}
