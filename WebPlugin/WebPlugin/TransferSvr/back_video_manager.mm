#ifdef _WIN32
#include "StdAfx.h"
#endif

#include "vms_error.h"
#include "back_xml_parser.h"
#include "vms_command.h"
#include "back_video_manager.h"
#include "vms_client_manager.h"
#ifdef _WIN32
#include <Mmsystem.h>
#include <AtlBase.h>
#endif

#ifdef  __APPLE__
#import <Cocoa/Cocoa.h>
#include <sys/time.h>
#endif


static struct timeval obj_initialization_time;

#ifdef __APPLE__
#define DWORD   unsigned int
static unsigned int timeGetTime()
{
    struct timeval cur_time;
    gettimeofday(&cur_time,NULL);
    return (cur_time.tv_sec - obj_initialization_time.tv_sec) * 1000 +
    (cur_time.tv_usec - obj_initialization_time.tv_usec) / 1000000;
}
#endif


back_video_manager::back_video_manager(void)
{
    static bool first_initialization = true;
    if (first_initialization) {
        gettimeofday(&obj_initialization_time, NULL);
        first_initialization = false;
    }
}

back_video_manager::~back_video_manager(void)
{
}

back_video_manager& back_video_manager::instance()
{
	static back_video_manager manager;
	return manager;
}

#ifdef _WIN32
int back_video_manager::find_video_file(back_video* bv, time_t begin_time)
{
    int type;
    time_t begin = -1, end =-1;
    time_t min_begin = -1;
    const char* ini = "./vms.ini";
    
    int disk_count = GetPrivateProfileIntA("RECORD_DISK", "COUNT", 0, ini);
    for(int disk=0; disk<disk_count; disk++)
    {
        char keyName[256];
        sprintf(keyName, "DISK_PATH_%d", disk);
        char rootPath[MAX_PATH];
        GetPrivateProfileStringA("RECORD_DISK", keyName, "",  rootPath, sizeof(rootPath)-1, ini);
        
        char path[1024];
        sprintf(path, "%s\\%d\\*.*", rootPath, bv->vid);
        
        WIN32_FIND_DATAA FindFileData;
        HANDLE hFind = INVALID_HANDLE_VALUE;
        hFind = FindFirstFileA(path, &FindFileData);
        if (hFind == INVALID_HANDLE_VALUE)
            continue;
        
        if((FindFileData.dwFileAttributes & FILE_ATTRIBUTE_DIRECTORY) == 0) //is file, not is a directory
        {
            parse_file_name(FindFileData.cFileName, &type, &begin, &end);
            if((begin <= begin_time && begin_time < end) || begin_time < begin)
            {
                bool find = false;
                for(int i=0; i< bv->client->record_type_count; i++)//check type is selected by client
                {
                    if(type == bv->client->record_types[i])
                    {
                        find = true;
                        break;
                    }
                }
                if(find)
                {
                    sprintf(path, "%s\\%d\\%s", rootPath, bv->vid, FindFileData.cFileName);
                    bv->cur_file_name = path;
                    min_begin = begin;
                }
            }
        }
        
        while (FindNextFileA(hFind, &FindFileData) != 0)
        {
            if((FindFileData.dwFileAttributes & FILE_ATTRIBUTE_DIRECTORY) == 0) //is file, not is a directory
            {
                begin = -1;
                end = -1;
                parse_file_name(FindFileData.cFileName, &type, &begin, &end);
                if( ((begin <= begin_time && begin_time < end) || begin_time < begin)
                   && bv->client->end_time > begin)
                {
                    bool find = false;
                    for(int i=0; i< bv->client->record_type_count; i++)//check type is selected by cliented
                    {
                        if(type == bv->client->record_types[i])
                        {
                            find = true;
                            break;
                        }
                    }
                    if(find && (min_begin == -1 || min_begin > begin))
                    {
                        sprintf(path, "%s\\%d\\%s", rootPath, bv->vid, FindFileData.cFileName);
                        bv->cur_file_name = path;
                        min_begin = begin;
                    }
                }
            }
        }
        FindClose(hFind);
        if(min_begin != -1)
            return 0;
    }
    return -1;
}
#endif

#ifdef __APPLE__


int back_video_manager::find_video_file(back_video* bv, time_t begin_time)
{
    NSString *resLocation = [[NSBundle mainBundle] resourcePath];
    NSString *plistLocation = [NSString stringWithFormat:@"%@/vms.plist",resLocation];
    NSDictionary *plistDict = [NSDictionary dictionaryWithContentsOfFile:plistLocation];
    NSDictionary *recordingSetting = [plistDict valueForKey:@"RECORDING_SETTING"];
    NSString *rootPath = [recordingSetting valueForKey:@"RECORDING_PATHNAME"];
    
    NSError *err;
    NSURL *folderUrl = [NSURL URLWithString:[NSString stringWithFormat:@"%@/%d",rootPath,bv->vid]];
    NSArray *fileURLs = [[NSFileManager defaultManager] contentsOfDirectoryAtURL :folderUrl includingPropertiesForKeys :nil options :0 error :&err];
    
    if (!err) {
        int type;
        time_t begin = -1, end =-1;
        time_t min_begin = -1;
        char path[1024];
        
        for (NSURL *fileUrl in fileURLs) {
            NSString *file = [fileUrl path];
            const char *fileName = [[file lastPathComponent] UTF8String];
            
            begin = -1;
            end = -1;
            parse_file_name(fileName, &type, &begin, &end);
            if( ((begin <= begin_time && begin_time < end) || begin_time < begin)
               && bv->client->end_time > begin)
            {
                bool find = false;
                for(int i=0; i< bv->client->record_type_count; i++)//check type is selected by cliented
                {
                    if(type == bv->client->record_types[i])
                    {
                        find = true;
                        break;
                    }
                }
                if(find && (min_begin == -1 || min_begin > begin))
                {
                    sprintf(path, "%s/%d/%s", [rootPath UTF8String], bv->vid, fileName);
                    bv->cur_file_name = path;
                    min_begin = begin;
                }
            }
        }
        
        if(min_begin != -1)
            return 0;
    }
    
    return -1;
}
#endif



void back_video_manager::parse_file_name(const std::string& file_name,
                                         int* type,
                                         time_t* begin_time,
                                         time_t* end_time)
{
	std::string::size_type pos = file_name.find_last_of("/");
	std::string name = file_name.substr(pos+1);

	struct tm begin_tm, end_tm;
	sscanf(name.c_str(), "%d__%d-%d-%d_%d-%d-%d___%d-%d-%d_%d-%d-%d.vms", 
		type,
		&begin_tm.tm_year, 
		&begin_tm.tm_mon,
		&begin_tm.tm_mday,
		&begin_tm.tm_hour,
		&begin_tm.tm_min,
		&begin_tm.tm_sec,
		&end_tm.tm_year, 
		&end_tm.tm_mon,
		&end_tm.tm_mday,
		&end_tm.tm_hour,
		&end_tm.tm_min,
		&end_tm.tm_sec);

	begin_tm.tm_year -= 1900;
	begin_tm.tm_isdst = 0;
	begin_tm.tm_mon -= 1;
	*begin_time = mktime(&begin_tm);

	end_tm.tm_year -= 1900;
	end_tm.tm_isdst = 0;
	end_tm.tm_mon -= 1;
	*end_time = mktime(&end_tm);
}

int back_video_manager::get_video_file(back_video* bv, time_t begin_time)
{
	int result = find_video_file(bv, begin_time);
	if(result != 0)
		return result;

	int type;
	parse_file_name(bv->cur_file_name, &type, &bv->cur_begin_time, &bv->cur_end_time);
	return 0;
}

int back_video_manager::get_first_frame(back_video& bv,
										time_t begin_time,
										RECORD_FILE_DATA_INFO* cur_frame, 
										char** av_data, 
										int* av_data_len)
{
	//close current file and open new file
	if(bv.cur_file_handle)
	{
		fclose(bv.cur_file_handle);
		bv.cur_file_handle = NULL;
	}
	//get file with back video information

	int result = get_video_file(&bv, begin_time);
	if(result != 0)
		return -1;

	FILE* f = fopen(bv.cur_file_name.c_str(), "rb");
	if(f == NULL)
		return -1;

	//read file head
	size_t readed = fread(&bv.file_head, 1, sizeof(RECORD_FILE_HEAD_INFO), f);
	if(readed < sizeof(RECORD_FILE_HEAD_INFO))
	{
		fclose(f);
		return -1;
	}

	//RECORD_FILE_INDEX_INFO 
	readed = fread(&bv.file_index_info, 1, sizeof(RECORD_FILE_INDEX_INFO), f);
	if(readed < sizeof(RECORD_FILE_INDEX_INFO))
	{
		fclose(f);
		return -1;
	}

	//go to begin play position
	if(begin_time > bv.cur_begin_time)
	{
		double offset = (begin_time - bv.cur_begin_time)*1000.0;
		unsigned long index_offset = bv.file_index_info.Index[0].TimeOffset;
		//go to index of begin time 
		int find = 0;
		for(int i=0; i<bv.file_index_info.Count; i++)
		{
			if((bv.file_index_info.Index[i].TimeOffset-index_offset) > offset)
			{
				if(i>0)
					i--;
				fseek(f, bv.file_index_info.Index[i].FileOffset, SEEK_SET);
				find = 1;
				break;
			}
		}
		if(find == 0)
		{
			fclose(f);
			return -1;
		}

		//go to frame of begin time 
		while(1)
		{
			int readed = fread(cur_frame, 1, sizeof(RECORD_FILE_DATA_INFO), f);
			if(readed < sizeof(RECORD_FILE_DATA_INFO))
			{
				fclose(f);
				return -1;
			}
			if((cur_frame->TimeStamp-index_offset) > offset)
			{
				fseek(f, 0-sizeof(RECORD_FILE_DATA_INFO), SEEK_CUR); 
				break;
			}
			fseek(f, cur_frame->Len, SEEK_CUR);
		}
	}

	readed = fread(cur_frame, 1, sizeof(RECORD_FILE_DATA_INFO), f);
	if(readed < sizeof(RECORD_FILE_DATA_INFO))
	{
		fclose(f);
		return -1;
	}
	//get frame data
	if(*av_data_len < cur_frame->Len)
	{
		*av_data = (char*)realloc(*av_data, cur_frame->Len);
		*av_data_len = cur_frame->Len;
	}

	readed = fread(*av_data, 1, cur_frame->Len, f);
	if((int)readed < cur_frame->Len)
	{
		fclose(f);
		return -1;
	}
	bv.cur_file_handle = f;

	return 0;
}

int back_video_manager::get_next_frame(back_video& bv,
									   _RECORD_FILE_DATA_INFO* cur_frame,
									   char** av_data,
									   int* av_data_len)
{
	while(1)
	{
		//get next frame
		int readed = fread(cur_frame, 1, sizeof(RECORD_FILE_DATA_INFO), bv.cur_file_handle);
		if(readed < sizeof(RECORD_FILE_DATA_INFO))
		{
			return -1;
		}
		if(!bv.play_audio && cur_frame->Type == DATA_TYPE_AUDIO) //skip audio frame
		{
			fseek(bv.cur_file_handle, cur_frame->Len, SEEK_CUR);
			continue;
		}
		//get frame data
		if(*av_data_len < cur_frame->Len)
		{
			*av_data = (char*)realloc(*av_data, cur_frame->Len);
			*av_data_len = cur_frame->Len;
		}
		readed = fread(*av_data, 1, cur_frame->Len, bv.cur_file_handle);
		if((int)readed < cur_frame->Len)
			return -1;

		break;
	}
	return 0;
}




void back_video_manager::play_back_thread(back_thread_arg* arg)
{
	back_video& bv = arg->client->videos[arg->index];
	
	RECORD_FILE_DATA_INFO cur_frame;
#define DEFAULT_FRAME_DATA_LEN 8192
	int av_data_len = DEFAULT_FRAME_DATA_LEN;
	char* av_data = (char*)malloc(av_data_len);
	char type;
	unsigned long first_frame_time = -1; //first frame in record file
	DWORD begin_time = timeGetTime(); //first frame in timeGetTime
	double stamp;
	float cur_play_speep = bv.play_speed;

	int result = get_first_frame(bv, arg->client->begin_time, &cur_frame, &av_data, &av_data_len);
	if(result == 0)
		first_frame_time = cur_frame.TimeStamp;

	while(bv.thread_run)
	{
		//client change the time on user interface
		if(bv.client_play_begin_time_changed)
		{
			bv.client_play_begin_time_changed = false;
			result = get_first_frame(bv, bv.client_play_begin_time, &cur_frame, &av_data, &av_data_len);
			if(result == 0)
			{
				first_frame_time = cur_frame.TimeStamp;
				begin_time = timeGetTime();
			}
			continue;
		}

		//client change the play speed on user interface
		if(cur_play_speep != bv.play_speed)
		{
			cur_play_speep = bv.play_speed;
			first_frame_time = cur_frame.TimeStamp;
			begin_time = timeGetTime();
		}

		//no find file in time range, or failed to open file, or file is bad,
		//sleep and open next file
		if(bv.cur_file_handle == NULL)
		{
			result = get_first_frame(bv, bv.cur_end_time, &cur_frame, &av_data, &av_data_len);
			if(result == 0)
			{
				first_frame_time = cur_frame.TimeStamp;
				begin_time = timeGetTime();
			}
			else
				usleep(500*1000);//Sleep(500);
			continue;
		}

		type = cur_frame.Type == 0 ? VMS_AUDIO_DATA : VMS_VIDEO_DATA;

		//time stamp is real millisecond time of current frame
		stamp = bv.cur_begin_time*1000.0 + cur_frame.TimeStamp - bv.file_index_info.Index[0].TimeOffset;

		VMS_CMD_HEADER* cmd = create_av_data_cmd(bv.vid, type, av_data, cur_frame.Len, stamp);
		vms_client_manager::instance().send_data_to_client(bv.client_id, cmd); //net_socket::handle_write will destroy the command

		result = get_next_frame(bv, &cur_frame, &av_data, &av_data_len);
		if(result != 0) 
		{	
			//current file is end, open next file
			result = get_first_frame(bv, bv.cur_end_time, &cur_frame, &av_data, &av_data_len);
			if(result == 0)
			{
				first_frame_time = cur_frame.TimeStamp;
				begin_time = timeGetTime();
			}
			continue;
		}
		
		//Sleep until next video frame time
		if(cur_frame.Type == 1 && cur_frame.TimeStamp > first_frame_time)
		{
			unsigned long stampSpan = (unsigned long)((cur_frame.TimeStamp - first_frame_time) * cur_play_speep);
			DWORD span = timeGetTime() - begin_time;
			if(stampSpan > span )
			{
				DWORD sleepTime = stampSpan - span;
				static DWORD MAX_SPAN = 1000;
				if(sleepTime > MAX_SPAN) //if time span too large, reset begin time
				{
					sleepTime = MAX_SPAN;
					first_frame_time = cur_frame.TimeStamp;
					begin_time = timeGetTime();
				}
                usleep(sleepTime * 1000);//Sleep(sleepTime);
			}
		}
	}
	free(av_data);
	if(bv.cur_file_handle)
		fclose(bv.cur_file_handle);
	delete arg;
}

time_t string2time_t(const std::string& str)         
{
	struct tm t;
	sscanf(str.c_str(), "%d-%d-%d %d:%d:%d", 
		&t.tm_year, 
		&t.tm_mon,
		&t.tm_mday,
		&t.tm_hour,
		&t.tm_min,
		&t.tm_sec);
	t.tm_year -= 1900;
	t.tm_isdst = 0;
	t.tm_mon -= 1;
	return mktime(&t);
}

int back_video_manager::open_video(unsigned int cid, const std::string& xml)
{
	boost::recursive_mutex::scoped_lock lock(client_map_mutex_);
	BACK_VIDEO_MAP::iterator it = backVideoMap.find(cid);
	if(it != backVideoMap.end())
		return VIDEO_IS_OPENED;

	back_xml_parser parser(xml);
	if(parser.valid == false)
		return XML_INVALID;

	boost::shared_ptr<back_video_client> client(new back_video_client);//use shared_ptr for multi play_back_thread thread 
	client->client_id = cid;
	backVideoMap[cid] = client;

	client->begin_time = string2time_t(parser.begin_time);
	client->end_time = string2time_t(parser.end_time);
	client->record_type_count = parser.record_type_count;
	client->record_types = new int[client->record_type_count];
	for(int i=0; i<client->record_type_count; i++)
		client->record_types[i] = parser.record_types[i];
	client->video_count = parser.item_count;
	client->videos = new back_video[client->video_count];
	for(int i=0; i<client->video_count; i++)
	{
		back_video& bv = client->videos[i];
		back_video_item& item = parser.items[i];
		bv.client_id = cid;
		bv.thread_run = true;
		bv.vid = item.video_id;
		bv.play_audio = false;
		bv.play_speed = 1.0;
		bv.cur_begin_time = bv.cur_end_time = 0;
		bv.cur_file_handle = NULL;
		bv.client_play_begin_time = 0;
		bv.client_play_begin_time_changed = false;
		bv.client = client.get();

		back_thread_arg* arg = new back_thread_arg; //delete in play_back_thread
		arg->client = client;
		arg->index = i;
		bv.thread = new boost::thread(&play_back_thread, arg);
	}

	return VMS_SUCCESS;
}

void back_video_manager::close_client(unsigned int cid)
{
	boost::recursive_mutex::scoped_lock lock(client_map_mutex_);
	BACK_VIDEO_MAP::iterator it = backVideoMap.find(cid);
	if(it == backVideoMap.end())
		return ;

	boost::shared_ptr<back_video_client> client = it->second;
	for(int i=0; i<client->video_count; i++)
	{
		client->videos[i].thread_run = false; //for stop play_back_thread
	}
	backVideoMap.erase(it);
}
void back_video_manager::close_all_client()
{
	boost::recursive_mutex::scoped_lock lock(client_map_mutex_);
	for(BACK_VIDEO_MAP::iterator it = backVideoMap.begin(); it!=backVideoMap.end(); it++)
	{
		boost::shared_ptr<back_video_client> client = it->second;
		for(int i=0; i<client->video_count; i++)
		{
			client->videos[i].thread_run = false; //for stop play_back_thread
		}
	}
	backVideoMap.clear();
}

int back_video_manager::open_audio(unsigned int cid, unsigned int vid)
{
	boost::recursive_mutex::scoped_lock lock(client_map_mutex_);
	BACK_VIDEO_MAP::iterator it = backVideoMap.find(cid);
	if(it == backVideoMap.end())
		return VIDEO_IS_CLOSE;

	boost::shared_ptr<back_video_client> client = it->second;
	for(int i=0; i<client->video_count; i++)
	{
		if(client->videos[i].vid == vid)
		{
			client->videos[i].play_audio = true;
			break;
		}
	}
	return VMS_SUCCESS;
}

void back_video_manager::close_audio(unsigned int cid, unsigned int vid)
{
	boost::recursive_mutex::scoped_lock lock(client_map_mutex_);
	BACK_VIDEO_MAP::iterator it = backVideoMap.find(cid);
	if(it == backVideoMap.end())
		return ;
	boost::shared_ptr<back_video_client> client = it->second;
	for(int i=0; i<client->video_count; i++)
	{
		if(client->videos[i].vid == vid)
		{
			client->videos[i].play_audio = false;
			break;
		}
	}
}

void back_video_manager::set_play_speed(unsigned int cid, unsigned int vid, float speed)
{
	boost::recursive_mutex::scoped_lock lock(client_map_mutex_);
	BACK_VIDEO_MAP::iterator it = backVideoMap.find(cid);
	if(it == backVideoMap.end())
		return ;
	boost::shared_ptr<back_video_client> client = it->second;
	for(int i=0; i<client->video_count; i++)
	{
		if(client->videos[i].vid == vid)
		{
			client->videos[i].play_speed = 1.0f / speed;
			break;
		}
	}
}


void back_video_manager::set_play_begin_time(unsigned int cid, unsigned int vid, std::string& begin)
{
	boost::recursive_mutex::scoped_lock lock(client_map_mutex_);
	BACK_VIDEO_MAP::iterator it = backVideoMap.find(cid);
	if(it == backVideoMap.end())
		return ;
	boost::shared_ptr<back_video_client> client = it->second;
	for(int i=0; i<client->video_count; i++)
	{
		if(client->videos[i].vid == vid)
		{
			client->videos[i].client_play_begin_time = string2time_t(begin);
			client->videos[i].client_play_begin_time_changed = true;
			break;
		}
	}
}