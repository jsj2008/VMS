#include "config.h"
#include "vms_command.h"
#include "vms_log.h"
#include "md5.h"
#include <boost/property_tree/ptree.hpp>
#include <boost/property_tree/xml_parser.hpp>
#include <boost/uuid/sha1.hpp>

#define VMS_XML_ROOT "vms"
#define VMS_XML_PATH_CMD "vms.cmd"
#define VMS_XML_PATH_USER "vms.user"
#define VMS_XML_PATH_PWD "vms.pwd"
#define VMS_XML_PATH_ERROR "vms.error"
#define VMS_XML_PATH_CID "vms.cid"
#define VMS_XML_PATH_HEART "vms.heart"
#define VMS_XML_PATH_SID "vms.sid"
#define VMS_XML_PATH_TYPE "vms.type"
#define VMS_XML_PATH_SRC_ID "vms.src_id"
#define VMS_XML_PATH_USER_NAME "vms.username"
#define VMS_XML_PATH_PASSWORD "vms.password"
#define VMS_XML_PATH_SESSION_ID "vms.session_id"
#define VMS_XML_PATH_TID "vms.tid"
#define VMS_XML_PATH_RESULT "vms.result"
#define VMS_XML_PATH_USER_ID "vms.user_id"
#define VMS_XML_PATH_VID "vms.vid"
#define VMS_XML_PATH_XML "vms.xml"
#define VMS_XML_PATH_SPEED "vms.speed"
#define VMS_XML_PATH_TIME "vms.time"

#define VMS_XML_USER "user"
#define VMS_XML_ID "id"

VMS_COMMAND* decode_login_command(boost::property_tree::ptree& xml_tree, vms_result_t& error)
{
	VMS_LOGIN_COMMAND* cmd = new VMS_LOGIN_COMMAND;
	cmd->cmd = VMS_CMD_LOGIN;
	cmd->user = decode_str_from_xml(xml_tree.get<std::string>(VMS_XML_PATH_USER));
	cmd->password = xml_tree.get<std::string>(VMS_XML_PATH_PWD);
	/*if(cmd->user.length() == 0 || cmd->password.length() == 0)
	{
		error = USER_OR_PASSWORD_NULL;
		delete cmd;
		return NULL;
	}*/

	error = VMS_SUCCESS;
	return cmd;
}

VMS_COMMAND* decode_open_video_response_command(boost::property_tree::ptree& xml_tree, vms_result_t& error)
{
	VMS_OPEN_VIDEO_RESPONSE_COMMAND* cmd = new VMS_OPEN_VIDEO_RESPONSE_COMMAND;
	cmd->cmd = VMS_CMD_OPEN_VIDEO_RESPONSE;
	cmd->error = xml_tree.get<int>(VMS_XML_PATH_ERROR);
	cmd->cid = xml_tree.get<unsigned int>(VMS_XML_PATH_CID);
	cmd->vid = xml_tree.get<unsigned int>(VMS_XML_PATH_VID);
	error = VMS_SUCCESS;
	return cmd;
}

VMS_COMMAND* decode_open_back_video_response_command(boost::property_tree::ptree& xml_tree, vms_result_t& error)
{
	VMS_OPEN_BACK_VIDEO_RESPONSE_COMMAND* cmd = new VMS_OPEN_BACK_VIDEO_RESPONSE_COMMAND;
	cmd->cmd = VMS_CMD_OPEN_BACK_VIDEO_RESPONSE;
	cmd->error = xml_tree.get<int>(VMS_XML_PATH_ERROR);
	cmd->cid = xml_tree.get<unsigned int>(VMS_XML_PATH_CID);
	error = VMS_SUCCESS;
	return cmd;
}


VMS_COMMAND* decode_open_audio_response_command(boost::property_tree::ptree& xml_tree, vms_result_t& error)
{
	VMS_OPEN_AUDIO_RESPONSE_COMMAND* cmd = new VMS_OPEN_AUDIO_RESPONSE_COMMAND;
	cmd->cmd = VMS_CMD_OPEN_AUDIO_RESPONSE;
	cmd->error = xml_tree.get<int>(VMS_XML_PATH_ERROR);
	cmd->cid = xml_tree.get<unsigned int>(VMS_XML_PATH_CID);
	cmd->vid = xml_tree.get<unsigned int>(VMS_XML_PATH_VID);
	error = VMS_SUCCESS;
	return cmd;
}

VMS_COMMAND* decode_open_back_audio_response_command(boost::property_tree::ptree& xml_tree, vms_result_t& error)
{
	VMS_OPEN_BACK_AUDIO_RESPONSE_COMMAND* cmd = new VMS_OPEN_BACK_AUDIO_RESPONSE_COMMAND;
	cmd->cmd = VMS_CMD_OPEN_BACK_AUDIO_RESPONSE;
	cmd->error = xml_tree.get<int>(VMS_XML_PATH_ERROR);
	cmd->cid = xml_tree.get<unsigned int>(VMS_XML_PATH_CID);
	cmd->vid = xml_tree.get<unsigned int>(VMS_XML_PATH_VID);
	error = VMS_SUCCESS;
	return cmd;
}


VMS_COMMAND* decode_login_response_command(boost::property_tree::ptree& xml_tree, vms_result_t& error)
{
	VMS_LOGIN_RESPONSE_COMMAND* cmd = new VMS_LOGIN_RESPONSE_COMMAND;
	cmd->cmd = VMS_CMD_LOGIN_RESPONSE;
	cmd->error = xml_tree.get<int>(VMS_XML_PATH_ERROR);
	if(cmd->error != VMS_SUCCESS)
		cmd->cid = 0;
	else
	{
		cmd->cid = xml_tree.get<unsigned int>(VMS_XML_PATH_CID);
		cmd->heart_span = xml_tree.get<int>(VMS_XML_PATH_HEART);
	}
	error = VMS_SUCCESS;
	return cmd;
}

VMS_COMMAND* decode_logoff_command(boost::property_tree::ptree& xml_tree, vms_result_t& error)
{
	VMS_LOGOFF_COMMAND* cmd = new VMS_LOGOFF_COMMAND;
	cmd->cmd = VMS_CMD_LOGOFF;
	cmd->cid = xml_tree.get<unsigned int>(VMS_XML_PATH_CID);
	error = VMS_SUCCESS;
	return cmd;
}

VMS_COMMAND* decode_heart_command(boost::property_tree::ptree& xml_tree, vms_result_t& error)
{
	VMS_HEART_COMMAND* cmd = new VMS_HEART_COMMAND;
	cmd->cmd = VMS_CMD_HEART;
	cmd->cid = xml_tree.get<unsigned int>(VMS_XML_PATH_CID);
	error = VMS_SUCCESS;
	return cmd;
}

VMS_COMMAND* decode_open_video_command(boost::property_tree::ptree& xml_tree, vms_result_t& error)
{
	VMS_OPEN_VIDEO_COMMAND* cmd = new VMS_OPEN_VIDEO_COMMAND;
	cmd->cmd = VMS_CMD_OPEN_VIDEO;
	cmd->cid = xml_tree.get<unsigned int>(VMS_XML_PATH_CID);
	cmd->vid = xml_tree.get<unsigned int>(VMS_XML_PATH_VID);
	error = VMS_SUCCESS;
	return cmd;
}

VMS_COMMAND* decode_open_back_audio_command(boost::property_tree::ptree& xml_tree, vms_result_t& error)
{
	VMS_OPEN_BACK_AUDIO_COMMAND* cmd = new VMS_OPEN_BACK_AUDIO_COMMAND;
	cmd->cmd = VMS_CMD_OPEN_BACK_AUDIO;
	cmd->cid = xml_tree.get<unsigned int>(VMS_XML_PATH_CID);
	cmd->vid = xml_tree.get<unsigned int>(VMS_XML_PATH_VID);
	error = VMS_SUCCESS;
	return cmd;
}

VMS_COMMAND* decode_close_back_audio_command(boost::property_tree::ptree& xml_tree, vms_result_t& error)
{
	VMS_CLOSE_BACK_AUDIO_COMMAND* cmd = new VMS_CLOSE_BACK_AUDIO_COMMAND;
	cmd->cmd = VMS_CMD_CLOSE_BACK_AUDIO;
	cmd->cid = xml_tree.get<unsigned int>(VMS_XML_PATH_CID);
	cmd->vid = xml_tree.get<unsigned int>(VMS_XML_PATH_VID);
	error = VMS_SUCCESS;
	return cmd;
}

VMS_COMMAND* decode_open_back_video_command(boost::property_tree::ptree& xml_tree, vms_result_t& error)
{
	VMS_OPEN_BACK_VIDEO_COMMAND* cmd = new VMS_OPEN_BACK_VIDEO_COMMAND;
	cmd->cmd = VMS_CMD_OPEN_BACK_VIDEO;
	cmd->cid = xml_tree.get<unsigned int>(VMS_XML_PATH_CID);
	cmd->xml = xml_tree.get<std::string>(VMS_XML_PATH_XML);
	error = VMS_SUCCESS;
	return cmd;
}

VMS_COMMAND* decode_ptz_command(boost::property_tree::ptree& xml_tree, vms_result_t& error)
{
	VMS_PTZ_COMMAND* cmd = new VMS_PTZ_COMMAND;
	cmd->cmd = VMS_CMD_PTZ;
	cmd->cid = xml_tree.get<unsigned int>(VMS_XML_PATH_CID);
	cmd->vid = xml_tree.get<unsigned int>(VMS_XML_PATH_VID);
	cmd->xml = xml_tree.get<std::string>(VMS_XML_PATH_XML);
	error = VMS_SUCCESS;
	return cmd;
}

VMS_COMMAND* decode_play_begin_time_command(boost::property_tree::ptree& xml_tree, vms_result_t& error)
{
	VMS_PLAY_BEGIN_TIME_COMMAND* cmd = new VMS_PLAY_BEGIN_TIME_COMMAND;
	cmd->cmd = VMS_CMD_PALY_BEGIN_TIME;
	cmd->cid = xml_tree.get<unsigned int>(VMS_XML_PATH_CID);
	cmd->vid = xml_tree.get<unsigned int>(VMS_XML_PATH_VID);
	cmd->beginTime = xml_tree.get<std::string>(VMS_XML_PATH_TIME);
	error = VMS_SUCCESS;
	return cmd;
}

VMS_COMMAND* decode_close_back_video_command(boost::property_tree::ptree& xml_tree, vms_result_t& error)
{
	VMS_CLOSE_BACK_VIDEO_COMMAND* cmd = new VMS_CLOSE_BACK_VIDEO_COMMAND;
	cmd->cmd = VMS_CMD_CLOSE_BACK_VIDEO;
	cmd->cid = xml_tree.get<unsigned int>(VMS_XML_PATH_CID);
	error = VMS_SUCCESS;
	return cmd;
}

VMS_COMMAND* decode_close_video_command(boost::property_tree::ptree& xml_tree, vms_result_t& error)
{
	VMS_CLOSE_VIDEO_COMMAND* cmd = new VMS_CLOSE_VIDEO_COMMAND;
	cmd->cmd = VMS_CMD_CLOSE_VIDEO;
	cmd->cid = xml_tree.get<unsigned int>(VMS_XML_PATH_CID);
	cmd->vid = xml_tree.get<unsigned int>(VMS_XML_PATH_VID);
	error = VMS_SUCCESS;
	return cmd;
}

VMS_COMMAND* decode_open_audio_command(boost::property_tree::ptree& xml_tree, vms_result_t& error)
{
	VMS_OPEN_AUDIO_COMMAND* cmd = new VMS_OPEN_AUDIO_COMMAND;
	cmd->cmd = VMS_CMD_OPEN_AUDIO;
	cmd->cid = xml_tree.get<unsigned int>(VMS_XML_PATH_CID);
	cmd->vid = xml_tree.get<unsigned int>(VMS_XML_PATH_VID);
	error = VMS_SUCCESS;
	return cmd;
}


VMS_COMMAND* decode_close_audio_command(boost::property_tree::ptree& xml_tree, vms_result_t& error)
{
	VMS_CLOSE_AUDIO_COMMAND* cmd = new VMS_CLOSE_AUDIO_COMMAND;
	cmd->cmd = VMS_CMD_CLOSE_AUDIO;
	cmd->cid = xml_tree.get<unsigned int>(VMS_XML_PATH_CID);
	cmd->vid = xml_tree.get<unsigned int>(VMS_XML_PATH_VID);
	error = VMS_SUCCESS;
	return cmd;
}

VMS_COMMAND* decode_set_play_speed_command(boost::property_tree::ptree& xml_tree, vms_result_t& error)
{
	VMS_SET_PLAY_SPEED_COMMAND* cmd = new VMS_SET_PLAY_SPEED_COMMAND;
	cmd->cmd = VMS_CMD_SET_PLAY_SPEED;
	cmd->cid = xml_tree.get<unsigned int>(VMS_XML_PATH_CID);
	cmd->vid = xml_tree.get<unsigned int>(VMS_XML_PATH_VID);
	cmd->speed = xml_tree.get<float>(VMS_XML_PATH_SPEED);
	error = VMS_SUCCESS;
	return cmd;
}

VMS_COMMAND* decode_xml_command(const char* data, vms_result_t& error)
{
	boost::property_tree::ptree xml_tree;
	std::stringstream stream(data);
	try
	{
		boost::property_tree::xml_parser::read_xml(stream, xml_tree);
	}
	catch (const boost::property_tree::xml_parser::xml_parser_error&)
	{
		VMS_LOG(VMS_LOG_LEVEL_ERROR, "read_xml throw exception %s", e.what());
		error = VMS_XML_PARSER_ERROR;
		return NULL;
	}

	int cmd = xml_tree.get<int>(VMS_XML_PATH_CMD);
	switch(cmd)
	{
	case VMS_CMD_LOGIN:
		return decode_login_command(xml_tree, error);

	case VMS_CMD_LOGIN_RESPONSE:
		return decode_login_response_command(xml_tree, error);

	case VMS_CMD_LOGOFF:
		return decode_logoff_command(xml_tree, error);

	case VMS_CMD_HEART:
		return decode_heart_command(xml_tree, error);

	case VMS_CMD_OPEN_VIDEO:
		return decode_open_video_command(xml_tree, error);

	case VMS_CMD_CLOSE_VIDEO:
		return decode_close_video_command(xml_tree, error);

	case VMS_CMD_OPEN_AUDIO:
		return decode_open_audio_command(xml_tree, error);

	case VMS_CMD_CLOSE_AUDIO:
		return decode_close_audio_command(xml_tree, error);

	case VMS_CMD_OPEN_VIDEO_RESPONSE:
		return decode_open_video_response_command(xml_tree, error);

	case VMS_CMD_OPEN_AUDIO_RESPONSE:
		return decode_open_audio_response_command(xml_tree, error);

	case VMS_CMD_OPEN_BACK_VIDEO:
		return decode_open_back_video_command(xml_tree, error);

	case VMS_CMD_OPEN_BACK_VIDEO_RESPONSE:
		return decode_open_back_video_response_command(xml_tree, error);

	case VMS_CMD_CLOSE_BACK_VIDEO:
		return decode_close_back_video_command(xml_tree, error);

	case VMS_CMD_OPEN_BACK_AUDIO:
		return decode_open_back_audio_command(xml_tree, error);

	case VMS_CMD_CLOSE_BACK_AUDIO:
		return decode_close_back_audio_command(xml_tree, error);

	case VMS_CMD_OPEN_BACK_AUDIO_RESPONSE:
		return decode_open_back_audio_response_command(xml_tree, error);

	case VMS_CMD_SET_PLAY_SPEED:
		return decode_set_play_speed_command(xml_tree, error);

	case VMS_CMD_PTZ:
		return decode_ptz_command(xml_tree, error);

	case VMS_CMD_PALY_BEGIN_TIME:
		return decode_play_begin_time_command(xml_tree, error);

	default:
		VMS_LOG(VMS_LOG_LEVEL_ERROR, "unknown command: %d", cmd);
		error = VMS_INVALID_CMD_CODE;
		return NULL;
	}
}

VMS_COMMAND* decode_vms_command(const char* data, vms_result_t& error)
{
	VMS_CMD_HEADER* header = (VMS_CMD_HEADER*)data;
	if(header->type == VMS_CMD_TYPE_BINARY)
	{
		VMS_BIN_DATA* bin_data = (VMS_BIN_DATA*)command_offset_data(header);

		VMS_BINARY_COMMAND* bin_cmd = new VMS_BINARY_COMMAND;
		bin_cmd->cmd = bin_data->cmd;
		bin_cmd->data = (char*)bin_data;
		bin_cmd->len = header->data_length; 
		return bin_cmd;
	}
	else
		return decode_xml_command(command_offset_data((void*)data), error);

}

void delete_vms_command(VMS_COMMAND* cmd)
{
	delete cmd;
}

inline VMS_CMD_HEADER* create_xml_command(boost::property_tree::ptree* xml_tree)
{
	std::stringstream stream;
	boost::property_tree::xml_parser::write_xml(stream, *xml_tree);
	stream.seekp(0, std::ios::end);
	std::stringstream::pos_type size = stream.tellp();

	int total_size = sizeof(VMS_CMD_HEADER)+size;
	char* buffer = (char*)malloc(total_size+1);
	VMS_CMD_HEADER* header = (VMS_CMD_HEADER*)buffer;
	set_command_data_length(header, size);
	memcpy(command_offset_data(header), stream.str().c_str(), size);
	buffer[total_size] = '\0';
	return header;
}

VMS_CMD_HEADER* create_simple_response_command(int cmd, int result)
{
	boost::property_tree::ptree xml_tree;
	xml_tree.put(VMS_XML_PATH_CMD, cmd);
	xml_tree.put(VMS_XML_PATH_ERROR, result);
	return create_xml_command(&xml_tree);
}

VMS_CMD_HEADER* create_login_command(const char* user, const char* pwd)
{
	boost::property_tree::ptree xml_tree;
	xml_tree.put(VMS_XML_PATH_CMD, VMS_CMD_LOGIN);
	xml_tree.put(VMS_XML_PATH_USER, encode_str_to_xml(user));
	xml_tree.put(VMS_XML_PATH_PWD, command_pwd_encode(pwd));

	return create_xml_command(&xml_tree);
}

VMS_CMD_HEADER* create_login_response_command(unsigned int id, int result)
{
	if(result != VMS_SUCCESS)
	{
		return create_simple_response_command(VMS_CMD_LOGIN_RESPONSE, result);
	}
	else
	{
		boost::property_tree::ptree xml_tree;
		xml_tree.put(VMS_XML_PATH_CMD, VMS_CMD_LOGIN_RESPONSE);
		xml_tree.put(VMS_XML_PATH_ERROR, 0);
		xml_tree.put(VMS_XML_PATH_CID, id);
		xml_tree.put(VMS_XML_PATH_HEART, VMS_CLIENT_HEART_SPAN);
		return create_xml_command(&xml_tree);
	}
}


VMS_CMD_HEADER* create_logoff_command(unsigned int id)
{
	boost::property_tree::ptree xml_tree;
	xml_tree.put(VMS_XML_PATH_CMD, VMS_CMD_LOGOFF);
	xml_tree.put(VMS_XML_PATH_CID, id);

	return create_xml_command(&xml_tree);
}

VMS_CMD_HEADER* create_heart_command(unsigned int id)
{
	boost::property_tree::ptree xml_tree;
	xml_tree.put(VMS_XML_PATH_CMD, VMS_CMD_HEART);
	xml_tree.put(VMS_XML_PATH_CID, id);

	return create_xml_command(&xml_tree);
}

VMS_CMD_HEADER* create_open_video_command(unsigned int cid, unsigned int vid)
{
	boost::property_tree::ptree xml_tree;
	xml_tree.put(VMS_XML_PATH_CMD, VMS_CMD_OPEN_VIDEO);
	xml_tree.put(VMS_XML_PATH_CID, cid);
	xml_tree.put(VMS_XML_PATH_VID, vid);
	return create_xml_command(&xml_tree);
}
VMS_CMD_HEADER* create_close_video_command(unsigned int cid, unsigned int vid)
{
	boost::property_tree::ptree xml_tree;
	xml_tree.put(VMS_XML_PATH_CMD, VMS_CMD_CLOSE_VIDEO);
	xml_tree.put(VMS_XML_PATH_CID, cid);
	xml_tree.put(VMS_XML_PATH_VID, vid);
	return create_xml_command(&xml_tree);
}

VMS_CMD_HEADER* create_open_back_video_command(unsigned int cid, const std::string& xml)
{
	boost::property_tree::ptree xml_tree;
	xml_tree.put(VMS_XML_PATH_CMD, VMS_CMD_OPEN_BACK_VIDEO);
	xml_tree.put(VMS_XML_PATH_CID, cid);
	xml_tree.put(VMS_XML_PATH_XML, xml);
	return create_xml_command(&xml_tree);
}

VMS_CMD_HEADER* create_ptz_command(unsigned int cid, int vid, const std::string& xml)
{
	boost::property_tree::ptree xml_tree;
	xml_tree.put(VMS_XML_PATH_CMD, VMS_CMD_PTZ);
	xml_tree.put(VMS_XML_PATH_CID, cid);
	xml_tree.put(VMS_XML_PATH_VID, vid);
	xml_tree.put(VMS_XML_PATH_XML, xml);
	return create_xml_command(&xml_tree);
}

VMS_CMD_HEADER* create_set_play_begin_time_command(unsigned int cid, unsigned int vid, const std::string& t)
{
	boost::property_tree::ptree xml_tree;
	xml_tree.put(VMS_XML_PATH_CMD, VMS_CMD_PALY_BEGIN_TIME);
	xml_tree.put(VMS_XML_PATH_CID, cid);
	xml_tree.put(VMS_XML_PATH_VID, vid);
	xml_tree.put(VMS_XML_PATH_TIME, t);
	return create_xml_command(&xml_tree);
}

VMS_CMD_HEADER* create_open_audio_command(unsigned int cid, unsigned int vid, int cmd)
{
	boost::property_tree::ptree xml_tree;
	xml_tree.put(VMS_XML_PATH_CMD, cmd);
	xml_tree.put(VMS_XML_PATH_CID, cid);
	xml_tree.put(VMS_XML_PATH_VID, vid);
	return create_xml_command(&xml_tree);
}

VMS_CMD_HEADER* create_set_play_speed_command(unsigned int cid, unsigned int vid, float speed)
{
	boost::property_tree::ptree xml_tree;
	xml_tree.put(VMS_XML_PATH_CMD, VMS_CMD_SET_PLAY_SPEED);
	xml_tree.put(VMS_XML_PATH_CID, cid);
	xml_tree.put(VMS_XML_PATH_VID, vid);
	xml_tree.put(VMS_XML_PATH_SPEED, speed);
	
	return create_xml_command(&xml_tree);
}

VMS_CMD_HEADER* create_close_audio_command(unsigned int cid, unsigned int vid, int cmd)
{
	boost::property_tree::ptree xml_tree;
	xml_tree.put(VMS_XML_PATH_CMD, cmd);
	xml_tree.put(VMS_XML_PATH_CID, cid);
	xml_tree.put(VMS_XML_PATH_VID, vid);
	return create_xml_command(&xml_tree);
}
VMS_CMD_HEADER* create_open_video_response_command(unsigned int cid, unsigned int vid, int result)
{
	boost::property_tree::ptree xml_tree;
	xml_tree.put(VMS_XML_PATH_CMD, VMS_CMD_OPEN_VIDEO_RESPONSE);
	xml_tree.put(VMS_XML_PATH_CID, cid);
	xml_tree.put(VMS_XML_PATH_VID, vid);
	xml_tree.put(VMS_XML_PATH_ERROR, result);
	return create_xml_command(&xml_tree);
}

VMS_CMD_HEADER* create_open_back_video_response_command(unsigned int cid, int result)
{
	boost::property_tree::ptree xml_tree;
	xml_tree.put(VMS_XML_PATH_CMD, VMS_CMD_OPEN_BACK_VIDEO_RESPONSE);
	xml_tree.put(VMS_XML_PATH_CID, cid);
	xml_tree.put(VMS_XML_PATH_ERROR, result);
	return create_xml_command(&xml_tree);
}
VMS_CMD_HEADER* create_open_audio_response_command(unsigned int cid, unsigned int vid, int result)
{
	boost::property_tree::ptree xml_tree;
	xml_tree.put(VMS_XML_PATH_CMD, VMS_CMD_OPEN_AUDIO_RESPONSE);
	xml_tree.put(VMS_XML_PATH_CID, cid);
	xml_tree.put(VMS_XML_PATH_VID, vid);
	xml_tree.put(VMS_XML_PATH_ERROR, result);
	return create_xml_command(&xml_tree);
}

VMS_CMD_HEADER* create_open_back_audio_response_command(unsigned int cid, unsigned int vid, int result)
{
	boost::property_tree::ptree xml_tree;
	xml_tree.put(VMS_XML_PATH_CMD, VMS_CMD_OPEN_BACK_AUDIO_RESPONSE);
	xml_tree.put(VMS_XML_PATH_CID, cid);
	xml_tree.put(VMS_XML_PATH_VID, vid);
	xml_tree.put(VMS_XML_PATH_ERROR, result);
	return create_xml_command(&xml_tree);
}


VMS_CMD_HEADER* create_av_data_cmd(unsigned int video_id, char av_type, const char* data, int data_len, double timestamp)
{
	char* buffer = (char*)malloc(sizeof(VMS_CMD_HEADER) + sizeof(VMS_AV_DATA) + data_len);
	fill_command_header((VMS_CMD_HEADER*)buffer, sizeof(VMS_AV_DATA) + data_len, VMS_CMD_TYPE_BINARY);
	VMS_AV_DATA* vms_data = (VMS_AV_DATA*)command_offset_data(buffer);
	vms_data->cmd = av_type == VMS_VIDEO_DATA ? VMS_CMD_VIDEO_DATA:VMS_CMD_AUDIO_DATA ;
	vms_data->device_id = video_id;
	vms_data->timestamp = timestamp;
	memcpy(buffer+sizeof(VMS_CMD_HEADER)+sizeof(VMS_AV_DATA), data, data_len);
	return (VMS_CMD_HEADER*)buffer;
}

VMS_CMD_HEADER* create_close_back_video_command(unsigned int id)
{
	boost::property_tree::ptree xml_tree;
	xml_tree.put(VMS_XML_PATH_CMD, VMS_CMD_CLOSE_BACK_VIDEO);
	xml_tree.put(VMS_XML_PATH_CID, id);

	return create_xml_command(&xml_tree);
}

void destory_vms_command(VMS_CMD_HEADER* header)
{
	free(header);
}

std::string command_pwd_encode(const std::string& pwd)
{
	MD5 md5(pwd);
	md5.finalize();
	std::string ret = md5.hexdigest();
	return ret;

}