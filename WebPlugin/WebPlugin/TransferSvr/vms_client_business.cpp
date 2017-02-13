#include <config.h>
#include "vms_client_business.h"
#include <vms_command.h>
#include <time.h>
#include "vms_client_manager.h"
#include "net_client.h"
#include "live_video_manager.h"
#include "back_video_manager.h"

vms_client_business::vms_client_business(void)
{
	
}

vms_client_business::~vms_client_business(void)
{
	live_video_manager::instance().close_client(id_);
	back_video_manager::instance().close_client(id_);

}

void vms_client_business::init_with_net_client(boost::shared_ptr<net_client> client) 
{
	net_client_ = client;
	vms_client_manager::instance().add_vms_client(this->shared_from_this());
}

void vms_client_business::on_net_close()
{
	vms_client_manager::instance().remove_vms_client(id_);
}

//check net connection is valid
bool vms_client_business::check_valid()
{
	time_t now;
	time(&now);
	
	if(now-last_cmd_time_ > VMS_CLIENT_HEART_SPAN * 3)
	{
		return false;
	}
	else
	{
		return true;
	}
}

void vms_client_business::close_net_connection()
{
	VMS_LOG(VMS_LOG_LEVEL_INFO, "vms_client_business::close_net_connection");
	if(net_client_)
		net_client_->close();
}

vms_result_t vms_client_business::process_command(VMS_COMMAND* cmd)
{
	time(&last_cmd_time_);
	switch(cmd->cmd)
	{
	case VMS_CMD_HEART:
		do_heart();
		break;

	case VMS_CMD_LOGIN:
		do_login(cmd);
		break;

	case VMS_CMD_LOGOFF:
		do_logoff();
		break;

	case VMS_CMD_OPEN_VIDEO:
		open_video(cmd);
		break;

	case VMS_CMD_CLOSE_VIDEO:
		live_video_manager::instance().close_video(id_, ((VMS_OPEN_VIDEO_COMMAND*)cmd)->vid);
		break;

	case VMS_CMD_OPEN_AUDIO:
		open_audio(cmd);
		break;

	case VMS_CMD_CLOSE_AUDIO:
		live_video_manager::instance().close_audio(id_, ((VMS_CLOSE_AUDIO_COMMAND*)cmd)->vid);
		break;

	case VMS_CMD_OPEN_BACK_VIDEO:
		open_back_video(cmd);
		break;
	
	case VMS_CMD_CLOSE_BACK_VIDEO:
		back_video_manager::instance().close_client(id_);
		break;

	case VMS_CMD_OPEN_BACK_AUDIO:
		open_back_audio(cmd);
		break;

	case VMS_CMD_CLOSE_BACK_AUDIO:
		back_video_manager::instance().close_audio(id_, ((VMS_CLOSE_BACK_AUDIO_COMMAND*)cmd)->vid);
		break;

	case VMS_CMD_SET_PLAY_SPEED:
		{
			VMS_SET_PLAY_SPEED_COMMAND* speed_cmd = (VMS_SET_PLAY_SPEED_COMMAND*)cmd;
			back_video_manager::instance().set_play_speed(id_, speed_cmd->vid, speed_cmd->speed);
		}
		break;
	case VMS_CMD_PTZ:
		{
			VMS_PTZ_COMMAND* ptz = (VMS_PTZ_COMMAND*)cmd;
			live_video_manager::instance().ptz(id_, ptz->vid, ptz->xml);
		}
		break;
	case VMS_CMD_PALY_BEGIN_TIME:
		{
			VMS_PLAY_BEGIN_TIME_COMMAND* bt = (VMS_PLAY_BEGIN_TIME_COMMAND*)cmd;
			back_video_manager::instance().set_play_begin_time(id_, bt->vid, bt->beginTime);
		}
		break;
	}
	delete_vms_command(cmd); 
	return VMS_SUCCESS;
}

void vms_client_business::do_heart()
{
	VMS_CMD_HEADER* header = create_heart_command(id_);
	net_client_->send_cmd(header);
}

void vms_client_business::do_login(VMS_COMMAND* cmd)
{
	VMS_LOGIN_COMMAND* login_cmd = (VMS_LOGIN_COMMAND*)cmd;
	user_ = login_cmd->user;
	pwd_ = login_cmd->password;

	VMS_LOG(VMS_LOG_LEVEL_INFO, "vms_client_business::do_login begin");

	VMS_CMD_HEADER* header = create_login_response_command(id_, VMS_SUCCESS);

	net_client_->send_cmd(header);

	VMS_LOG(VMS_LOG_LEVEL_INFO, "vms_client_business::do_login end");
}
//client logoff, close socket, remove this from client manager
void vms_client_business::do_logoff()
{
	VMS_LOG(VMS_LOG_LEVEL_INFO, "vms_client_business::do_logoff %d", id_);

	net_client_->close();
	live_video_manager::instance().close_client(id_);
	back_video_manager::instance().close_client(id_);
}

void vms_client_business::open_video(VMS_COMMAND* cmd)
{
	VMS_LOG(VMS_LOG_LEVEL_INFO, "vms_client_business::open_video begin");

	VMS_OPEN_VIDEO_COMMAND* open_video_cmd = (VMS_OPEN_VIDEO_COMMAND*)cmd;
	int result = live_video_manager::instance().open_video(id_, open_video_cmd->vid);

	VMS_CMD_HEADER* header = create_open_video_response_command(id_, open_video_cmd->vid, result);

	net_client_->send_cmd(header);

	VMS_LOG(VMS_LOG_LEVEL_INFO, "vms_client_business::open_video end");

}

void vms_client_business::open_audio(VMS_COMMAND* cmd)
{
	VMS_LOG(VMS_LOG_LEVEL_INFO, "vms_client_business::open_audio begin");

	VMS_OPEN_AUDIO_COMMAND* open_video_cmd = (VMS_OPEN_AUDIO_COMMAND*)cmd;
	int result = live_video_manager::instance().open_audio(id_, open_video_cmd->vid);

	VMS_CMD_HEADER* header = create_open_audio_response_command(id_, open_video_cmd->vid, result);

	net_client_->send_cmd(header);

	VMS_LOG(VMS_LOG_LEVEL_INFO, "vms_client_business::open_audio end");

}

void vms_client_business::open_back_video(VMS_COMMAND* cmd)
{
	VMS_LOG(VMS_LOG_LEVEL_INFO, "vms_client_business::open_back_video begin");

	VMS_OPEN_BACK_VIDEO_COMMAND* open_video_cmd = (VMS_OPEN_BACK_VIDEO_COMMAND*)cmd;
	
	int result = back_video_manager::instance().open_video(id_, open_video_cmd->xml);

	VMS_CMD_HEADER* header = create_open_back_video_response_command(id_, result);

	net_client_->send_cmd(header);

	VMS_LOG(VMS_LOG_LEVEL_INFO, "vms_client_business::open_back_video end");
}

void vms_client_business::send_data_to_client(VMS_CMD_HEADER* header)
{
	net_client_->send_cmd(header);
}

void vms_client_business::open_back_audio(VMS_COMMAND* cmd)
{
	VMS_LOG(VMS_LOG_LEVEL_INFO, "vms_client_business::open_back_audio begin");

	VMS_OPEN_BACK_AUDIO_COMMAND* open_video_cmd = (VMS_OPEN_BACK_AUDIO_COMMAND*)cmd;
	int result = back_video_manager::instance().open_audio(id_, open_video_cmd->vid);

	VMS_CMD_HEADER* header = create_open_back_audio_response_command(id_, open_video_cmd->vid, result);

	net_client_->send_cmd(header);

	VMS_LOG(VMS_LOG_LEVEL_INFO, "vms_client_business::open_back_audio end");
}