#pragma once

#include <string>
#include <map>
#include <boost/thread/thread.hpp> 
#include <boost/thread/recursive_mutex.hpp>

#ifdef _WIN32
#include <Windows.h>
#endif

#include "RecordDef.h"

class back_video_manager
{
public:
	back_video_manager(void);
	virtual ~back_video_manager(void);

	static back_video_manager& instance();

	int open_video(unsigned int cid, const std::string& xml);
	void close_client(unsigned int cid);

	int open_audio(unsigned int cid, unsigned int vid);
	void close_audio(unsigned int cid, unsigned int vid);

	void close_all_client();

	void set_play_speed(unsigned int cid, unsigned int vid, float speed);

	void set_play_begin_time(unsigned int cid, unsigned int vid, std::string& begin);

private:
	boost::recursive_mutex client_map_mutex_;

	class back_video_client;
	class back_video
	{
	public:
		boost::thread* thread;
		bool thread_run;
		int vid;
		unsigned int client_id;

		bool play_audio;

		float play_speed;

		RECORD_FILE_HEAD_INFO file_head;
		RECORD_FILE_INDEX_INFO file_index_info;

		time_t cur_begin_time; //begin time in file name
		time_t cur_end_time; //end time in file name
		std::string cur_file_name;
		FILE* cur_file_handle;

		time_t client_play_begin_time; //client can change the time use user interface 
		bool client_play_begin_time_changed;

		back_video_client* client;
	};

	class back_video_client
	{
	public:
		unsigned int client_id;
		back_video* videos;
		int video_count;

		time_t begin_time; //from client
		time_t end_time; //from client
		int* record_types;
		int record_type_count; //from client

		back_video_client()
		{
			videos = NULL;
			video_count = 0;
		}
		~back_video_client()
		{
			if(videos)
				delete[] videos;
			if(record_types)
				delete[] record_types;
		}
	};

	class back_thread_arg
	{
	public:
		boost::shared_ptr<back_video_client> client;
		int index;
	};

	#define BACK_VIDEO_MAP std::map<unsigned int, boost::shared_ptr<back_video_client>>
	BACK_VIDEO_MAP backVideoMap ;
private:    
	static void play_back_thread(back_thread_arg* arg);

	static int get_video_file(back_video* bv, time_t begin_time); 

	static int find_video_file(back_video* bv, time_t begin_time);

	static int get_first_frame(back_video& bv,
		time_t begin_time,
		RECORD_FILE_DATA_INFO* cur_frame, 
		char** av_data,
		int* av_data_len);

	static int get_next_frame(back_video& bv,
		RECORD_FILE_DATA_INFO* cur_frame, 
		char** av_data,	
		int* av_data_len);

	static void parse_file_name(const std::string& file_name, int* type, time_t* begin_time, time_t* end_time);
};
