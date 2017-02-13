#ifndef __VMS_COMMAND__
#define __VMS_COMMAND__

#include <string>
#include <list>
#include <boost/asio/detail/socket_ops.hpp>
#include <boost/locale/conversion.hpp>
#include <boost/locale/encoding.hpp>
#include <boost/shared_ptr.hpp>
#include <vector>
#include "vms_log.h"
#include "vms_error.h"

#define MAX_VMS_CMD_LEN 655360
#define VMS_RECV_BUFFER_LEN 8192

#pragma pack(1)

#define VMS_CMD_TYPE_XML 0
#define VMS_CMD_TYPE_BINARY 1

/**
 * This structure data header. All the fields are in network byte
 * order when it's on the wire.
 */
typedef struct _VMS_CMD_HEADER
{
	char type; //0 is utf-8 xml. 1 is binary, video data, audio data
	char reserve[3]; //reserved, fill zero
	unsigned int data_length; //command data length
}VMS_CMD_HEADER;

#define VMS_VIDEO_DATA 0
#define VMS_AUDIO_DATA 1

typedef struct _VMS_BIN_DATA
{
	int cmd;
}VMS_BIN_DATA;

typedef struct _VMS_AV_DATA
{
	int cmd;
	unsigned int device_id;
	double timestamp;
}VMS_AV_DATA;
#pragma pack()

inline void fill_command_header(VMS_CMD_HEADER* header, int length, int type = VMS_CMD_TYPE_XML)
{
	header->type = type;
	header->data_length = boost::asio::detail::socket_ops::host_to_network_long(length); //network byte order
	header->reserve[0] = header->reserve[1] = header->reserve[2] = 0;//reserved, fill zero
}

inline void set_command_data_length(VMS_CMD_HEADER* header, int length)
{
	header->data_length = boost::asio::detail::socket_ops::host_to_network_long(length);
}

inline char* command_offset_data(void* header)
{
	return (char*)header + sizeof(VMS_CMD_HEADER);
}

inline std::string encode_str_to_xml(const std::string& src)
{
#ifdef WIN32
	return boost::locale::conv::between(src, "UTF-8", "GBK" );
#else 
	return src;
#endif
	
}

inline std::string decode_str_from_xml(const std::string& src)
{
#ifdef WIN32
	return boost::locale::conv::between(src, "GBK", "UTF-8" );
#else 
	return src;
#endif
}

inline unsigned int get_net_command_total_length(VMS_CMD_HEADER* header)
{
	return boost::asio::detail::socket_ops::network_to_host_long(header->data_length) + sizeof(VMS_CMD_HEADER);
}

//define command code 
#define VMS_CMD_LOGIN					1
#define VMS_CMD_LOGIN_RESPONSE			2
#define VMS_CMD_LOGOFF					3
#define VMS_CMD_HEART					4
#define VMS_CMD_OPEN_VIDEO				5
#define VMS_CMD_CLOSE_VIDEO				6
#define VMS_CMD_OPEN_VIDEO_RESPONSE		7
#define VMS_CMD_VIDEO_DATA				8
#define VMS_CMD_AUDIO_DATA				9
#define VMS_CMD_OPEN_AUDIO				10
#define VMS_CMD_CLOSE_AUDIO				11
#define VMS_CMD_OPEN_AUDIO_RESPONSE		12
#define VMS_CMD_OPEN_BACK_VIDEO				13
#define VMS_CMD_CLOSE_BACK_VIDEO			14
#define VMS_CMD_OPEN_BACK_VIDEO_RESPONSE	15
#define VMS_CMD_VIDEO_BACK_DATA				16
#define VMS_CMD_AUDIO_BACK_DATA				17
#define VMS_CMD_OPEN_BACK_AUDIO				18
#define VMS_CMD_CLOSE_BACK_AUDIO			19
#define VMS_CMD_OPEN_BACK_AUDIO_RESPONSE	20
#define VMS_CMD_SET_PLAY_SPEED				21
#define VMS_CMD_PTZ							22
#define VMS_CMD_PALY_BEGIN_TIME				23

//client heart time span, in seconds
#define VMS_CLIENT_HEART_SPAN 60

struct VMS_COMMAND
{
	int cmd;
};

struct VMS_RESPONSE_COMMAND: public VMS_COMMAND
{
	int error;
};

struct VMS_LOGIN_RESPONSE_COMMAND: public VMS_RESPONSE_COMMAND
{
	unsigned int cid;
	int heart_span;
};

struct VMS_OPEN_VIDEO_RESPONSE_COMMAND: public VMS_RESPONSE_COMMAND
{
	unsigned int cid;
	unsigned int vid;
};

struct VMS_OPEN_BACK_VIDEO_RESPONSE_COMMAND: public VMS_RESPONSE_COMMAND
{
	unsigned int cid;
};

struct VMS_LOGIN_COMMAND: public VMS_COMMAND
{
	std::string user;
	std::string password;
};

struct VMS_LOGOFF_COMMAND: public VMS_COMMAND
{
	unsigned int cid;
};

struct VMS_HEART_COMMAND: public VMS_COMMAND
{
	unsigned int cid;
};

struct VMS_OPEN_VIDEO_COMMAND: public VMS_COMMAND
{
	unsigned int cid;
	unsigned int vid;
};

struct VMS_CLOSE_VIDEO_COMMAND: public VMS_COMMAND
{
	unsigned int cid;
	unsigned int vid;
};

struct VMS_BINARY_COMMAND: public VMS_COMMAND
{
	char* data;
	int len;
};

struct VMS_OPEN_AUDIO_COMMAND: public VMS_COMMAND
{
	unsigned int cid;
	unsigned int vid;
};

struct VMS_CLOSE_AUDIO_COMMAND: public VMS_COMMAND
{
	unsigned int cid;
	unsigned int vid;
};
struct VMS_OPEN_AUDIO_RESPONSE_COMMAND: public VMS_RESPONSE_COMMAND
{
	unsigned int cid;
	unsigned int vid;
};

struct VMS_OPEN_BACK_VIDEO_COMMAND: public VMS_COMMAND
{
	unsigned int cid;
	std::string xml;
};

struct VMS_CLOSE_BACK_VIDEO_COMMAND: public VMS_COMMAND
{
	unsigned int cid;
};

struct VMS_OPEN_BACK_AUDIO_COMMAND: public VMS_COMMAND
{
	unsigned int cid;
	unsigned int vid;
};

struct VMS_CLOSE_BACK_AUDIO_COMMAND: public VMS_COMMAND
{
	unsigned int cid;
	unsigned int vid;
};

struct VMS_OPEN_BACK_AUDIO_RESPONSE_COMMAND: public VMS_RESPONSE_COMMAND
{
	unsigned int cid;
	unsigned int vid;
};

struct VMS_SET_PLAY_SPEED_COMMAND: public VMS_COMMAND
{
	unsigned int cid;
	unsigned int vid;
	float speed;
};

struct VMS_PTZ_COMMAND: public VMS_COMMAND
{
	unsigned int cid;
	unsigned int vid;
	std::string xml;
};

struct VMS_PLAY_BEGIN_TIME_COMMAND: public VMS_COMMAND
{
	unsigned int cid;
	unsigned int vid;
	std::string beginTime;
};

typedef struct VMS_COMMAND VMS_COMMAND;
typedef struct VMS_RESPONSE_COMMAND VMS_RESPONSE_COMMAND;
typedef struct VMS_LOGIN_COMMAND VMS_LOGIN_COMMAND;
typedef struct VMS_LOGIN_RESPONSE_COMMAND VMS_LOGIN_RESPONSE_COMMAND;
typedef struct VMS_LOGOFF_COMMAND VMS_LOGOFF_COMMAND;
typedef struct VMS_HEART_COMMAND VMS_HEART_COMMAND;
typedef struct VMS_CLOSE_VIDEO_COMMAND VMS_CLOSE_VIDEO_COMMAND;
typedef struct VMS_OPEN_VIDEO_COMMAND VMS_OPEN_VIDEO_COMMAND;
typedef struct VMS_OPEN_VIDEO_RESPONSE_COMMAND VMS_OPEN_VIDEO_RESPONSE_COMMAND;
typedef struct VMS_OPEN_AUDIO_RESPONSE_COMMAND VMS_OPEN_AUDIO_RESPONSE_COMMAND;
typedef struct VMS_OPEN_BACK_VIDEO_COMMAND VMS_OPEN_BACK_VIDEO_COMMAND;
typedef struct VMS_CLOSE_BACK_VIDEO_COMMAND VMS_CLOSE_BACK_VIDEO_COMMAND;

//xml text to command struct,return value must be freed by free_vms_command
VMS_COMMAND* decode_vms_command(const char* data, vms_result_t& error);
void delete_vms_command(VMS_COMMAND* cmd);

std::string command_pwd_encode(const std::string& pwd);

//return value must be freed by free_vms_command
VMS_CMD_HEADER* create_login_command(const char* user, const char* pwd); 
VMS_CMD_HEADER* create_login_response_command(unsigned int id, int result);
VMS_CMD_HEADER* create_logoff_command(unsigned int id);
VMS_CMD_HEADER* create_heart_command(unsigned int id);
VMS_CMD_HEADER* create_open_video_command(unsigned int cid, unsigned int vid);
VMS_CMD_HEADER* create_close_video_command(unsigned int cid, unsigned int vid);
VMS_CMD_HEADER* create_open_video_response_command(unsigned int cid, unsigned int vid, int result);
VMS_CMD_HEADER* create_av_data_cmd(unsigned int video_id, char av_type, const char* data, int data_len, double timestamp);
VMS_CMD_HEADER* create_open_audio_command(unsigned int cid, unsigned int vid, int cmd);
VMS_CMD_HEADER* create_close_audio_command(unsigned int cid, unsigned int vid, int cmd);
VMS_CMD_HEADER* create_open_audio_response_command(unsigned int cid, unsigned int vid, int result);
VMS_CMD_HEADER* create_close_back_video_command(unsigned int id);
VMS_CMD_HEADER* create_open_back_video_command(unsigned int cid, const std::string& xml);
VMS_CMD_HEADER* create_open_back_video_response_command(unsigned int cid, int result);
VMS_CMD_HEADER* create_open_back_audio_response_command(unsigned int cid, unsigned int vid, int result);
VMS_CMD_HEADER* create_set_play_speed_command(unsigned int cid, unsigned int vid, float speed);
VMS_CMD_HEADER* create_ptz_command(unsigned int cid, int vid, const std::string& xml);
VMS_CMD_HEADER* create_set_play_begin_time_command(unsigned int cid, unsigned int vid, const std::string& t);


void destory_vms_command(VMS_CMD_HEADER* header);

//cut network stream to command 
template<typename type>
vms_result_t vms_process_recved_data(const char* receive_buffer, size_t receive_buffer_len, char* cmd_buffer, size_t& cmd_buffer_len, type* t)
{
	size_t pos = 0;
	size_t remain = receive_buffer_len;
	size_t copyed = 0;
	VMS_CMD_HEADER* header;
	vms_result_t r = VMS_SUCCESS;

	while (remain)
	{
		VMS_LOG(VMS_LOG_LEVEL_INFO, "vms_process_recved_data pos %d, remain %d, copyed %d, cmd_buffer_len %d,receive_buffer_len %d", 
			pos, remain, copyed, cmd_buffer_len, receive_buffer_len);
		if(cmd_buffer_len < sizeof(VMS_CMD_HEADER))
		{
			if((cmd_buffer_len+remain) < sizeof(VMS_CMD_HEADER))//not enough head length
			{
				memcpy(cmd_buffer+cmd_buffer_len, receive_buffer+pos, remain);
				cmd_buffer_len += remain;
				break;
			}
			else
			{
				copyed = sizeof(VMS_CMD_HEADER)-cmd_buffer_len;
				memcpy(cmd_buffer+cmd_buffer_len, receive_buffer+pos, copyed); //get command head
				pos += copyed;
				remain -= copyed;

				//cross-platform, All the fields are in network byte order, must convert to host byte order
				header = (VMS_CMD_HEADER*)cmd_buffer;
				header->type = header->type;
				header->reserve[0] = header->reserve[1] = header->reserve[2] = 0; //reserved, fill zero
				header->data_length = boost::asio::detail::socket_ops::network_to_host_long(header->data_length);
				if(header->data_length == 0) //the command no append data,only head
				{
					try
					{
						r = t->process_command();
						VMS_LOG(VMS_LOG_LEVEL_INFO, "vms_process_recved_data t->process_command, header->data_length %ld return %d", 
							header->data_length, r);
						if(r != VMS_SUCCESS)
							break;
					}
					catch (...)
					{
						VMS_LOG(VMS_LOG_LEVEL_INFO, "%s", "vms_process_recved_data exception 1");
						return PROCESS_CMD_EXCEPTION;
					}					
					cmd_buffer_len =0 ;
				}
				else
				{
					cmd_buffer_len = sizeof(VMS_CMD_HEADER);
				}
			}
		}
		else
		{
			header = (VMS_CMD_HEADER*)cmd_buffer;
			if((cmd_buffer_len+remain) < (sizeof(VMS_CMD_HEADER)+header->data_length))//not enough data length
			{
				memcpy(cmd_buffer+cmd_buffer_len, receive_buffer+pos, remain);
				cmd_buffer_len += remain;
				break;
			}
			else //get a full command
			{
				copyed = sizeof(VMS_CMD_HEADER)+header->data_length-cmd_buffer_len;
				memcpy(cmd_buffer+cmd_buffer_len, receive_buffer+pos, copyed);
				cmd_buffer_len += copyed;
				try
				{
					r = t->process_command();
					VMS_LOG(VMS_LOG_LEVEL_INFO, "vms_process_recved_data t->process_command, header->data_length %ld return %d", 
						header->data_length, r);
					if(r != VMS_SUCCESS)
						break;
				}
				catch (...)
				{
					VMS_LOG(VMS_LOG_LEVEL_INFO, "%s", "vms_process_recved_data exception 2");
					return PROCESS_CMD_EXCEPTION;
				}
				cmd_buffer_len =0 ;
				pos += copyed;
				remain -= copyed;
			}
		}
	}

	return r;
}

#endif