#include "config.h"
#include "vms_net_client.h"
#include "net_io.h"

#define CLIENT_RECONNECT_SECONDS 30

vms_net_client::vms_net_client(boost::asio::io_service& io_service, char keepAlive)
	: net_socket(io_service)
	, heart_timer_(io_service)
	, reconnect_timer_(io_service)
	, keepAlive_(keepAlive)
{
	status_ = VMS_LOGOFF;
	heart_span_ = VMS_CLIENT_HEART_SPAN;
	is_reconnect = false;
}

vms_net_client::~vms_net_client(void)
{
	logoff();
}

void vms_net_client::reconnect_timer(const boost::system::error_code& error)
{
    if(error.value() == 0)
	{
        login(server_, port_, user_, pwd_);
		is_reconnect = true;
	}
}

void vms_net_client::reconnect()
{
	reconnect_timer_.expires_from_now(boost::posix_time::seconds(CLIENT_RECONNECT_SECONDS));
	reconnect_timer_.async_wait( boost::bind( &vms_net_client::reconnect_timer, this->shared_from_this() , boost::asio::placeholders::error) ) ;
}

vms_result_t vms_net_client::login(const std::string& server, short port, const std::string& name, const std::string& pwd)
{
	boost::recursive_mutex::scoped_lock lock(recursive_mutex_);

	if(status_ == VMS_LOGOFF)
	{
		server_ = server;
		port_ = port;
		user_ = name;
		pwd_ = pwd;
		
		boost::asio::io_service& service = *(boost::asio::io_service*)net_io::instance().get_io_service();

		char sz_port[128];
		sprintf(sz_port, "%d", port);
		tcp::resolver resolver(service);
		tcp::resolver::query query(server, sz_port);

		tcp::resolver::iterator endpoint_iterator;
		try
		{
			endpoint_iterator = resolver.resolve(query);
		}
		catch (const boost::system::system_error&) //failed to find server host name 
		{
			VMS_LOG(VMS_LOG_LEVEL_ERROR, "failed to find server host name, server is %s", server.c_str());
			reconnect();
			return VMS_HOST_NOT_FOUND;
		}

		status_ = VMS_CONNECTTING;
		
		//async connect server,the call back function is vms_net_client::handle_connect
		boost::asio::async_connect(socket_, 
			endpoint_iterator,
			boost::bind(&vms_net_client::handle_connect, this->shared_from_this(), boost::asio::placeholders::error));
		VMS_LOG(VMS_LOG_LEVEL_INFO, "async conect server,%s %d %s %s", server.c_str(), port, name.c_str(), pwd.c_str());
		return VMS_SUCCESS;	
	}
	else
	{
		VMS_LOG(VMS_LOG_LEVEL_WARN, "client is connected or connecting, status is %d", status_);
		return CONNECTED_OR_CONNECTTING;
	}
}

void vms_net_client::logoff()
{
	boost::recursive_mutex::scoped_lock lock(recursive_mutex_);
	VMS_LOG(VMS_LOG_LEVEL_INFO, "vms_net_client::logoff %d", status_);
	if(status_ == VMS_LOGOFF)
		return;
	reconnect_timer_.cancel();
	if(status_ == VMS_LOGIN)
	{
		heart_timer_.cancel();
		status_ = VMS_LOGOFF;
		VMS_CMD_HEADER* header = create_logoff_command(cid_);
		send_cmd( header );
	}
	else if(status_ == VMS_CONNECTTING || status_ == VMS_CONNECTED)
	{
		status_ = VMS_LOGOFF;
		socket_.close();
	}
}

void vms_net_client::open_video(int vid)
{
	boost::recursive_mutex::scoped_lock lock(recursive_mutex_);
	if(status_ == VMS_LOGIN)
	{
		VMS_CMD_HEADER* header = create_open_video_command(cid_, vid);
		send_cmd( header );
	}
}

void vms_net_client::close_video(int vid)
{
	boost::recursive_mutex::scoped_lock lock(recursive_mutex_);
	if(status_ == VMS_LOGIN)
	{
		VMS_CMD_HEADER* header = create_close_video_command(cid_, vid);
		send_cmd( header );
	}
}

void vms_net_client::open_audio(int vid, int cmd)
{
	boost::recursive_mutex::scoped_lock lock(recursive_mutex_);
	if(status_ == VMS_LOGIN)
	{
		VMS_CMD_HEADER* header = create_open_audio_command(cid_, vid, cmd);
		send_cmd( header );
	}
}

void vms_net_client::close_audio(int vid, int cmd)
{
	boost::recursive_mutex::scoped_lock lock(recursive_mutex_);
	if(status_ == VMS_LOGIN)
	{
		VMS_CMD_HEADER* header = create_close_audio_command(cid_, vid, cmd);
		send_cmd( header );
	}
}

void vms_net_client::open_back_video(const std::string& xml)
{
	boost::recursive_mutex::scoped_lock lock(recursive_mutex_);
	if(status_ == VMS_LOGIN)
	{
		VMS_CMD_HEADER* header = create_open_back_video_command(cid_, xml);
		send_cmd( header );
	}
}

void vms_net_client::close_back_video()
{
	boost::recursive_mutex::scoped_lock lock(recursive_mutex_);
	if(status_ == VMS_LOGIN)
	{
		VMS_CMD_HEADER* header = create_close_back_video_command(cid_);
		send_cmd( header );
	}
}

void vms_net_client::PtzControll(int vid, const std::string& xml)
{
	boost::recursive_mutex::scoped_lock lock(recursive_mutex_);
	if(status_ == VMS_LOGIN)
	{
		VMS_CMD_HEADER* header = create_ptz_command(cid_, vid,xml);
		send_cmd( header );
	}
}

 void vms_net_client::SetPlayBeginTime(int vid, const std::string& t)
 {
	 boost::recursive_mutex::scoped_lock lock(recursive_mutex_);
	 if(status_ == VMS_LOGIN)
	 {
		 VMS_CMD_HEADER* header = create_set_play_begin_time_command(cid_, vid, t);
		 send_cmd( header );
	 }
 }

void vms_net_client::SetPlaySpeed(int vid, float speed)
{
	boost::recursive_mutex::scoped_lock lock(recursive_mutex_);
	if(status_ == VMS_LOGIN)
	{
		VMS_CMD_HEADER* header = create_set_play_speed_command(cid_, vid, speed);
		send_cmd( header );
	}
}

vms_result_t vms_net_client::process_command() 
{
	//recursive_mutex_ is locked in net_socket::handle_read, so don't lock again
	cmd_buffer_[cmd_buffer_len_] = '\0';
	vms_result_t result = VMS_SUCCESS;
	VMS_COMMAND* cmd = decode_vms_command(cmd_buffer_, result);
	if(cmd && result == VMS_SUCCESS)
	{
		switch(cmd->cmd)
		{
		case VMS_CMD_LOGIN_RESPONSE:
			do_login_response(cmd);
			break;
		case VMS_CMD_OPEN_VIDEO_RESPONSE:
		case VMS_CMD_OPEN_BACK_VIDEO_RESPONSE:
			open_video_response(cmd);
			break;
		case VMS_CMD_VIDEO_DATA:
		case VMS_CMD_AUDIO_DATA:
			on_recv_av_data(cmd);
			break;
		case VMS_CMD_OPEN_AUDIO_RESPONSE:
		case VMS_CMD_OPEN_BACK_AUDIO_RESPONSE:
			open_audio_response(cmd);
			break;
		default:
			break;
		}
		delete_vms_command(cmd);
	}
	else
	{
		VMS_LOG(VMS_LOG_LEVEL_ERROR , "vms_net_client::process_command decode_vms_command result is %d", result);
	}
	//if return result is not VMS_SUCCESS, the net_socket::handle_read will close socket and call on_net_close
	return result;
}

void vms_net_client::on_net_close() 
{
	VMS_LOG(VMS_LOG_LEVEL_INFO, "vms_net_client::on_net_close %d", status_);
	//recursive_mutex_ is locked in net_socket::handle_read, so don't lock again
	if(status_ == VMS_LOGIN)
	{
		heart_timer_.cancel();
		status_ = VMS_LOGOFF;
		on_net_disconnect();
		reconnect();
	}
	else if(status_ == VMS_CONNECTED)
	{
		status_ = VMS_LOGOFF;
		on_login_completed(FAILED_TO_CONNECT_SERVER);
		reconnect();
	}
}

void vms_net_client::handle_connect(const boost::system::error_code& error)
{
	VMS_LOG(VMS_LOG_LEVEL_INFO, "vms_net_client::handle_connect called, error is %d", error.value());

	boost::recursive_mutex::scoped_lock lock(recursive_mutex_);
	if (!error) //connect success
	{
		VMS_LOG(VMS_LOG_LEVEL_INFO, "%s", "send login command to cms server");
		//send login command to cms
		VMS_CMD_HEADER* header = create_login_command(user_.c_str(), pwd_.c_str());

		send_cmd(header);
		status_ = VMS_CONNECTED;
		//receive cms response
		async_read();
	}
	else
	{
		if(status_ == VMS_CONNECTTING)
		{
			status_ = VMS_LOGOFF;
			on_login_completed(FAILED_TO_CONNECT_SERVER);
		}
		reconnect();
	}
}

void vms_net_client::keep_alive()
{
	boost::recursive_mutex::scoped_lock lock(recursive_mutex_);
	if(status_ == VMS_LOGIN)
	{
		VMS_CMD_HEADER* header = create_heart_command(cid_);
		send_cmd( header );
	}
}

void vms_net_client::handle_heart_timer(const boost::system::error_code& error)
{
    if(error.value() == 0)
    {
        keep_alive();
        heart_timer_.expires_from_now(boost::posix_time::seconds(heart_span_));
        heart_timer_.async_wait( boost::bind( &vms_net_client::handle_heart_timer, this->shared_from_this(), boost::asio::placeholders::error) ) ;
    }
}

void vms_net_client::do_login_response(VMS_COMMAND* cmd)
{
	VMS_LOGIN_RESPONSE_COMMAND* response_cmd = (VMS_LOGIN_RESPONSE_COMMAND*)cmd;
	if(response_cmd->error == VMS_SUCCESS)
	{
		VMS_LOG(VMS_LOG_LEVEL_INFO, "%s", "client login successful!!!!!!");
		status_ = VMS_LOGIN;
		is_reconnect = false;
		cid_ = response_cmd->cid;
		on_login_completed(VMS_SUCCESS);

		//post async heart timer
		heart_span_ = response_cmd->heart_span;

		if(keepAlive_)
		{
			heart_timer_.expires_from_now( boost::posix_time::seconds(heart_span_) );
			heart_timer_.async_wait( boost::bind( &vms_net_client::handle_heart_timer, this->shared_from_this(), boost::asio::placeholders::error ) );
		}
	}
	else
	{
		VMS_LOG(VMS_LOG_LEVEL_INFO, "client login failed, error is %d ??????", response_cmd->error);
		on_login_completed(response_cmd->error);
		socket_.close();
		status_ = VMS_LOGOFF ;

		if(response_cmd->error != USER_IS_DISABLE 
			&& response_cmd->error != PSW_IS_INVALID 
			&& response_cmd->error != USER_NO_EXIST)
		{
			reconnect();
		}
	}
}

void vms_net_client::open_video_response(VMS_COMMAND* cmd)
{
	VMS_OPEN_VIDEO_RESPONSE_COMMAND* response = (VMS_OPEN_VIDEO_RESPONSE_COMMAND*)cmd;
	for(vms_client_cb_list::iterator it=client_cb_list_.begin(); it!=client_cb_list_.end(); it++)
	{
		(*it)->on_open_video(response->vid, response->error);
	}
}

void vms_net_client::open_audio_response(VMS_COMMAND* cmd)
{
	VMS_OPEN_AUDIO_RESPONSE_COMMAND* response = (VMS_OPEN_AUDIO_RESPONSE_COMMAND*)cmd;
	for(vms_client_cb_list::iterator it=client_cb_list_.begin(); it!=client_cb_list_.end(); it++)
	{
		(*it)->on_open_audio(response->vid, response->error);
	}
}

void vms_net_client::on_login_completed(vms_result_t error)
{
	for(vms_client_cb_list::iterator it=client_cb_list_.begin(); it!=client_cb_list_.end(); it++)
	{
		if(!is_reconnect || error == VMS_SUCCESS)
			(*it)->on_login_completed(error);
	}
}

void vms_net_client::on_recv_av_data(VMS_COMMAND* cmd)
{
	for(vms_client_cb_list::iterator it=client_cb_list_.begin(); it!=client_cb_list_.end(); it++)
	{
		(*it)->on_recv_av_data(cmd);
	}
}

void vms_net_client::on_net_disconnect()
{
	for(vms_client_cb_list::iterator it=client_cb_list_.begin(); it!=client_cb_list_.end(); it++)
	{
		(*it)->on_net_disconnect();
	}
}

void vms_net_client::add_client_cb(boost::shared_ptr<vms_client_cb> cb)
{
	boost::recursive_mutex::scoped_lock lock(recursive_mutex_);
	client_cb_list_.push_back(cb);
}

void vms_net_client::remove_client_cb(boost::shared_ptr<vms_client_cb> cb)
{
	boost::recursive_mutex::scoped_lock lock(recursive_mutex_);
	for(vms_client_cb_list::iterator it=client_cb_list_.begin(); it!=client_cb_list_.end(); it++)
	{
		if(cb == *it)
		{
			client_cb_list_.erase(it);
			break;
		}
	}
}